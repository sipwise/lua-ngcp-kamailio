--
-- Copyright 2013-2015 SipWise Team <development@sipwise.com>
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
local pvMock = require 'mocks.pv'
local xavpMock = require 'mocks.xavp'

-- luacheck: ignore TestXAVPMock
TestXAVPMock = {}
    function TestXAVPMock:setUp()
        self.pv = pvMock.new()
        self.xavp = xavpMock.new(self.pv)

        self.pv.sets("$xavp(test=>uno)", "uno")
        assertEquals(self.pv.get("$xavp(test[0]=>uno)"), "uno")
        self.pv.seti("$xavp(test[0]=>dos)", 4)
        self.pv.seti("$xavp(test[0]=>dos)", 2)
        assertEquals(self.pv.get("$xavp(test[0]=>dos)"), 2)
        self.pv.seti("$xavp(test=>uno)", 3)
        self.pv.seti("$xavp(test[0]=>uno)", 1)
        assertEquals(self.pv.get("$xavp(test[0]=>uno)"), 1)
        self.pv.sets("$xavp(test[0]=>dos)", "dos")
        assertEquals(self.pv.get("$xavp(test[0]=>dos)"), "dos")
        self.pv.seti("$xavp(test[0]=>tres)", 3)
        assertEquals(self.pv.get("$xavp(test[0]=>tres)"), 3)
        --
        assertEquals(self.pv.get("$xavp(test[1]=>uno)"), "uno")
        assertEquals(self.pv.get("$xavp(test[1]=>dos)"), 2)
    end

    function TestXAVPMock:tearDown()
        self.pv.vars = {}
    end

    function TestXAVPMock:test_get_keys()
        local l = self.xavp.get_keys("test", 0)
        assertEvalToTrue(l)
        assertItemsEquals(l, {"uno", "dos", "tres"})
    end

    function TestXAVPMock:test_get_keys_1()
        local l = self.xavp.get_keys("test", 1)
        assertEvalToTrue(l)
        assertItemsEquals(l, {"uno", "dos"})
    end

    function TestXAVPMock:test_get_simple()
        local l = self.xavp.get("test", 0, 1)
        assertEvalToTrue(l)
        assertItemsEquals(l, {uno=1, dos="dos", tres=3})
    end

    function TestXAVPMock:test_get_simple_1()
        local l = self.xavp.get("test", 1, 1)
        assertEvalToTrue(l)
        assertItemsEquals(l, {uno="uno", dos=2})
    end

    function TestXAVPMock:test_get()
        local l = self.xavp.get("test", 0, 0)
        assertEvalToTrue(l)
        assertItemsEquals(l, {uno={1,3}, dos={"dos"}, tres={3}})
    end

    function TestXAVPMock:test_get_1()
        local l = self.xavp.get("test", 1, 0)
        assertEvalToTrue(l)
        assertItemsEquals(l, {uno={"uno"}, dos={2,4}})
    end
--EOF
