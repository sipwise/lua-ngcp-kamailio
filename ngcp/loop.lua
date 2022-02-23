--
-- Copyright 2016-2022 SipWise Team <development@sipwise.com>
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
local NGCPRedis = require 'ngcp.redis';
local utils = require 'ngcp.utils';
local utable = utils.table

_ENV = NGCPLoop

local defaults = {
    host = '127.0.0.1',
    port = 6379,
    db = 3,
    expire = 5,
    max = 5
}

-- class NGCPLoop
local NGCPLoop_MT = { __index = NGCPLoop }

NGCPLoop_MT.__tostring = function (t)
    return string.format("config:%s",
        utable.tostring(t.config));
end
-- luacheck: globals KSR
    function NGCPLoop.new(config)
        local t = NGCPLoop.init(utils.merge_defaults(config, defaults))
        setmetatable( t, NGCPLoop_MT )
        return t
    end

    function NGCPLoop.init(config)
        return {
            config = config,
            redis = NGCPRedis.new(config)
        }
    end

    function NGCPLoop:add(fu, tu, ru)
        if not self.redis:test_connection() then
            self.redis:connect()
        end

        local key = string.format("%s;%s;%s",
            tostring(fu), tostring(tu), tostring(ru));
        local res = self.redis.client:incr(key);
        if res == 1 then
            self.redis.client:expire(key, self.config.expire);
        end
        KSR.dbg(string.format("[%s]=>[%s] expires:%s\n",
            key, tostring(res), tostring(self.config.expires)));
        return res;
    end

    function NGCPLoop:detect(fu, tu, ru)
        local num = self:add(fu, tu, ru)
        if num >= self.config.max then
            return true
        end
        return false
    end
-- class

return NGCPLoop
--EOF
