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
    assertTrue(self.loop)

    self.loop.client = self.client;
end

function TestNGCPLoop:test_exists()
    local fu = "AAA@dom.com";
    local tu = "BBB@domB.com";
    local ru = "CCC@domC.com";

    self.client:ping() ;mc :returns(true)
    self.client:get(fu) ;mc :returns(string.format("%s;%s", tu, ru))

    mc:replay()
    local res = self.loop:exists(fu, tu, ru)
    mc:verify()

    assertTrue(res)
end

function TestNGCPLoop:test_exists_ko()
    local fu = "AAA@dom.com";
    local tu = "BBB@domB.com";
    local ru = "CCC@domC.com";

    self.client:ping() ;mc :returns(true)
    self.client:get(fu) ;mc :returns(string.format("NONO;%s", ru))

    mc:replay()
    local res = self.loop:exists(fu, tu, ru)
    mc:verify()

    assertFalse(res)
end

function TestNGCPLoop:test_exists_tu_nil()
    local tu = "BBB@domB.com";
    local ru = "CCC@domC.com";

    mc:replay()
    local res = self.loop:exists(nil, tu, ru)
    mc:verify()

    assertFalse(res)
end

function TestNGCPLoop:test_add()
    local fu = "AAA@dom.com";
    local tu = "BBB@domB.com";
    local ru = "CCC@domC.com";
    local value = string.format("%s;%s", tu, ru);

    self.client:ping() ;mc :returns(true)
    self.client:set(fu, value, self.loop.config.expires) ;mc :returns(true)

    mc:replay()
    self.loop:add(fu, tu, ru)
    mc:verify()
end

function TestNGCPLoop:test_detect_false()
    local fu = "AAA@dom.com";
    local tu = "BBB@domB.com";
    local ru = "CCC@domC.com";
    local value = string.format("%s;%s", tu, ru);

    self.client:ping() ;mc :returns(true)
     self.client:get(fu) ;mc :returns(nil)
    self.client:ping() ;mc :returns(true)
    self.client:set(fu, value, self.loop.config.expires) ;mc :returns(true)

    mc:replay()
    local res = self.loop:detect(fu, tu, ru)
    mc:verify()

    assertFalse(res)
end

function TestNGCPLoop:test_detect()
    local fu = "AAA@dom.com";
    local tu = "BBB@domB.com";
    local ru = "CCC@domC.com";
    local value = string.format("%s;%s", tu, ru);

    self.client:ping() ;mc :returns(true)
     self.client:get(fu) ;mc :returns(value)

    mc:replay()
    local res = self.loop:detect(fu, tu, ru)
    mc:verify()

    assertTrue(res)
end
-- class
