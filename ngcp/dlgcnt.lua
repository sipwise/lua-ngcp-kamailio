--
-- Copyright 2014-2024 SipWise Team <development@sipwise.com>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This package is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
-- .
-- On Debian systems, the complete text of the GNU General
-- Public License version 3 can be found in "/usr/share/common-licenses/GPL-3".
--
local NGCPDlgCounters = {
     __class__ = 'NGCPDlgCounters'
}
-- luacheck: globals KSR
local KSR = KSR
local NGCPRedis = require 'ngcp.redis';
local utils = require 'ngcp.utils';
local utable = utils.table;
local xavp_name = 'lua_dlgcnt_vals';
local xavp_fmt_init = '$xavp('..xavp_name..'=>%s)'
local xavp_fmt = '$xavp('..xavp_name..'[0]=>%s)'

_ENV = NGCPDlgCounters

local defaults = {
    central = {
        host = '127.0.0.1',
        port = 6379,
        db = 3
    },
    pair = {
        host = '127.0.0.1',
        port = 6379,
        db = 4
    },
    logfile = false,
    debug = false,
    check_pair_dup = false,
    allow_negative = false
}

  -- class NGCPDlgCounters
local NGCPDlgCounters_MT = { __index = NGCPDlgCounters }

NGCPDlgCounters_MT.__tostring = function (t)
    return string.format("config:%s central:%s pair:%s",
        utable.tostring(t.config), utable.tostring(t.central),
        utable.tostring(t.pair));
end

    function NGCPDlgCounters:new(config)
        local t = NGCPDlgCounters.init(utils.merge_defaults(config, defaults))
        return setmetatable( t, NGCPDlgCounters_MT )
    end

    function NGCPDlgCounters.init(config)
        local t = {
            config = config,
            central = NGCPRedis:new(config.central),
            pair = NGCPRedis:new(config.pair)
        }
        if config.logfile then
            t.KSR = utils.KSR_log(KSR, config.logfile)
            if t.KSR and t.KSR._logger then
                KSR = t.KSR
                KSR.dbg(string.format("logfile %s will be in used", config.logfile))
            end
        end
        return t
    end

    function NGCPDlgCounters._decr(self, key, callid)
        local res = self.central.client:decr(key);
        if res == 0 then
            self.central.client:del(key);
            KSR.dbg(string.format("central:del[%s] counter is 0 - %s\n", key, callid));
            if self.config.debug then
                KSR.pv.unset(string.format(xavp_fmt, key))
            end
        elseif res < 0 and not self.config.allow_negative then
            self.central.client:del(key);
            KSR.warn(string.format("central:del[%s] counter was %s\n",
                key, tostring(res)));
            if self.config.debug then
                KSR.pv.unset(string.format(xavp_fmt, key))
            end
        else
            KSR.dbg(string.format("central:decr[%s]=>[%s] - %s\n",
                key, tostring(res), callid));
            if self.config.debug then
                KSR.pv.seti(string.format(xavp_fmt, key), res)
            end
        end
        return res;
    end

    function NGCPDlgCounters:exists(callid)
        if not self.pair:test_connection() then
            self.pair:connect()
        end
        local res = self.pair.client:llen(callid)
        if res > 0 then
            return true
        else
            return false
        end
    end

    function NGCPDlgCounters:is_in_set(callid, key)
        if not self.pair:test_connection() then
            self.pair:connect()
        end
        local res = self.pair.client:lrange(callid, 0, -1);
        return utable.contains(res, key);
    end

    function NGCPDlgCounters:is_in_set_regex(callid, key)
        if not self.pair:test_connection() then
            self.pair:connect()
        end
        local res = self.pair.client:lrange(callid, 0, -1);
        return utable.contains_regex(res, key);
    end

    function NGCPDlgCounters:set(callid, key)
        if not self.central:test_connection() then
            self.central:connect()
        end
        local res = self.central.client:incr(key);
        KSR.dbg(string.format("central:incr[%s]=>%s - %s\n", key, tostring(res), callid));
        if self.config.debug then
            if KSR.pvx.xavp_is_null(xavp_name) > 0 then
                KSR.pv.seti(string.format(xavp_fmt_init, key), res)
            else
                KSR.pv.seti(string.format(xavp_fmt, key), res)
            end
        end
        if not self.pair:test_connection() then
            self.pair:connect()
        end
        if self.config.check_pair_dup and self:is_in_set(callid, key) then
            local msg = "pair:check_pair_dup[%s]=>[%s] already there!\n";
            KSR.warn(msg:format(callid, key));
        end
        local pos = self.pair.client:lpush(callid, key);
        KSR.dbg(string.format("pair:lpush[%s]=>[%s] %s - %s\n",
            callid, key, tostring(pos), callid));
    end

    function NGCPDlgCounters:del_key(callid, key)
        if not self.pair:test_connection() then
            self.pair:connect()
        end
        local num = self.pair.client:lrem(callid, 1, key);
        if num == 0 then
            local msg = "pair:lrem[%s]=>[%s] no such key found in list, " ..
                "skipping decrement - %s\n";
            KSR.dbg(msg:format(callid, key, callid));
            return false;
        end
        KSR.dbg(string.format("pair:lrem[%s]=>[%s] %d - %s\n", callid, key, num, callid));
        if not self.central:test_connection() then
            self.central:connect()
        end
        self:_decr(key, callid);
    end

    function NGCPDlgCounters:del(callid)
        if not self.pair:test_connection() then
            self.pair:connect()
        end
        local key = self.pair.client:lpop(callid);
        if not key then
            error(string.format("callid:%s list empty", callid));
        end
        if not self.central:test_connection() then
            self.central:connect()
        end
        while key do
            self:_decr(key, callid);
            KSR.dbg(string.format("pair:lpop[%s]=>[%s] - %s\n", callid, key, callid));
            key = self.pair.client:lpop(callid);
        end
    end

    function NGCPDlgCounters:del_pair(callid)
        if not self.pair:test_connection() then
            self.pair:connect()
        end
        local key = self.pair.client:lpop(callid);
        if not key then
            error(string.format("callid:%s list empty", callid));
        end
        if not self.central:test_connection() then
            self.central:connect()
        end
        while key do
            KSR.dbg(string.format("pair:lpop[%s]=>[%s] - %s\n", callid, key, callid));
            key = self.pair.client:lpop(callid);
        end
    end

    function NGCPDlgCounters:get(key)
        if not self.central:test_connection() then
            self.central:connect()
        end
        local res = self.central.client:get(key);
        KSR.dbg(string.format("central:get[%s]=>%s - %s\n", key, tostring(res), key));
        return res;
    end
-- class

return NGCPDlgCounters
--EOF
