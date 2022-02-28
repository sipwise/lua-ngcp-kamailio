--
-- Copyright 2014-2022 SipWise Team <development@sipwise.com>
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

local lu = require('luaunit')
local lemock = require('lemock')
local ksrMock = require 'mocks.ksr'

KSR = ksrMock:new()

local mc

-- luacheck: ignore TestNGCPRecentCalls
TestNGCPRecentCalls = {} --class

    function TestNGCPRecentCalls:setUp()
        mc = lemock.controller()
        self.fake_redis = mc:mock()
        self.central = mc:mock()

        package.loaded.redis = self.fake_redis
        local NGCPRecentCalls = require 'ngcp.recentcalls'

        self.rcalls = NGCPRecentCalls.new()
        lu.assertNotNil(self.rcalls)
        lu.assertNotNil(self.rcalls.redis)
        lu.assertNotNil(self.rcalls.redis.config)
        self.rcalls.redis.client = self.central;
    end

    function TestNGCPRecentCalls:test_config()
        local NGCPRecentCalls = require 'ngcp.recentcalls'
        rcalls = NGCPRecentCalls.new({central = {db = 10}})
        lu.assertEquals(rcalls.config.central.db, 10)
        lu.assertNotNil(rcalls.config.central.port)
    end

    function TestNGCPRecentCalls:test_set_by_key()

        local ttl        = 7200
        local key        = "431110001"
        local uuid       = "9bcb88b6-541a-43da-8fdc-816f5557ff93"
        local callid     = "12345-67890"
        local start_time = "1439911398"
        local duration   = 11
        local caller     = "437712345"
        local callee     = "437754321"
        local source     = "SIPWISE_1"

        self.central:ping() ;mc :returns(true)
        self.central:hmset(key,  "callid", callid,
                                 "uuid", uuid,
                                 "start_time", start_time,
                                 "duration", duration,
                                 "caller", caller,
                                 "callee", callee,
                                 "source", source) ;mc :returns(true)
        self.central:expire(key, ttl) ;mc :returns(1)

        mc:replay()
        local res = self.rcalls:set_by_key(key,
                                            callid, uuid,
                                            start_time, duration,
                                            caller, callee,
                                            source)
        mc:verify()

        lu.assertTrue(res)
        lu.assertIs(self.rcalls.redis.client, self.central)
    end

    function TestNGCPRecentCalls:test_set_by_key_ko()
        local ttl        = 7200
        local key        = "431110001"
        local uuid       = "9bcb88b6-541a-43da-8fdc-816f5557ff93"
        local callid     = "12345-67890"
        local start_time = "1439911398"
        local duration   = 11
        local caller     = "437712345"
        local callee     = "437754321"
        local source     = "SIPWISE_1"

        self.central:ping() ;mc :returns(true)
        self.central:hmset(key,  "callid", callid,
                                 "uuid", uuid,
                                 "start_time", start_time,
                                 "duration", duration,
                                 "caller", caller,
                                 "callee", callee,
                                 "source", source) ;mc :returns(false)

        mc:replay()
        local res = self.rcalls:set_by_key(key,
                                            callid, uuid,
                                            start_time, duration,
                                            caller, callee,
                                            source)
        mc:verify()
        lu.assertFalse(res)
        lu.assertIs(self.rcalls.redis.client, self.central)
    end
-- class TestNGCPRecentCalls
--EOF
