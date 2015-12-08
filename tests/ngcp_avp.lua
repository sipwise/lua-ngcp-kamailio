--
-- Copyright 2013 SipWise Team <development@sipwise.com>
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
require('luaunit')
local srMock = require 'mocks.sr'
local NGCPAvp = require 'ngcp.avp'

sr = srMock.new()

-- luacheck: ignore TestNGCPAvp
TestNGCPAvp = {} --class
    function TestNGCPAvp:setUp()
        self.avp = NGCPAvp:new("testid")
    end

    function TestNGCPAvp:tearDown()
        sr.pv.vars = {}
    end

    function TestNGCPAvp:test_avp_id()
        assertEquals(self.avp.id, "$avp(s:testid)")
    end

    function TestNGCPAvp:test_avp_get()
        sr.pv.sets("$avp(s:testid)", "value")
        assertEquals(self.avp(), "value")
        sr.pv.sets("$avp(s:testid)", "1")
        assertItemsEquals(self.avp(), "1")
        assertItemsEquals(self.avp:all(),{"1","value"})
    end

    function TestNGCPAvp:test_avp_set()
        local vals = {1,2,3}
        local okvals = {3,2,1}
        for i=1,#vals do
            self.avp(vals[i])
            assertEquals(self.avp(),vals[i])
        end
        assertEquals(self.avp:all(), okvals)
    end

    function TestNGCPAvp:test_avp_set2()
        local vals = {1,2,"3"}
        local okvals = {"3",2,1}
        for i=1,#vals do
            self.avp(vals[i])
            assertEquals(self.avp(),vals[i])
        end
        assertEquals(self.avp:all(), okvals)
    end

    function TestNGCPAvp:test_avp_set_list()
        local vals = {1,2, {"3", 4}}
        local okvals = {4, "3", 2, 1}

        for i=1,#vals do
            self.avp(vals[i])
        end
        assertItemsEquals(self.avp:all(), okvals)
    end

    function TestNGCPAvp:test_clean()
        self.avp(1)
        self.avp:clean()
        assertFalse(self.avp())
    end

    function TestNGCPAvp:test_log()
        self.avp:log()
    end

    function TestNGCPAvp:test_tostring()
        self.avp(1)
        assertEquals(tostring(self.avp), "$avp(s:testid):1")
        self.avp("hola")
        assertEquals(tostring(self.avp), "$avp(s:testid):hola")
    end
-- class TestNGCPAvp
--EOF
