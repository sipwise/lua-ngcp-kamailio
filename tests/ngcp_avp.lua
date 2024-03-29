--
-- Copyright 2013-2020 SipWise Team <development@sipwise.com>
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
local ksrMock = require 'mocks.ksr'
local NGCPAvp = require 'ngcp.avp'

KSR = ksrMock:new()

-- luacheck: ignore TestNGCPAvp
TestNGCPAvp = {} --class
    function TestNGCPAvp:setUp()
        self.avp = NGCPAvp:new("testid")
    end

    function TestNGCPAvp:tearDown()
        KSR.pv.vars = {}
    end

    function TestNGCPAvp:test_avp_id()
        lu.assertEquals(self.avp.id, "$avp(s:testid)")
    end

    function TestNGCPAvp:test_avp_get()
        KSR.pv.sets("$avp(s:testid)", "value")
        lu.assertEquals(self.avp(), "value")
        KSR.pv.sets("$avp(s:testid)", "1")
        lu.assertItemsEquals(self.avp(), "1")
        lu.assertItemsEquals(self.avp:all(),{"1","value"})
    end

    function TestNGCPAvp:test_avp_set()
        local vals = {1,2,3}
        local okvals = {3,2,1}
        for i=1,#vals do
            self.avp(vals[i])
            lu.assertEquals(self.avp(),vals[i])
        end
        lu.assertEquals(self.avp:all(), okvals)
    end

    function TestNGCPAvp:test_avp_set2()
        local vals = {1,2,"3"}
        local okvals = {"3",2,1}
        for i=1,#vals do
            self.avp(vals[i])
            lu.assertEquals(self.avp(),vals[i])
        end
        lu.assertEquals(self.avp:all(), okvals)
    end

    function TestNGCPAvp:test_avp_set_list()
        local vals = {1,2, {"3", 4}}
        local okvals = {4, "3", 2, 1}

        for i=1,#vals do
            self.avp(vals[i])
        end
        lu.assertItemsEquals(self.avp:all(), okvals)
    end

    function TestNGCPAvp:test_avp_del()
        local vals = {1,2, {"3", 4}}
        local okvals = {4, "3", 2, 1}

        for i=1,#vals do
            self.avp(vals[i])
        end
        lu.assertItemsEquals(self.avp:all(), okvals)
        self.avp:del(1)
        lu.assertItemsEquals(self.avp:all(), {4, "3", 2})
        self.avp:del(4)
        lu.assertItemsEquals(self.avp:all(), {"3", 2})
        self.avp:del(1)
        lu.assertItemsEquals(self.avp:all(), {"3", 2})
        self.avp:del("3")
        lu.assertItemsEquals(self.avp:all(), {2})
        self.avp:del(2)
        lu.assertNil(self.avp:all())
        self.avp:del(nil)
        lu.assertNil(self.avp:all())
    end

    function TestNGCPAvp:test_clean()
        self.avp(1)
        self.avp:clean()
        lu.assertNil(self.avp())
    end

    function TestNGCPAvp:test_log()
        self.avp:log()
    end

    function TestNGCPAvp:test_tostring()
        self.avp(1)
        lu.assertEquals(tostring(self.avp), "$avp(s:testid):1")
        self.avp("hola")
        lu.assertEquals(tostring(self.avp), "$avp(s:testid):hola")
    end
-- class TestNGCPAvp
--EOF
