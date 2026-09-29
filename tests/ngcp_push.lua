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
local ltn12 = require('ltn12')
local lu = require('luaunit')

local ksrMock = require 'mocks.ksr'
KSR = ksrMock:new()

local mc

local function capture_warnings(fn)
    -- luacheck: globals KSR
    local warnings = {}
    local warn = KSR.warn
    KSR.warn = function(msg) table.insert(warnings, msg) end
    local ok, err = pcall(fn)
    KSR.warn = warn
    lu.assertEvalToTrue(ok, tostring(err))
    return warnings
end

local function drain(source)
    local t = {}
    -- sink.table returns the sink and the table, keep just the sink
    local sink = ltn12.sink.table(t)
    ltn12.pump.all(source, sink)
    return table.concat(t)
end
-- luacheck: ignore TestNGCPPush
TestNGCPPush = {} --class

    function TestNGCPPush:setUp()
        mc = lemock.controller()
        self.fake_redis = mc:mock()
        self.redis = mc:mock()

        package.loaded.redis = self.fake_redis
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
          joined=0,
        }
    end

    function TestNGCPPush:test_add()
        self.redis:ping() ;mc :returns(true)
        self.redis:lpush("whatever", "callid_A#0#label#node#node_uri#stored#0")  ;mc :returns(1)
        self.redis:lpush("callid_A", "whatever#0#label#node#node_uri#stored#0")  ;mc :returns(1)

        mc:replay()
        self.push:add(self.v)
        mc:verify()
    end

    function TestNGCPPush:test_del_ok()
        self.redis:ping() ;mc :returns(true)
        self.redis:lrem("whatever", 0, "callid_A#0#label#node#node_uri#stored#0")  ;mc :returns(1)
        self.redis:llen("whatever") ;mc :returns(0)

        self.redis:ping() ;mc :returns(true)
        self.redis:del("whatever")

        self.redis:lrem("callid_A", 0, "whatever#0#label#node#node_uri#stored#0")  ;mc :returns(1)
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
        self.redis:lrem("whatever", 0, "callid_A#0#label#node#node_uri#stored#0")  ;mc :returns(0)
        self.redis:llen("whatever") ;mc :returns(0)

        self.redis:ping() ;mc :returns(true)
        self.redis:del("whatever") ;mc :returns(0)

        self.redis:lrem("callid_A", 0, "whatever#0#label#node#node_uri#stored#0")  ;mc :returns(0)
        self.redis:llen("callid_A") ;mc :returns(0)

        self.redis:del("callid_A") ;mc :returns(0)

        mc:replay()
        self.push:del(self.v)
        mc:verify()
    end

    function TestNGCPPush:test_callid_get()
        self.redis:ping() ;mc :returns(true)
        self.redis:lrange("callid_A", 0, -1)  ;mc :returns({"whatever#0#label#node#node_uri#stored#0"})

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
        self.redis:lrange("whatever", 0, -1)  ;mc :returns({"callid_A#0#label#node#node_uri#stored#0"})

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

    function TestNGCPPush:test_set_joined()
        self.redis:ping() ;mc :returns(true)
        self.redis:lpos("whatever", "callid_A#0#label#node#node_uri#stored#0")  ;mc :returns(1)
        self.redis:lset("whatever", 1, "callid_A#0#label#node#node_uri#stored#1")  ;mc :returns(1)

        self.redis:lpos("callid_A", "whatever#0#label#node#node_uri#stored#0")  ;mc :returns(2)
        self.redis:lset("callid_A", 2, "whatever#0#label#node#node_uri#stored#1")  ;mc :returns(1)

        mc:replay()
        local res = self.push:set(self.v, 'joined', 1)
        mc:verify()
        lu.assertNotNil(res)
        lu.assertEquals(res.joined, 1)
    end

    function TestNGCPPush:test_set_ko()
        self.redis:ping() ;mc :returns(true)
        self.redis:lpos("whatever", "callid_A#0#label#node#node_uri#stored#0")  ;mc :returns(nil)

        mc:replay()
        lu.assertErrorMsgContains(
            'not found in key[whatever]', self.push.set, self.push, self.v, 'joined', 1)
        mc:verify()
    end

    function TestNGCPPush:test_set_ko_key()

        mc:replay()
        lu.assertErrorMsgContains(
            'key[key] not allowed to change', self.push.set, self.push, self.v, 'key', "nono")
        mc:verify()
    end

    function TestNGCPPush:test_new_warns_on_host_name()
        local NGCPPush = require 'ngcp.push'
        local warnings = capture_warnings(function()
            NGCPPush:new({url = 'http://pushd.example.org:45059/push'})
        end)
        lu.assertEquals(#warnings, 1)
        lu.assertStrContains(warnings[1], 'uses a host name')
        lu.assertStrContains(warnings[1], 'pushd.example.org')
        -- the instance from setUp did not warn on its address based url
        lu.assertNotNil(self.push)
    end

    function TestNGCPPush:test_new_quiet_on_address()
        local NGCPPush = require 'ngcp.push'
        local warnings = capture_warnings(function()
            NGCPPush:new()
            NGCPPush:new({url = 'http://[::1]:45059/push'})
        end)
        lu.assertEquals(warnings, {})
        -- the default the kamailio template relies on is an address too
        lu.assertEquals(self.push.config.url, 'http://127.0.0.1:45059/push')
    end

    -- stands in for socket.http
    function TestNGCPPush:fake_http(result)
        local this = self
        return {
            TIMEOUT = 60,
            request = function(reqt)
                this.reqt = reqt
                this.reqbody = drain(reqt.source)
                this.used_timeout = this.push.c.TIMEOUT
                this.used_https_timeout = require('ssl.https').TIMEOUT
                if not result.code then
                    return nil, result.err
                end
                ltn12.pump.all(ltn12.source.string(result.body), reqt.sink)
                return 1, result.code, result.headers, result.status
            end,
        }
    end

    function TestNGCPPush:test_request()
        self.push.c = self:fake_http({
            code = 200,
            status = 'HTTP/1.1 200 OK',
            headers = {['content-type'] = 'text/plain'},
            body = 'ok',
        })

        local res = self.push:request({push_id = "call-id@1.2.3.4"})

        lu.assertEquals(self.reqt.url, 'http://127.0.0.1:45059/push')
        lu.assertEquals(self.reqt.method, 'POST')
        lu.assertEquals(self.reqt.redirect, false)
        lu.assertEquals(self.reqbody, 'push_id=call%2did%401%2e2%2e3%2e4')
        lu.assertEquals(self.reqt.headers, {
            ['content-type'] = 'application/x-www-form-urlencoded',
            ['content-length'] = #self.reqbody,
        })
        -- our timeout during the request, the module defaults afterwards,
        -- for ssl.https too since socket.http hands https urls over to it
        lu.assertEquals(self.used_timeout, 2)
        lu.assertEquals(self.used_https_timeout, 2)
        lu.assertEquals(self.push.c.TIMEOUT, 60)
        lu.assertEquals(require('ssl.https').TIMEOUT, 60)

        lu.assertEquals(res.code, 200)
        lu.assertEquals(res.codemessage, 'OK')
        lu.assertEquals(res.headers, {['content-type'] = 'text/plain'})
        lu.assertEquals(res.body, 'ok')
    end

    function TestNGCPPush:test_request_no_response()
        self.push.c = self:fake_http({err = 'timeout'})

        local res = self.push:request({push_id = "1234"})

        -- the caller tells a failed request apart by the missing code
        lu.assertNil(res.code)
        lu.assertNil(res.codemessage)
        lu.assertEquals(res.headers, {})
        lu.assertEquals(res.body, '')
        lu.assertEquals(self.push.c.TIMEOUT, 60)
    end
-- class TestNGCPPush
--EOF
