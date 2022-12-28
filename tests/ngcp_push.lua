--
-- Copyright 2022 SipWise Team <development@sipwise.com>
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
local lemock = require('lemock')
local lu = require('luaunit')
local utils = require 'ngcp.utils'

local ksrMock = require 'mocks.ksr'
KSR = ksrMock:new()

local mc
-- luacheck: ignore TestNGCPPush
TestNGCPPush = {} --class

    function TestNGCPPush:setUp()
        mc = lemock.controller()
        self.fake_redis = mc:mock()
        self.fake_curl = utils.inheritsFrom(mc:mock())
        self.fake_curl.easy_init = function()
            return self.curl
        end
        self.redis = mc:mock()
        self.curl = mc:mock()

        package.loaded.redis = self.fake_redis
        package.loaded.curl = self.fake_curl
        local NGCPPush = require 'ngcp.push'

        self.push = NGCPPush:new()

        lu.assertEvalToTrue(self.push)
        self.push.redis.client = self.redis

        self.v = {
          key="whatever",
          idx="0",
          label="label",
          callid="callid_A",
          node="node",
          node_uri="node_uri",
          mode="stored",
        }
    end

    function TestNGCPPush:test_add()
        self.redis:ping() ;mc :returns(true)
        self.redis:lpush("whatever", "callid_A#0#label#node#node_uri#stored")  ;mc :returns(1)
        self.redis:lpush("callid_A", "whatever#0#label#node#node_uri#stored")  ;mc :returns(1)

        mc:replay()
        self.push:add(self.v)
        mc:verify()
    end

    function TestNGCPPush:test_del_ok()
        self.redis:ping() ;mc :returns(true)
        self.redis:lrem("whatever", 0, "callid_A#0#label#node#node_uri#stored")  ;mc :returns(1)
        self.redis:llen("whatever") ;mc :returns(0)

        self.redis:ping() ;mc :returns(true)
        self.redis:del("whatever")

        self.redis:lrem("callid_A", 0, "whatever#0#label#node#node_uri#stored")  ;mc :returns(1)
        self.redis:llen("callid_A") ;mc :returns(1)

        mc:replay()
        self.push:del(self.v)
        mc:verify()
    end

    function TestNGCPPush:test_del_ko()
        -- https://redis.io/commands/lrem/
        -- Note that non-existing keys are treated like empty lists,
        -- so when key does not exist, the command will always return 0.
        self.redis:ping() ;mc :returns(true)
        self.redis:lrem("whatever", 0, "callid_A#0#label#node#node_uri#stored")  ;mc :returns(0)
        self.redis:llen("whatever") ;mc :returns(0)

        self.redis:ping() ;mc :returns(true)
        self.redis:del("whatever") ;mc :returns(0)

        self.redis:lrem("callid_A", 0, "whatever#0#label#node#node_uri#stored")  ;mc :returns(0)
        self.redis:llen("callid_A") ;mc :returns(0)

        self.redis:del("callid_A") ;mc :returns(0)

        mc:replay()
        self.push:del(self.v)
        mc:verify()
    end

    function TestNGCPPush:test_callid_get()
        self.redis:ping() ;mc :returns(true)
        self.redis:lrange("callid_A", 0, -1)  ;mc :returns({"whatever#0#label#node#node_uri#stored"})

        mc:replay()
        local res = self.push:callid_get("callid_A")
        mc:verify()
        lu.assertNotNil(res)
        self.v.callid = nil
        lu.assertEquals(res[1], self.v)
    end

    function TestNGCPPush:test_callid_get_ko()
        self.redis:ping() ;mc :returns(true)
        self.redis:lrange("callid_A", 0, -1)  ;mc :returns({})

        mc:replay()
        local res = self.push:callid_get("callid_A")
        mc:verify()
        lu.assertEquals(res, {})
    end

    function TestNGCPPush:test_get()
        self.redis:ping() ;mc :returns(true)
        self.redis:lrange("whatever", 0, -1)  ;mc :returns({"callid_A#0#label#node#node_uri#stored"})

        mc:replay()
        local res = self.push:callid_get("whatever")
        mc:verify()
        lu.assertNotNil(res)
        self.v.callid = nil
        self.v.key = "callid_A"
        lu.assertEquals(res[1], self.v)
    end

    function TestNGCPPush:test_get_ko()
        self.redis:ping() ;mc :returns(true)
        self.redis:lrange("whatever", 0, -1)  ;mc :returns({})

        mc:replay()
        local res = self.push:callid_get("whatever")
        mc:verify()
        lu.assertEquals(res, {})
    end
-- class TestNGCPPush
--EOF
