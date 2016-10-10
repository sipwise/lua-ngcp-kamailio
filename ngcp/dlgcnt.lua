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
    return string.format("config:%s client:%s",
        utable.tostring(t.config), utable.tostring(t.client));
end

    function NGCPDlgCounters.new()
        local t = NGCPDlgCounters.init();
        setmetatable( t, NGCPDlgCounters_MT );
        return t;
    end

    function NGCPDlgCounters.init()
        local t = {
            config = {
                host = '127.0.0.1',
                port = 6379,
                db = "3",
                default_expire = 5,
            },
            client = {},
            -- this helps when testing
            scan_param = {match="*"}
        };
        return t;
    end

    local function _test_connection(client)
        if not client then return nil end
        local ok, _ = pcall(client.ping, client);
        return ok
    end

    local function _connect(config)
        local client = redis.connect(config.host, config.port);
        client:select(config.db);
        sr.log("dbg", string.format("connected to redis server %s:%d at %s\n",
            config.host, config.port, config.db));
        return client;
    end

    local function _scan_key(self, cursor, match, result)
        if not result then error("parameter result is null") end
        if not cursor then
            cursor = 0
        end
        self.scan_param.match = match
        local res = self.client:scan(cursor, self.scan_param)
        if res[2] then
            utable.merge(result, res[2])
        end
        --[[ sr.log("dbg", string.format(
            "cursor:%s cursor_next:%s match:[%s] res:%s\n",
            tostring(cursor) ,tostring(res[1]), tostring(match),
            utable.tostring(res), utable.tostring(result)))--]]
        return tonumber(res[1])
    end

    local function _get_keys(self, key)
        if not key then error("parameter key is null") end
        local result = {}
        local cursor = nil
        repeat
            cursor = _scan_key(self, cursor, key, result)
        until (cursor == 0)
        return result
    end

    function NGCPDlgCounters:exists(callid)
        if not callid then error("parameter callid is null") end
        if not _test_connection(self.client) then
            self.client = _connect(self.config);
        end
        local real_key = callid .. ':*'
        local res = _get_keys(self, real_key)
        if res and utable.size(res) > 0 then
            return true
        else
            return false
        end
    end

    function NGCPDlgCounters:set(callid, key, expire)
        if not callid then error("parameter callid is null") end
        if not key then error("parameter key is null") end
        if not _test_connection(self.client) then
            self.client = _connect(self.config);
        end
        if not expire then
            expire = self.config.default_expire
        end
        local real_key = callid .. ':' .. key
        self.client:set(real_key, 'OK');
        self.client:expire(real_key, expire);
        sr.log("dbg", string.format("set[%s] %d\n", real_key, expire));
    end

    function NGCPDlgCounters:del_key(callid, key)
        if not callid then error("parameter callid is null") end
        if not key then error("parameter key is null") end
        if not _test_connection(self.client) then
            self.client = _connect(self.config);
        end
        local real_key = callid .. ':' .. key
        self.client:del(real_key)
        sr.log("dbg", string.format("del[%s]", real_key))
    end

    function NGCPDlgCounters:del(callid)
        if not callid then error("parameter callid is null") end
        if not _test_connection(self.client) then
            self.client = _connect(self.config);
        end
        local real_key = callid .. ':*'
        local keys = _get_keys(self, real_key)
        if keys then
            sr.log("info",
                string.format("del[%s]=>%s", callid, utable.tostring(keys)))
        else
            sr.log("dbg", string.format("no keys found for %s", real_key))
            return
        end
        for _, key in ipairs(keys) do
            self.client:del(key)
            sr.log("dbg", string.format("del[%s]", key))
        end
    end

    function NGCPDlgCounters:get_size(key)
        if not key then error("parameter key is null") end
        if not _test_connection(self.client) then
            self.client = _connect(self.config);
        end
        local real_key = '*:' .. key
        local res = _get_keys(client, real_key)
        local len = 0
        if res then
            len = #res
        end
        sr.log("dbg", string.format("get_size[%s]=>%d\n", real_key, len));
        return len;
    end
-- class

return NGCPDlgCounters
--EOF
