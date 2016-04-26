--
-- Copyright 2014-2016 SipWise Team <development@sipwise.com>
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
local redis = require 'redis';
local utils = require 'ngcp.utils';
local utable = utils.table;

_ENV = NGCPDlgCounters

-- class NGCPDlgCounters
local NGCPDlgCounters_MT = { __index = NGCPDlgCounters }

NGCPDlgCounters_MT.__tostring = function (t)
    return string.format("config:%s central:%s pair:%s",
        utable.tostring(t.config), utable.tostring(t.central),
        utable.tostring(t.pair));
end

    function NGCPDlgCounters.new()
        local t = NGCPDlgCounters.init();
        setmetatable( t, NGCPDlgCounters_MT );
        return t;
    end

    function NGCPDlgCounters.init()
        local t = {
            config = {
                central = {
                    host = '127.0.0.1',
                    port = 6379,
                    db = "3"
                },
                pair = {
                    host = '127.0.0.1',
                    port = 6379,
                    db = "4"
                },
                check_pair_dup = false,
                allow_negative = false
            },
            central = {},
            pair = {}
        };
        return t;
    end

    function NGCPDlgCounters._test_connection(client)
        if not client then return nil end
        local ok, _ = pcall(client.ping, client);
        return ok
    end

    function NGCPDlgCounters._connect(config)
        local client = redis.connect(config.host,config.port);
        client:select(config.db);
        sr.log("dbg", string.format("connected to redis server %s:%d at %s\n",
            config.host, config.port, config.db));
        return client;
    end

    function NGCPDlgCounters._decr(self, key)
        local res = self.central:decr(key);
        if res == 0 then
            self.central:del(key);
            sr.log("dbg", string.format("central:del[%s] counter is 0\n", key));
        elseif res < 0 and not self.config.allow_negative then
            self.central:del(key);
            sr.log("warn", string.format("central:del[%s] counter was %s\n", key, tostring(res)));
        else
            sr.log("dbg", string.format("central:decr[%s]=>[%s]\n", key, tostring(res)));
        end
        return res;
    end

    function NGCPDlgCounters:exists(callid)
        if not self._test_connection(self.pair) then
            self.pair = self._connect(self.config.pair);
        end
        local res = self.pair:llen(callid)
        if res > 0 then
            return true
        else
            return false
        end
    end

    function NGCPDlgCounters:is_in_set(callid, key)
        if not self._test_connection(self.pair) then
            self.pair = self._connect(self.config.pair);
        end
        local res = self.pair:lrange(callid, 0, -1);
        return utable.contains(res, key);
    end

    function NGCPDlgCounters:set(callid, key)
        if not self._test_connection(self.central) then
            self.central = self._connect(self.config.central);
        end
        local res = self.central:incr(key);
        sr.log("dbg", string.format("central:incr[%s]=>%s\n", key, tostring(res)));
        if not self._test_connection(self.pair) then
            self.pair = self._connect(self.config.pair);
        end
        if self.config.check_pair_dup and self:is_in_set(callid, key) then
            sr.log("warn", string.format("pair:check_pair_dup[%s]=>[%s] already there!\n", callid, key));
        end
        local pos = self.pair:lpush(callid, key);
        sr.log("dbg", string.format("pair:lpush[%s]=>[%s] %s\n", callid, key, tostring(pos)));
    end

    function NGCPDlgCounters:del_key(callid, key)
        if not self._test_connection(self.pair) then
            self.pair = self._connect(self.config.pair);
        end
        local num = self.pair:lrem(callid, 1, key);
        sr.log("dbg", string.format("pair:lrem[%s]=>[%s] %d\n", callid, key, num));
        if not self._test_connection(self.central) then
            self.central = self._connect(self.config.central);
        end
        self:_decr(key);
    end

    function NGCPDlgCounters:del(callid)
        if not self._test_connection(self.pair) then
            self.pair = self._connect(self.config.pair);
        end
        local key = self.pair:lpop(callid);
        if not key then
            error(string.format("callid:%s list empty", callid));
        end
        if not self._test_connection(self.central) then
            self.central = self._connect(self.config.central);
        end
        while key do
            self:_decr(key);
            sr.log("dbg", string.format("pair:lpop[%s]=>[%s]\n", callid, key));
            key = self.pair:lpop(callid);
        end
    end

    function NGCPDlgCounters:get(key)
        if not self._test_connection(self.central) then
            self.central = self._connect(self.config.central);
        end
        local res = self.central:get(key);
        sr.log("dbg", string.format("central:get[%s]=>%s\n", key, tostring(res)));
        return res;
    end
-- class

return NGCPDlgCounters
--EOF
