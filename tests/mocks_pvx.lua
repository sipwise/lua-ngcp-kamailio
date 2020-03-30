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
local pvxMock = require 'mocks.pvx'

-- luacheck: ignore TestXAVPMock
TestXAVPMock = {}
    function TestXAVPMock:setUp()
        self.pv = pvMock.new()
        self.pvx = pvxMock.new(self.pv)

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

    function TestXAVPMock:test_xavp_get()
        local l = self.pvx.xavp_get("test")
        local m = tostring(self.pv.vars["xavp:test"])
        assertItemsEquals(l, "<<xavp:"..m:sub(8)..">>")
    end

    function TestXAVPMock:test_xavp_gete()
        assertItemsEquals(self.pvx.xavp_gete("fake"), "")
    end

    function TestXAVPMock:test_xavp_getw()
        assertItemsEquals(self.pvx.xavp_getw("fake"), "<null>")
    end
--EOF
