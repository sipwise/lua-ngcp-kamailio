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

local lu = require('luaunit')
local lemock = require('lemock')
local ksrMock = require 'mocks.ksr'
local utils = require 'ngcp.utils'

KSR = ksrMock:new()

local mc

-- luacheck: ignore TestNGCPRedis
TestNGCPRedis = {} --class

  function TestNGCPRedis:setUp()
    mc = lemock.controller()
    self.fake_redis = mc:mock()
    local fake_client = utils.inheritsFrom(mc:mock())
    self.socket = mc:mock()
    fake_client.network = { socket = self.socket }
    self.client = fake_client:create()

    package.loaded.redis = self.fake_redis
    local NGCPRedis = require 'ngcp.redis'

    self.ngcp_redis = NGCPRedis.new()
    lu.assertNotNil(self.ngcp_redis)
    lu.assertNotNil(self.ngcp_redis.config)
    self.ngcp_redis.client = self.client;
  end

  function TestNGCPRedis:test_connection_ok()
    local prev = self.client
    self.client:ping() ;mc :returns(true)

    mc:replay()
    local ok = self.ngcp_redis:test_connection()
    mc:verify()

    lu.assertTrue(ok)
    lu.assertIs(prev, self.ngcp_redis.client)
  end

  function TestNGCPRedis:test_connection_fail()
    local prev = self.client
    self.client:ping() ;mc :error("error")
    self.socket:getfd() ;mc:returns(3)
    self.socket:close() ;mc:returns(true)

    mc:replay()
    local res = self.ngcp_redis:test_connection()
    mc:verify()

    lu.assertFalse(res)
    lu.assertNil(self.ngcp_redis.client)
  end

  function TestNGCPRedis:test_connect_ok()
    local c = self.ngcp_redis.config
    self.fake_redis.connect(c.host, c.port) ;mc :returns(self.client)
    self.client:select(c.db) ;mc :returns(true)
    self.socket:getfd() ;mc:returns(3)

    mc:replay()
    local res = self.ngcp_redis:connect()
    mc:verify()
    lu.assertIs(res, self.client)
  end
