--
-- Copyright 2015-2022 SipWise Team <development@sipwise.com>
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
local NGCPDlgList = {
     __class__ = 'NGCPDlgList'
}
local NGCPRedis = require 'ngcp.redis';
local utils = require 'ngcp.utils';
local utable = utils.table

_ENV = NGCPDlgList

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
    check_pair_dup = false
}

-- class NGCPDlgList
local NGCPDlgList_MT = { __index = NGCPDlgList }

NGCPDlgList_MT.__tostring = function (t)
    return string.format("config:%s central:%s pair:%s",
        utable.tostring(t.config), utable.tostring(t.central),
        utable.tostring(t.pair));
end
-- luacheck: globals KSR
    function NGCPDlgList:new(config)
        local t = NGCPDlgList.init(utils.merge_defaults(config, defaults))
        setmetatable( t, NGCPDlgList_MT )
        return t
    end

    function NGCPDlgList.init(config)
        return {
            config = config,
            central = NGCPRedis:new(config.central),
            pair = NGCPRedis:new(config.pair)
        }
    end

    function NGCPDlgList._del(self, key, callid)
        self.central.client:lrem(key, 0, callid);
        local num = self.central.client:llen(key);
        if num == 0 then
            self.central.client:del(key);
            KSR.dbg(string.format("central[%s] is empty. Removed\n", key));
        else
            KSR.dbg(string.format("central:lrem[%s]=>[%s]\n", key, tostring(num)));
        end
        return num;
    end

    function NGCPDlgList:exists(callid)
        if not self.pair:test_connection() then
            self.pair:connect()
        end
        local res = self.pair.client:llen("list:"..callid)
        if res > 0 then
            return true
        else
            return false
        end
    end

    function NGCPDlgList:is_in_set(callid, key)
        if not self.pair:test_connection() then
            self.pair:connect()
        end
        local res = self.pair.client:lrange("list:"..callid, 0, -1);
        return utable.contains(res, key);
    end

    function NGCPDlgList:add(callid, key)
        if not self.central:test_connection() then
            self.central:connect()
        end
        local pos = self.central.client:rpush(key, callid);
        KSR.dbg(string.format("central:rpush[%s]=>[%s] %s\n", key, callid, tostring(pos)));
        if not self.pair:test_connection() then
            self.pair:connect()
        end
        if self.config.check_pair_dup and self:is_in_set(callid, key) then
            KSR.warn(string.format("pair:check_pair_dup[%s]=>[%s] already there!\n", callid, key));
        end
        pos = self.pair.client:lpush("list:"..callid, key);
        KSR.dbg(string.format("pair:lpush[list:%s]=>[%s] %s\n", callid, key, tostring(pos)));
    end

    function NGCPDlgList:del(callid, key)
        if not self.pair:test_connection() then
            self.pair:connect()
        end
        local num = self.pair.client:lrem("list:"..callid, 0, key);
        if num == 0 then
            KSR.dbg(string.format("pair:lrem[list:%s] no such key %s found in list\n", callid, key));
            return false;
        end
        KSR.dbg(string.format("pair:lrem[%s]=>[%s] %d\n", callid, key, num));
        if not self.central:test_connection() then
            self.central:connect()
        end
        self:_del(key, callid);
    end

    function NGCPDlgList:destroy(callid)
        if not self.pair:test_connection() then
            self.pair:connect()
        end
        local key = self.pair.client:lpop("list:"..callid);
        if not key then
            self.pair.client:del("list:"..callid);
            error(string.format("callid:%s list empty", callid));
        end
        if not self.central:test_connection() then
            self.central:connect()
        end
        while key do
            self:_del(key, callid);
            KSR.dbg(string.format("pair:lpop[%s]=>[%s]\n", callid, key));
            key = self.pair.client:lpop("list:"..callid);
        end
    end
-- class

return NGCPDlgList
--EOF
