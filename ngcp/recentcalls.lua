--
-- Copyright 2015-2020 SipWise Team <development@sipwise.com>
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
local redis = require 'redis';
local utils = require 'ngcp.utils';
local utable = utils.table
_ENV = NGCPRecentCalls

-- class NGCPRecentCalls
local NGCPRecentCalls_MT = { __index = NGCPRecentCalls }

NGCPRecentCalls_MT.__tostring = function (t)
    return string.format("config:%s central:%s",
        utable.tostring(t.config), utable.tostring(t.central))
end
-- luacheck: globals KSR
    function NGCPRecentCalls.new()
        local t = NGCPRecentCalls.init();
        setmetatable( t, NGCPRecentCalls_MT )
        return t;
    end

    function NGCPRecentCalls.init()
        local t = {
            config = {
                central = {
                    host = '127.0.0.1',
                    port = 6379,
                    db = "7"
                },
                expire = 7200,
                out_expire = 86400
            },
            central = {},
        };
        return t;
    end

    function NGCPRecentCalls._test_connection(client)
        if not client then return nil end
        local ok, _ = pcall(client.ping, client)
        if not ok then
            KSR.info(string.format("close redis server[%d]\n",
              client.network.socket:getfd()))
            client.network.socket:close()
        end
        return ok
    end

    function NGCPRecentCalls._connect(config)
        local client = redis.connect(config.host,config.port)
        client:select(config.db)
        KSR.info(string.format("connected to redis server %s:%d at %s\n",
            config.host, config.port, config.db))
        return client
    end

    function NGCPRecentCalls:set_by_key(key,
                                            callid, uuid, start_time,
                                            duration, caller, callee,
                                            source)
        if not self._test_connection(self.central) then
            self.central = self._connect(self.config.central)
        end
        local res = self.central:hmset(key,
                                        "callid", callid,
                                        "uuid", uuid,
                                        "start_time", start_time,
                                        "duration", duration,
                                        "caller", caller,
                                        "callee", callee,
                                        "source", source)
        if res then
            self.central:expire(key, self.config.expire)
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
        if not self._test_connection(self.central) then
            self.central = self._connect(self.config.central)
        end

        local res = self.central:hmset(key, element, value)
        if res then
            self.central:expire(key, self.config.out_expire)
        end
        KSR.info(string.format("central:hset[%s]=>[%s] %s: %s expire: %d\n",
                            key, tostring(res),
                            element, tostring(value),
                            self.config.out_expire))
        return res
    end

    function NGCPRecentCalls:get_element_by_key(key, element)
        if not self._test_connection(self.central) then
            self.central = self._connect(self.config.central)
        end

        local res = self.central:hgetall(key)
        if res then
            KSR.info(string.format("central:hget[%s]=>[%s]\n",
                                    key, tostring(res[element])))

            return res[element]
        end

        return 0
    end

    function NGCPRecentCalls:del_by_key(key)
        if not self._test_connection(self.central) then
            self.central = self._connect(self.config.central)
        end

        self.central:del(key)
        KSR.info(string.format("central:del[%s] removed\n", key));

        return 0
    end

-- class

return NGCPRecentCalls
--EOF
