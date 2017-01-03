--
-- Copyright 2015 SipWise Team <development@sipwise.com>
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
local redis = require 'redis';
local utils = require 'ngcp.utils';
local utable = utils.table

_ENV = NGCPDlgList

-- class NGCPDlgList
local NGCPDlgList_MT = { __index = NGCPDlgList }

NGCPDlgList_MT.__tostring = function (t)
    return string.format("config:%s central:%s pair:%s",
        utable.tostring(t.config), utable.tostring(t.central),
        utable.tostring(t.pair));
end

    function NGCPDlgList.new()
        local t = NGCPDlgList.init();
        setmetatable( t, NGCPDlgList_MT );
        return t;
    end

    function NGCPDlgList.init()
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
                check_pair_dup = false
            },
            central = {},
            pair = {}
        };
        return t;
    end

    local function _test_connection(client)
        if not client then return nil end
        local ok, _ = pcall(client.ping, client);
        return ok
    end

    local function _connect(config)
        local client = redis.connect(config.host,config.port);
        client:select(config.db);
        sr.log("dbg", string.format("connected to redis server %s:%d at %s\n",
            config.host, config.port, config.db));
        return client;
    end

    function NGCPDlgList._del(self, key, callid)
        self.central:lrem(key, 0, callid);
        local num = self.central:llen(key);
        if num == 0 then
            self.central:del(key);
            sr.log("dbg", string.format("central[%s] is empty. Removed\n", key));
        else
            sr.log("dbg", string.format("central:lrem[%s]=>[%s]\n", key, tostring(num)));
        end
        return num;
    end

    function NGCPDlgList:exists(callid)
        if not _test_connection(self.pair) then
            self.pair = _connect(self.config.pair);
        end
        local res = self.pair:llen("list:"..callid)
        if res > 0 then
            return true
        else
            return false
        end
    end

    function NGCPDlgList:is_in_set(callid, key)
        if not _test_connection(self.pair) then
            self.pair = _connect(self.config.pair);
        end
        local res = self.pair:lrange("list:"..callid, 0, -1);
        return utable.contains(res, key);
    end

    function NGCPDlgList:add(callid, key)
        if not _test_connection(self.central) then
            self.central = _connect(self.config.central);
        end
        local pos = self.central:rpush(key, callid);
        sr.log("dbg", string.format("central:rpush[%s]=>[%s] %s\n", key, callid, tostring(pos)));
        if not _test_connection(self.pair) then
            self.pair = _connect(self.config.pair);
        end
        if self.config.check_pair_dup and self:is_in_set(callid, key) then
            sr.log("warn", string.format("pair:check_pair_dup[%s]=>[%s] already there!\n", callid, key));
        end
        pos = self.pair:lpush("list:"..callid, key);
        sr.log("dbg", string.format("pair:lpush[list:%s]=>[%s] %s\n", callid, key, tostring(pos)));
    end

    function NGCPDlgList:del(callid, key)
        if not _test_connection(self.pair) then
            self.pair = _connect(self.config.pair);
        end
        local num = self.pair:lrem("list:"..callid, 0, key);
        sr.log("dbg", string.format("pair:lrem[%s]=>[%s] %d\n", callid, key, num));
        if not _test_connection(self.central) then
            self.central = _connect(self.config.central);
        end
        self:_del(key, callid);
    end

    function NGCPDlgList:destroy(callid)
        if not _test_connection(self.pair) then
            self.pair = _connect(self.config.pair);
        end
        local key = self.pair:lpop("list:"..callid);
        if not key then
            self.pair:del("list:"..callid);
            error(string.format("callid:%s list empty", callid));
        end
        if not _test_connection(self.central) then
            self.central = _connect(self.config.central);
        end
        while key do
            self:_del(key, callid);
            sr.log("dbg", string.format("pair:lpop[%s]=>[%s]\n", callid, key));
            key = self.pair:lpop("list:"..callid);
        end
    end
-- class

return NGCPDlgList
--EOF
