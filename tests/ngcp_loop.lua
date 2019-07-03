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

local lemock = require('lemock')
require('luaunit')

local srMock = require 'mocks.sr'
sr = srMock:new()

local mc

-- luacheck: ignore TestNGCPLoop
TestNGCPLoop = {} --class

function TestNGCPLoop:setUp()
    mc = lemock.controller()
    self.fake_redis = mc:mock()
    self.client = mc:mock()

    package.loaded.redis = self.fake_redis
    local NGCPLoop = require 'ngcp.loop'

    self.loop = NGCPLoop.new()
    assertEvalToTrue(self.loop)

    self.loop.client = self.client;
    self.loop.config.max = 5;
    self.loop.config.expire = 1;
end

function TestNGCPLoop:test_add()
    local fu = "AAA@dom.com";
    local tu = "BBB@domB.com";
    local ru = "CCC@domC.com";
    local key = string.format("%s;%s;%s", fu, tu, ru);

    self.client:ping() ;mc :returns(true)
    self.client:incr(key) ;mc :returns(1)
    self.client:expire(key, self.loop.config.expire) ;mc :returns(1)

    mc:replay()
    local res = self.loop:add(fu, tu, ru)
    mc:verify()

    assertEquals(res, 1)
end

function TestNGCPLoop:test_detect_false()
    local fu = "AAA@dom.com";
    local tu = "BBB@domB.com";
    local ru = "CCC@domC.com";
    local key = string.format("%s;%s;%s", fu, tu, ru);

    self.client:ping() ;mc :returns(true)
    self.client:incr(key) ;mc :returns(1)
    self.client:expire(key, self.loop.config.expire) ;mc :returns(1)

    mc:replay()
    local res = self.loop:detect(fu, tu, ru)
    mc:verify()

    assertFalse(res)
end

function TestNGCPLoop:test_detect_ko()
    local fu = "AAA@dom.com";
    local tu = "BBB@domB.com";
    local ru = "CCC@domC.com";
    local key = string.format("%s;%s;%s", fu, tu, ru);

    self.client:ping() ;mc :returns(true)
    self.client:incr(key) ;mc :returns(2)

    mc:replay()
    local res = self.loop:detect(fu, tu, ru)
    mc:verify()

    assertFalse(res)
end

function TestNGCPLoop:test_detect()
    local fu = "AAA@dom.com";
    local tu = "BBB@domB.com";
    local ru = "CCC@domC.com";
    local key = string.format("%s;%s;%s", fu, tu, ru);

    self.client:ping() ;mc :returns(true)
    self.client:incr(key) ;mc :returns(self.loop.config.max)

    mc:replay()
    local res = self.loop:detect(fu, tu, ru)
    mc:verify()

    assertTrue(res)
end
-- class
