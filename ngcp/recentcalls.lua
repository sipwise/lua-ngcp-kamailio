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
local NGCPRecentCalls = {
     __class__ = 'NGCPRecentCalls'
}
local redis = require 'redis';
require 'ngcp.utils';

_ENV = NGCPRecentCalls

-- class NGCPRecentCalls
local NGCPRecentCalls_MT = { __index = NGCPRecentCalls }

NGCPRecentCalls_MT.__tostring = function (t)
    return string.format("config:%s central:%s",
        table.tostring(t.config), table.tostring(t.central))
end

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
                expire = 7200
            },
            central = {},
        };
        return t;
    end

    function NGCPRecentCalls._test_connection(client)
        if not client then return nil end
        local ok, _ = pcall(client.ping, client)
        return ok
    end

    function NGCPRecentCalls._connect(config)
        local client = redis.connect(config.host,config.port)
        client:select(config.db)
        sr.log("info", string.format("connected to redis server %s:%d at %s\n",
            config.host, config.port, config.db))
        return client
    end

    function NGCPRecentCalls:set_by_uuid(uuid, callid, start_time,
                                            duration, caller, callee,
                                            caller_id, callee_id)
        if not self._test_connection(self.central) then
            self.central = self._connect(self.config.central)
        end
        local res = self.central:hmset(uuid, "callid", callid,
                                        "start_time", start_time,
                                        "duration", duration,
                                        "caller", caller,
                                        "callee", callee,
                                        "caller_id", caller_id,
                                        "callee_id", callee_id)
        if res then
            self.central:expire(uuid, self.config.expire)
        end
        sr.log("info", string.format("central:hset[%s]=>[%s] callid: %s start_time: %s duration: %d caller: %s callee: %s caller_id: %s callee_id: %s expire: %d\n",
                                    uuid, tostring(res),
                                    callid,
                                    start_time, duration,
                                    caller, callee,
                                    caller_id, callee_id,
                                    self.config.expire))
        return res
    end

-- class

return NGCPRecentCalls
--EOF
