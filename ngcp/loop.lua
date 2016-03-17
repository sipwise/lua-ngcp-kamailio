--
-- Copyright 2016 SipWise Team <development@sipwise.com>
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
local NGCPLoop = {
     __class__ = 'NGCPLoop'
}
local redis = require 'redis';
local utils = require 'ngcp.utils';
local utable = utils.table

_ENV = NGCPLoop

-- class NGCPLoop
local NGCPLoop_MT = { __index = NGCPLoop }

NGCPLoop_MT.__tostring = function (t)
    return string.format("config:%s",
        utable.tostring(t.config));
end

    function NGCPLoop.new()
        local t = NGCPLoop.init();
        setmetatable( t, NGCPLoop_MT );
        return t;
    end

    function NGCPLoop.init()
        local t = {
            config = {
                host = '127.0.0.1',
                port = 6379,
                db = "3",
                expires = 300
            },
            client = {}
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

    function NGCPLoop:add(fu, tu, ru)
        if not _test_connection(self.client) then
            self.client = _connect(self.config);
        end
        local key = tostring(fu);
        local value = string.format("%s;%s", tostring(tu), tostring(ru));

        self.client:set(key, value, self.config.expires);
        sr.log("dbg", string.format("[%s]=>[%s] expires:%s\n", key, value, tostring(self.config.expires)));
    end

    function NGCPLoop:exists(fu, tu, ru)
        if not fu then
            return false
        end
        if not _test_connection(self.client) then
            self.client = _connect(self.config);
        end
        local res = self.client:get(fu);
        local value = string.format("%s;%s", tostring(tu), tostring(ru));
        if res and res == value then
            return true
        else
            return false
        end
    end

    function NGCPLoop:detect(fu, tu, ru)
        if self:exists(fu, tu, ru) then
            return true
        else
            self:add(fu, tu, ru)
            return false
        end
    end
-- class

return NGCPLoop
--EOF
