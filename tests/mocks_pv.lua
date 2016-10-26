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
local hdrMock = require 'mocks.hdr'
local pvMock = require 'mocks.pv'

-- luacheck: ignore TestPVMock
TestPVMock = {}
    function TestPVMock:setUp()
        local hdr = hdrMock.new()
        self.pv = pvMock.new(hdr)
    end

    function TestPVMock:tearDown()
        self.pv.vars = {}
    end

    function TestPVMock:test_ini()
        assertTrue(self.pv)
    end

    function TestPVMock:test_clean_id()
        assertEquals(self.pv._clean_id('s:u25'), 'u25')
        assertEquals(self.pv._clean_id('i:u25'), 'u25')
        assertEquals(self.pv._clean_id('u25'), 'u25')
    end

    function TestPVMock:test_is_pv_simple()
        local result = self.pv._is_pv("$si")
        assertTrue(result)
        assertEquals(result.type, 'pv')
        assertEquals(result.id, 'si')
        assertEquals(result.key, nil)
        assertEquals(result.mode, 'ro')
        assertFalse(result.clean)
    end

    function TestPVMock:test_is_pv_rw()
        local result = self.pv._is_pv("$rU")
        assertTrue(result)
        assertEquals(result.type, 'pv')
        assertEquals(result.id, 'rU')
        assertEquals(result.key, nil)
        assertEquals(result.mode, 'rw')
        assertFalse(result.clean)
    end

    function TestPVMock:test_is_hdr_simple()
        local result = self.pv._is_hdr("$hdr(id)")
        assertTrue(result)
        assertEquals(result.type, 'hdr')
        assertEquals(result.id, 'id')
        assertEquals(result.key, nil)
        assertFalse(result.clean)
    end

    function TestPVMock:test_is_hdr_complex()
        local result = self.pv._is_hdr("$hdr($si)")
        assertTrue(result)
        assertEquals(result.type, 'hdr')
        assertEquals(result.id, '$si')
        assertEquals(result.key, nil)
        assertFalse(result.clean)
    end

    function TestPVMock:test_is_xavp_simple()
        local result = self.pv._is_xavp("$xavp(id=>key)")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id')
        assertEquals(result.key, 'key')
        assertIsNil(result.indx)
        assertIsNil(result.kindx)
        assertFalse(result.clean)
    end

    function TestPVMock:test_is_xavp_complex()
        local result = self.pv._is_xavp("$xavp(id1[8]=>key3g2)")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id1')
        assertEquals(result.key, 'key3g2')
        assertEquals(result.indx, 8)
        assertIsNil(result.kindx)
        assertFalse(result.clean)
        result = self.pv._is_xavp("$xavp(id2g1f[9]=>keygg33_f)")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id2g1f')
        assertEquals(result.key, 'keygg33_f')
        assertEquals(result.indx, 9)
        assertIsNil(result.kindx)
        assertFalse(result.clean)
    end

    function TestPVMock:test_is_xavp_complex_indx()
        local result = self.pv._is_xavp("$xavp(id1[8]=>key3g2)")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id1')
        assertEquals(result.key, 'key3g2')
        assertEquals(result.indx, 8)
        assertIsNil(result.kindx)
        assertFalse(result.clean)
        result = self.pv._is_xavp("$xavp(id2g1f[9]=>keygg33_f[2])")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id2g1f')
        assertEquals(result.key, 'keygg33_f')
        assertEquals(result.indx, 9)
        assertEquals(result.kindx, 2)
        assertFalse(result.clean)
    end

    function TestPVMock:test_is_xavp_complex_indx2()
        local result = self.pv._is_xavp("$xavp(gogo[9]=>gogo[*])")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'gogo')
        assertEquals(result.key, 'gogo')
        assertEquals(result.indx, 9)
        assertFalse(result.kindx)
        assertTrue(result.clean)
    end

    function TestPVMock:test_is_xavp_simple_nokey()
        local result = self.pv._is_xavp("$xavp(id1[8])")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id1')
        assertFalse(result.key)
        assertEquals(result.indx, 8)
        assertFalse(result.clean)
    end

    function TestPVMock:test_is_xavp_simple_nokey_noindx()
        local result = self.pv._is_xavp("$xavp(id1)")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id1')
        assertFalse(result.key)
        assertIsNil(result.indx)
        assertIsNil(result.kindx)
        assertFalse(result.clean)
    end

    function TestPVMock:test_is_avp_simple()
        local result = self.pv._is_avp("$avp(id2_f)")
        assertTrue(result)
        assertEquals(result.type, 'avp')
        assertEquals(result.id, 'id2_f')
        assertIsNil(result.indx)
        assertFalse(result.clean)
    end

    function TestPVMock:test_is_avp_simple1()
        local result = self.pv._is_avp("$(avp(s:id))")
        assertTrue(result)
        assertEquals(result.type, 'avp')
        assertEquals(result.id, 'id')
        assertIsNil(result.indx)
        assertFalse(result.clean)
    end

    function TestPVMock:test_is_avp_simple2()
        local result = self.pv._is_avp("$(avp(id))")
        assertTrue(result)
        assertEquals(result.type, 'avp')
        assertEquals(result.id, 'id')
        assertIsNil(result.indx)
        assertFalse(result.clean)
    end

    function TestPVMock:test_is_avp_simple3()
        local result = self.pv._is_avp("$(avp(s:id)[*])")
        assertTrue(result)
        assertEquals(result.type, 'avp')
        assertEquals(result.id, 'id')
        assertIsNil(result.indx)
        assertTrue(result.clean)
    end

    function TestPVMock:test_is_avp_simple4()
        local result = self.pv._is_avp("$(avp(s:id)[1])")
        assertTrue(result)
        assertEquals(result.type, 'avp')
        assertEquals(result.id, 'id')
        assertEquals(result.indx, 1)
        assertFalse(result.clean)
    end

    function TestPVMock:test_is_var_simple()
        local result = self.pv._is_var("$var(id)")
        assertTrue(result)
        assertEquals(result.type, 'var')
        assertEquals(result.id, 'id')
        --print(table.tostring(result))
        assertFalse(result.clean)
    end

    function TestPVMock:test_var_sets()
        self.pv.sets("$var(hithere)", "value")
        assertEquals(self.pv.get("$var(hithere)"), "value")
        assertError(self.pv.sets, "$var(hithere)", 1)
        assertError(self.pv.sets, "$var(s:hithere)", "1")
        assertError(self.pv.sets, "$(var(hithere)[*])", "1")
        assertError(self.pv.sets, "$(var(s:hithere))", "1")
        self.pv.sets("$(var(hithere))", "new_value")
        assertEquals(self.pv.get("$var(hithere)"), "new_value")
        assertEquals(self.pv.vars["var:hithere"], "new_value")
    end

    function TestPVMock:test_var_seti()
        self.pv.seti("$var(hithere)", 0)
        assertEquals(self.pv.get("$var(hithere)"), 0)
        assertError(self.pv.seti, "$var(hithere)", "1")
        assertError(self.pv.sets, "$var(s:hithere)", 1)
        assertError(self.pv.sets, "$(var(hithere)[*])", 1)
        assertError(self.pv.sets, "$(var(s:hithere))", 1)
        assertEquals(self.pv.get("$var(hithere)"), 0)
        self.pv.seti("$var(hithere)", 1)
        assertEquals(self.pv.get("$var(hithere)"), 1)
        assertEquals(self.pv.vars["var:hithere"], 1)
    end

    function TestPVMock:test_avp_sets()
        self.pv.sets("$avp(s:hithere)", "value")
        assertEquals(self.pv.get("$avp(hithere)"), "value")
        assertError(self.pv.sets, "$avp(hithere)", 1)
        self.pv.sets("$(avp(hithere)[*])", "1")
        assertEquals(self.pv.get("$avp(s:hithere)"), "1")
        self.pv.sets("$(avp(hithere))", "new_value")
        assertEquals(self.pv.vars["avp:hithere"]:list(), {"new_value","1"})
        assertEquals(self.pv.get("$avp(hithere)"), "new_value")
        assertEquals(self.pv.get("$(avp(hithere))"), "new_value")
    end

    function TestPVMock:test_avp_sets_all()
        self.pv.sets("$avp(s:hithere)", "value")
        assertEquals(self.pv.get("$avp(hithere)"), "value")
        assertEquals(self.pv.get("$(avp(hithere)[*])"), {"value"})
        self.pv.sets("$avp(s:hithere)", "value1")
        assertEquals(self.pv.get("$(avp(hithere)[*])"), {"value1","value"})
    end

    function TestPVMock:test_avp_seti()
        self.pv.seti("$avp(s:hithere)", 0)
        assertEquals(self.pv.get("$avp(s:hithere)"), 0)
        assertError(self.pv.seti, "$avp(s:hithere)", "1")
        self.pv.seti("$(avp(hithere))", 2)
        assertEquals(self.pv.vars["avp:hithere"]:list(), {2,0})
        assertEquals(self.pv.get("$avp(hithere)"), 2)
        assertEquals(self.pv.get("$(avp(hithere))"), 2)
    end

    function TestPVMock:test_xavp_sets()
        self.pv.sets("$xavp(g=>hithere)", "value")
        assertEquals(self.pv.get("$xavp(g=>hithere)"), "value")
        self.pv.sets("$xavp(g=>bythere)", "value_bye")
        assertEquals(self.pv.get("$xavp(g=>bythere)"), "value_bye")
    end

    function TestPVMock:test_xavp_sets_multi()
        self.pv.sets("$xavp(g=>hithere)", "value1")
        assertEquals(self.pv.get("$xavp(g=>hithere)"), "value1")
        self.pv.sets("$xavp(g[0]=>hithere)", "value0")
        assertEquals(self.pv.get("$xavp(g[0]=>hithere)"), "value0")
        assertEquals(self.pv.get("$xavp(g=>hithere[1])"), "value1")
    end

    function TestPVMock:test_xavp_sets1()
        self.pv.sets("$xavp(g=>hithere)", "value")
        assertEquals(self.pv.get("$xavp(g[0]=>hithere)"), "value")
        self.pv.sets("$xavp(g=>hithere)", "value_bye")
        assertEquals(self.pv.get("$xavp(g[0]=>hithere)"), "value_bye")
        assertEquals(self.pv.get("$xavp(g[1]=>hithere)"), "value")
    end

    function TestPVMock:test_xavp_sets1_multi()
        self.pv.sets("$xavp(g=>hithere)", "value1")
        assertEquals(self.pv.get("$xavp(g[0]=>hithere)"), "value1")
        self.pv.sets("$xavp(g[0]=>hithere)", "value0")
        assertEquals(self.pv.get("$xavp(g[0]=>hithere)"), "value0")
        assertEquals(self.pv.get("$xavp(g[0]=>hithere[1])"), "value1")
        self.pv.sets("$xavp(g=>hithere)", "value_bye")
        assertEquals(self.pv.get("$xavp(g[0]=>hithere)"), "value_bye")
        assertEquals(self.pv.get("$xavp(g[1]=>hithere)"), "value0")
    end

    function TestPVMock:test_xavp_seti()
        self.pv.seti("$xavp(t=>hithere)", 0)
        assertEquals(self.pv.get("$xavp(t[0]=>hithere)"), 0)
        assertEquals(self.pv.get("$xavp(t=>hithere)"), 0)
        assertError(self.pv.seti, "$xavp(t=>hithere)", "1")
        assertError(self.pv.seti, "$xavp(t[6]=>hithere)", "1")
    end

    function TestPVMock:test_xavp_get()
        self.pv.sets("$xavp(g=>hithere)", "value")
        assertTrue(self.pv.get, "$xavp(g)")
    end

    function TestPVMock:test_xavp_get_multi()
        self.pv.sets("$xavp(g=>hithere)", "value1")
        self.pv.sets("$xavp(g[0]=>hithere)", "value2")
        assertEquals(self.pv.get("$xavp(g[0]=>hithere[0])"), "value2")
        assertEquals(self.pv.get("$xavp(g[0]=>hithere[1])"), "value1")
    end

    function TestPVMock:test_avp_get_simple()
        self.pv.sets("$avp(s:hithere)", "value")
        assertEquals(self.pv.get("$avp(s:hithere)"), "value")
    end

    function TestPVMock:test_avp_get_simple2()
        self.pv.seti("$avp(s:hithere)", 1)
        assertEquals(self.pv.get("$avp(s:hithere)"), 1)
    end

    function TestPVMock:test_avp_get_simple3()
        self.pv.seti("$avp(s:hithere)", 1)
        assertEquals(self.pv.get("$(avp(s:hithere)[0])"), 1)
    end

    function TestPVMock:test_avp_get()
        local vals = {1,2,3}
        for i=1,#vals do
            self.pv.seti("$avp(s:hithere)", vals[i])
        end
        local l = self.pv.get("$(avp(s:hithere)[*])")
        assertTrue(type(l), 'table')
        assertEquals(#l,#vals)
        --print(table.tostring(l))
        local v = 1
        for i=#vals,1,-1 do
           assertEquals(l[i],vals[v])
           v = v + 1
        end
    end

    function TestPVMock:test_avp_get_2()
        local vals = {1,2,3}
        for i=1,#vals do
            self.pv.seti("$avp(s:hithere)", vals[i])
        end
        local l = "$(avp(s:hithere)[%d])"
        local v = 1
        for i=#vals,1,-1 do
           assertEquals(self.pv.get(string.format(l, i-1)), vals[v])
           v = v + 1
        end
    end

    function TestPVMock:test_avp_get_all()
        self.pv.sets("$avp(s:hithere)", "value")
        assertEquals(self.pv.get("$avp(hithere)"), "value")
        assertEquals(self.pv.get("$(avp(hithere)[*])"), {"value"})
        self.pv.sets("$avp(s:hithere)", "value1")
        assertEquals(self.pv.get("$(avp(hithere)[*])"), {"value1","value"})
        self.pv.sets("$(avp(s:hithere)[*])", "new_value")
        assertEquals(self.pv.get("$avp(s:hithere)"), "new_value")
        assertEquals(self.pv.get("$(avp(s:hithere)[*])"), {"new_value"})
    end

    function TestPVMock:test_hdr_get()
        self.pv.hdr.insert("From: hola\r\n")
        assertEquals(self.pv.get("$hdr(From)"), "hola")
    end

    function TestPVMock:test_pv_seti()
        self.pv.seti("$rU", 0)
        assertEquals(self.pv.get("$rU"), 0)
    end

    function TestPVMock:test_pv_sets()
        self.pv.sets("$rU", "0")
        assertEquals(self.pv.get("$rU"), "0")
    end

    function TestPVMock:test_unset_var()
        self.pv.sets("$var(hithere)", "value")
        assertEquals(self.pv.get("$var(hithere)"), "value")
        self.pv.unset("$var(hithere)")
        assertEquals(self.pv.get("$var(hithere)"), nil)
        self.pv.unset("$var(hithere)")
    end

    function TestPVMock:test_unset_avp()
        self.pv.sets("$avp(s:hithere)", "value")
        assertEquals(self.pv.get("$avp(hithere)"), "value")
        self.pv.unset("$avp(s:hithere)")
        assertEquals(self.pv.get("$avp(hithere)"), nil)
        self.pv.unset("$avp(s:hithere)")
        assertEquals(self.pv.get("$avp(s:hithere)"), nil)
    end

    function TestPVMock:test_unset_avp_2()
        self.pv.sets("$avp(s:hithere)", "value")
        self.pv.sets("$avp(s:hithere)", "other")
        assertEquals(self.pv.get("$avp(hithere)"), "other")
        self.pv.unset("$avp(s:hithere)")
        assertEquals(self.pv.get("$avp(hithere)"), "value")
        self.pv.unset("$(avp(s:hithere)[*])")
        assertEquals(self.pv.get("$avp(s:hithere)"), nil)
    end

    function TestPVMock:test_unset_avp_3()
        self.pv.sets("$avp(s:hithere)", "value")
        self.pv.sets("$avp(s:hithere)", "other")
        assertEquals(self.pv.get("$(avp(hithere)[0])"), "other")
        assertEquals(self.pv.get("$(avp(hithere)[1])"), "value")
        -- same behavior than kamailio!!
        self.pv.unset("$(avp(s:hithere)[1])")
        assertEquals(self.pv.get("$(avp(hithere)[*])"), {"value"})
    end

    function TestPVMock:test_unset_xavp()
        self.pv.sets("$xavp(g=>t)", "value")
        assertEquals(self.pv.get("$xavp(g[0]=>t)"), "value")
        self.pv.sets("$xavp(g=>t)", "value1")
        assertEquals(self.pv.get("$xavp(g[0]=>t)"), "value1")
        assertEquals(self.pv.get("$xavp(g[1]=>t)"), "value")
        --
        self.pv.unset("$xavp(g[0]=>t)")
        assertEquals(self.pv.get("$xavp(g[0]=>t)"), nil)
        assertEquals(self.pv.get("$xavp(g[1]=>t)"), "value")
        --
        self.pv.unset("$xavp(g[1])")
        assertFalse(self.pv.get("$xavp(g[1])"))
        self.pv.unset("$xavp(g)")
        assertEquals(self.pv.get("$xavp(g)"), nil)
    end

    function TestPVMock:test_unset_xavp1()
        self.pv.sets("$xavp(g=>t)", "value")
        assertEquals(self.pv.get("$xavp(g[0]=>t)"), "value")
        self.pv.sets("$xavp(g=>t)", "value1")
        assertEquals(self.pv.get("$xavp(g[0]=>t)"), "value1")
        assertEquals(self.pv.get("$xavp(g[1]=>t)"), "value")
        self.pv.sets("$xavp(g[1]=>z)", "value_z")
        assertEquals(self.pv.get("$xavp(g[1]=>z)"), "value_z")
        --
        self.pv.unset("$xavp(g[0])")
        assertEquals(self.pv.get("$xavp(g[0]=>t)"), nil)
        assertEquals(self.pv.get("$xavp(g[1]=>t)"), "value")
        assertEquals(self.pv.get("$xavp(g[1]=>z)"), "value_z")
        assertFalse(self.pv.get("$xavp(g[0])"))
        --
        self.pv.unset("$xavp(g[1])")
        assertFalse(self.pv.get("$xavp(g[1])"))
        self.pv.unset("$xavp(g)")
        assertEquals(self.pv.get("$xavp(g)"), nil)
    end

    function TestPVMock:test_is_null()
        assertTrue(self.pv.is_null("$avp(s:hithere)"))
        self.pv.unset("$avp(s:hithere)")
        assertTrue(self.pv.is_null("$avp(s:hithere)"))
        self.pv.sets("$avp(s:hithere)", "value")
        assertFalse(self.pv.is_null("$avp(s:hithere)"))
        self.pv.sets("$avp(s:hithere)", "value")
        assertFalse(self.pv.is_null("$avp(s:hithere)"))
    end

    function TestPVMock:test_avp_set_clean()
        self.pv.seti("$(avp(s:hithere)[*])", 0)
        assertEquals(self.pv.get("$avp(s:hithere)"), 0)
        assertEquals(self.pv.get("$(avp(s:hithere)[*])"), {0})
        self.pv.seti("$(avp(s:hithere)[*])", 1)
        assertEquals(self.pv.get("$avp(s:hithere)"), 1)
        assertEquals(self.pv.get("$(avp(s:hithere)[*])"), {1})
    end
