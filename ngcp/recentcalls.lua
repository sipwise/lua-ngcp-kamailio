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
local NGCPRecentCalls = {
     __class__ = 'NGCPRecentCalls'
}
local NGCPRedis = require 'ngcp.redis';
local utils = require 'ngcp.utils';
local utable = utils.table
_ENV = NGCPRecentCalls

local defaults = {
    central = {
        host = '127.0.0.1',
        port = 6379,
        db = 7
    },
    expire = 7200,
    out_expire = 86400
}

-- class NGCPRecentCalls
local NGCPRecentCalls_MT = { __index = NGCPRecentCalls }

NGCPRecentCalls_MT.__tostring = function (t)
    return string.format("config:%s redis:%s",
        utable.tostring(t.config), utable.tostring(t.redis))
end
-- luacheck: globals KSR
    function NGCPRecentCalls:new(config)
        local t = NGCPRecentCalls.init(utils.merge_defaults(config, defaults))
        setmetatable( t, NGCPRecentCalls_MT )
        return t
    end

    function NGCPRecentCalls.init(config)
        return {
            config = config,
            redis = NGCPRedis:new(config.central)
        }
    end

    function NGCPRecentCalls:set_by_key(key,
                                            callid, uuid, start_time,
                                            duration, caller, callee,
                                            source)
        if not self.redis:test_connection() then
            self.redis:connect()
        end
        local res = self.redis.client:hmset(key,
                                        "callid", callid,
                                        "uuid", uuid,
                                        "start_time", start_time,
                                        "duration", duration,
                                        "caller", caller,
                                        "callee", callee,
                                        "source", source)
        if res then
            self.redis.client:expire(key, self.config.expire)
        end
        local msg = "central:hset[%s]=>[%s] callid: %s uuid: %s " ..
            "start_time: %s duration: %s caller: %s callee: %s source: %s expire: %d\n"
        KSR.info(msg:format(key, tostring(res),
                            callid, uuid,
                            start_time, duration,
                            caller, callee,
                            source,
                            self.config.expire))
        return res
    end

    function NGCPRecentCalls:set_element_by_key(key, element, value)
        if not self.redis:test_connection() then
            self.redis:connect()
        end

        local res = self.redis.client:hmset(key, element, value)
        if res then
            self.redis.client:expire(key, self.config.out_expire)
        end
        KSR.info(string.format("central:hset[%s]=>[%s] %s: %s expire: %d\n",
                            key, tostring(res),
                            element, tostring(value),
                            self.config.out_expire))
        return res
    end

    function NGCPRecentCalls:get_element_by_key(key, element)
        if not self.redis:test_connection() then
            self.redis:connect()
        end

        local res = self.redis.client:hgetall(key)
        if res then
            KSR.info(string.format("central:hget[%s]=>[%s]\n",
                                    key, tostring(res[element])))

            return res[element]
        end

        return 0
    end

    function NGCPRecentCalls:del_by_key(key)
        if not self.redis:test_connection() then
            self.redis:connect()
        end

        self.redis.client:del(key)
        KSR.info(string.format("central:del[%s] removed\n", key));

        return 0
    end

-- class

return NGCPRecentCalls
--EOF
