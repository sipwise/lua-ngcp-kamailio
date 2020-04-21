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
local pvMock = require 'mocks.pv'
local pvxMock = require 'mocks.pvx'

-- luacheck: ignore TestPVXMock
TestPVXMock = {}
    function TestPVXMock:setUp()
        self.pv = pvMock.new()
        self.pvx = pvxMock.new(self.pv)

        self.pv.sets("$xavp(test=>uno)", "uno")
        lu.assertEquals(self.pv.get("$xavp(test[0]=>uno)"), "uno")
        self.pv.seti("$xavp(test[0]=>dos)", 4)
        self.pv.seti("$xavp(test[0]=>dos)", 2)
        lu.assertEquals(self.pv.get("$xavp(test[0]=>dos)"), 2)
        self.pv.seti("$xavp(test=>uno)", 3)
        self.pv.seti("$xavp(test[0]=>uno)", 1)
        lu.assertEquals(self.pv.get("$xavp(test[0]=>uno)"), 1)
        self.pv.sets("$xavp(test[0]=>dos)", "dos")
        lu.assertEquals(self.pv.get("$xavp(test[0]=>dos)"), "dos")
        self.pv.seti("$xavp(test[0]=>tres)", 3)
        lu.assertEquals(self.pv.get("$xavp(test[0]=>tres)"), 3)
        --
        lu.assertEquals(self.pv.get("$xavp(test[1]=>uno)"), "uno")
        lu.assertEquals(self.pv.get("$xavp(test[1]=>dos)"), 2)
    end

    function TestPVXMock:tearDown()
        self.pv.vars = {}
    end

    function TestPVXMock:test_xavp_get()
        local l = self.pvx.xavp_get("test")
        local m = tostring(self.pv.vars["xavp:test"])
        lu.assertEquals(l, "<<xavp:"..m:sub(8)..">>")
    end

    function TestPVXMock:test_xavp_gete()
        lu.assertEquals(self.pvx.xavp_gete("fake"), "")
    end

    function TestPVXMock:test_xavp_getw()
        lu.assertEquals(self.pvx.xavp_getw("fake"), "<null>")
    end

    function TestPVXMock:test_get_keys()
        local l = self.pvx.xavp_get_keys("test", 0)
        lu.assertNotNil(l)
        lu.assertItemsEquals(l, {"uno", "dos", "tres"})
    end

    function TestPVXMock:test_get_keys_1()
        local l = self.pvx.xavp_get_keys("test", 1)
        lu.assertNotNil(l)
        lu.assertItemsEquals(l, {"uno", "dos"})
    end

    function TestPVXMock:test_getd()
        local l = self.pvx.xavp_getd("test")
        lu.assertNotNil(l)
        lu.assertItemsEquals(l, {
            {uno={1,3}, dos={"dos"}, tres={3}},
            {uno={"uno"}, dos={2,4}}
        })
    end

    function TestPVXMock:test_getd_p1()
        local l = self.pvx.xavp_getd_p1("test", 1)
        lu.assertNotNil(l)
        lu.assertItemsEquals(l, {uno={"uno"}, dos={2,4}})
    end
--EOF
