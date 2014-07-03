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
require 'mocks.sr'

TestMock = {}
    function TestMock:testMock()
        mc = lemock.controller()
        m = mc:mock()
        m.pv = mc:mock()
        m.titi( 42 )
        m.toto( 33, "abc", { 21} )
    end

TestHDRMock = {}
    function TestHDRMock:setUp()
        self.hdr = hdrMock:new()
    end

    function TestHDRMock:tearDown()
        self.hdr.headers = {}
        self.hdr.headers_reply = {}
    end

    function TestHDRMock:test_is_header()
        assertTrue(self.hdr._is_header("From: hi@there.com\r\n"))
        assertFalse(self.hdr._is_header("From hi@there.com\r\n"))
        assertFalse(self.hdr._is_header("From: hi@there.com\r"))
        assertFalse(self.hdr._is_header("From : hi@there.com\n"))
        assertFalse(self.hdr._is_header("From : hi@there.com\n\r"))
        assertTrue(self.hdr._is_header("From: hi@there.com:8080\r\n"))
    end

    function TestHDRMock:test_append()
        assertFalse(self.hdr._get_header("From"))
        self.hdr.append("From: hi@there.com\r\n")
        assertEquals(self.hdr.headers, {"From: hi@there.com\r\n"})
        self.hdr.append("To: bye@there.com\r\n")
        assertEquals(self.hdr.headers, {"From: hi@there.com\r\n", "To: bye@there.com\r\n"})
    end

    function TestHDRMock:test_insert()
        assertFalse(self.hdr._get_header("From"))
        self.hdr.insert("From: hi@there.com\r\n")
        assertEquals(self.hdr.headers, {"From: hi@there.com\r\n"})
        self.hdr.insert("To: bye@there.com\r\n")
        assertEquals(self.hdr.headers, {"To: bye@there.com\r\n", "From: hi@there.com\r\n"})
    end

    function TestHDRMock:test_get_header()
        self:test_append()
        assertEquals(self.hdr._get_header("From"), "hi@there.com")
    end
-- end class

TestSRMock = {}
    function TestSRMock:setUp()
        self.sr = srMock:new()
    end

    function TestSRMock:tearDown()
        self.sr.pv.vars = {}
    end

    function TestSRMock:test_ini()
        assertTrue(self.sr.pv)
    end

    function TestSRMock:test_clean_id()
        assertEquals(self.sr.pv._clean_id('s:u25'), 'u25')
        assertEquals(self.sr.pv._clean_id('i:u25'), 'u25')
        assertEquals(self.sr.pv._clean_id('u25'), 'u25')
    end

    function TestSRMock:test_is_pv_simple()
        local result
        result = self.sr.pv._is_pv("$si")
        assertTrue(result)
        assertEquals(result.type, 'pv')
        assertEquals(result.id, 'si')
        assertEquals(result.key, nil)
        assertEquals(result.mode, 'ro')
        assertFalse(result.clean)
    end

    function TestSRMock:test_is_pv_rw()
        local result
        result = self.sr.pv._is_pv("$rU")
        assertTrue(result)
        assertEquals(result.type, 'pv')
        assertEquals(result.id, 'rU')
        assertEquals(result.key, nil)
        assertEquals(result.mode, 'rw')
        assertFalse(result.clean)
    end

    function TestSRMock:test_is_hdr_simple()
        local result
        result = self.sr.pv._is_hdr("$hdr(id)")
        assertTrue(result)
        assertEquals(result.type, 'hdr')
        assertEquals(result.id, 'id')
        assertEquals(result.key, nil)
        assertFalse(result.clean)
    end

    function TestSRMock:test_is_hdr_complex()
        local result
        result = self.sr.pv._is_hdr("$hdr($si)")
        assertTrue(result)
        assertEquals(result.type, 'hdr')
        assertEquals(result.id, '$si')
        assertEquals(result.key, nil)
        assertFalse(result.clean)
    end

    function TestSRMock:test_is_xavp_simple()
        local result
        result = self.sr.pv._is_xavp("$xavp(id=>key)")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id')
        assertEquals(result.key, 'key')
        assertIsNil(result.indx)
        assertIsNil(result.kindx)
        assertFalse(result.clean)
    end

    function TestSRMock:test_is_xavp_complex()
        local result
        result = self.sr.pv._is_xavp("$xavp(id1[8]=>key3g2)")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id1')
        assertEquals(result.key, 'key3g2')
        assertEquals(result.indx, 8)
        assertIsNil(result.kindx)
        assertFalse(result.clean)
        result = self.sr.pv._is_xavp("$xavp(id2g1f[9]=>keygg33_f)")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id2g1f')
        assertEquals(result.key, 'keygg33_f')
        assertEquals(result.indx, 9)
        assertIsNil(result.kindx)
        assertFalse(result.clean)
    end

    function TestSRMock:test_is_xavp_complex_indx()
        local result
        result = self.sr.pv._is_xavp("$xavp(id1[8]=>key3g2)")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id1')
        assertEquals(result.key, 'key3g2')
        assertEquals(result.indx, 8)
        assertIsNil(result.kindx)
        assertFalse(result.clean)
        result = self.sr.pv._is_xavp("$xavp(id2g1f[9]=>keygg33_f[2])")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id2g1f')
        assertEquals(result.key, 'keygg33_f')
        assertEquals(result.indx, 9)
        assertEquals(result.kindx, 2)
        assertFalse(result.clean)
    end

    function TestSRMock:test_is_xavp_complex_indx2()
        result = self.sr.pv._is_xavp("$xavp(gogo[9]=>gogo[*])")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'gogo')
        assertEquals(result.key, 'gogo')
        assertEquals(result.indx, 9)
        assertFalse(result.kindx)
        assertTrue(result.clean)
    end

    function TestSRMock:test_is_xavp_simple_nokey()
        local result
        result = self.sr.pv._is_xavp("$xavp(id1[8])")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id1')
        assertFalse(result.key)
        assertEquals(result.indx, 8)
        assertFalse(result.clean)
    end

    function TestSRMock:test_is_xavp_simple_nokey_noindx()
        local result
        result = self.sr.pv._is_xavp("$xavp(id1)")
        assertTrue(result)
        assertEquals(result.type, 'xavp')
        assertEquals(result.id, 'id1')
        assertFalse(result.key)
        assertIsNil(result.indx)
        assertIsNil(result.kindx)
        assertFalse(result.clean)
    end

    function TestSRMock:test_is_avp_simple()
        local result
        result = self.sr.pv._is_avp("$avp(id2_f)")
        assertTrue(result)
        assertEquals(result.type, 'avp')
        --print(table.tostring(result))
        assertEquals(result.id, 'id2_f')
        assertFalse(result.clean)
    end

    function TestSRMock:test_is_avp_simple1()
        local result
        result = self.sr.pv._is_avp("$(avp(s:id))")
        assertTrue(result)
        assertEquals(result.type, 'avp')
        --print(table.tostring(result))
        assertEquals(result.id, 'id')
        assertFalse(result.clean)
    end

    function TestSRMock:test_is_avp_simple2()
        local result
        result = self.sr.pv._is_avp("$(avp(id))")
        assertTrue(result)
        assertEquals(result.type, 'avp')
        --print(table.tostring(result))
        assertEquals(result.id, 'id')
        assertFalse(result.clean)
    end

    function TestSRMock:test_is_avp_simple3()
        local result
        result = self.sr.pv._is_avp("$(avp(s:id)[*])")
        assertTrue(result)
        assertEquals(result.type, 'avp')
        assertEquals(result.id, 'id')
        --print(table.tostring(result))
        assertTrue(result.clean)
    end

    function TestSRMock:test_is_var_simple()
        local result
        result = self.sr.pv._is_var("$var(id)")
        assertTrue(result)
        assertEquals(result.type, 'var')
        assertEquals(result.id, 'id')
        --print(table.tostring(result))
        assertFalse(result.clean)
    end

    function TestSRMock:test_var_sets()
        self.sr.pv.sets("$var(hithere)", "value")
        assertEquals(self.sr.pv.get("$var(hithere)"), "value")
        assertError(self.sr.pv.sets, "$var(hithere)", 1)
        assertError(self.sr.pv.sets, "$var(s:hithere)", "1")
        assertError(self.sr.pv.sets, "$(var(hithere)[*])", "1")
        assertError(self.sr.pv.sets, "$(var(s:hithere))", "1")
        self.sr.pv.sets("$(var(hithere))", "new_value")
        assertEquals(self.sr.pv.get("$var(hithere)"), "new_value")
        assertEquals(self.sr.pv.vars["var:hithere"], "new_value")
    end

    function TestSRMock:test_var_seti()
        self.sr.pv.seti("$var(hithere)", 0)
        assertEquals(self.sr.pv.get("$var(hithere)"), 0)
        assertError(self.sr.pv.seti, "$var(hithere)", "1")
        assertError(self.sr.pv.sets, "$var(s:hithere)", 1)
        assertError(self.sr.pv.sets, "$(var(hithere)[*])", 1)
        assertError(self.sr.pv.sets, "$(var(s:hithere))", 1)
        assertEquals(self.sr.pv.get("$var(hithere)"), 0)
        self.sr.pv.seti("$var(hithere)", 1)
        assertEquals(self.sr.pv.get("$var(hithere)"), 1)
        assertEquals(self.sr.pv.vars["var:hithere"], 1)
    end

    function TestSRMock:test_avp_sets()
        self.sr.pv.sets("$avp(s:hithere)", "value")
        assertEquals(self.sr.pv.get("$avp(hithere)"), "value")
        assertError(self.sr.pv.sets, "$avp(hithere)", 1)
        self.sr.pv.sets("$(avp(hithere)[*])", "1")
        assertEquals(self.sr.pv.get("$avp(s:hithere)"), "1")
        self.sr.pv.sets("$(avp(hithere))", "new_value")
        assertEquals(self.sr.pv.vars["avp:hithere"]:list(), {"new_value","1"})
        assertEquals(self.sr.pv.get("$avp(hithere)"), "new_value")
        assertEquals(self.sr.pv.get("$(avp(hithere))"), "new_value")
    end

    function TestSRMock:test_avp_sets_all()
        self.sr.pv.sets("$avp(s:hithere)", "value")
        assertEquals(self.sr.pv.get("$avp(hithere)"), "value")
        assertEquals(self.sr.pv.get("$(avp(hithere)[*])"), {"value"})
        self.sr.pv.sets("$avp(s:hithere)", "value1")
        assertEquals(self.sr.pv.get("$(avp(hithere)[*])"), {"value1","value"})
    end

    function TestSRMock:test_avp_seti()
        self.sr.pv.seti("$avp(s:hithere)", 0)
        assertEquals(self.sr.pv.get("$avp(s:hithere)"), 0)
        assertError(self.sr.pv.seti, "$avp(s:hithere)", "1")
        self.sr.pv.seti("$(avp(hithere))", 2)
        assertEquals(self.sr.pv.vars["avp:hithere"]:list(), {2,0})
        assertEquals(self.sr.pv.get("$avp(hithere)"), 2)
        assertEquals(self.sr.pv.get("$(avp(hithere))"), 2)
    end

    function TestSRMock:test_xavp_sets()
        self.sr.pv.sets("$xavp(g=>hithere)", "value")
        assertEquals(self.sr.pv.get("$xavp(g=>hithere)"), "value")
        self.sr.pv.sets("$xavp(g=>bythere)", "value_bye")
        assertEquals(self.sr.pv.get("$xavp(g=>bythere)"), "value_bye")
    end

    function TestSRMock:test_xavp_sets_multi()
        self.sr.pv.sets("$xavp(g=>hithere)", "value1")
        assertEquals(self.sr.pv.get("$xavp(g=>hithere)"), "value1")
        self.sr.pv.sets("$xavp(g[0]=>hithere)", "value0")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>hithere)"), "value0")
        assertEquals(self.sr.pv.get("$xavp(g=>hithere[1])"), "value1")
    end

    function TestSRMock:test_xavp_sets1()
        self.sr.pv.sets("$xavp(g=>hithere)", "value")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>hithere)"), "value")
        self.sr.pv.sets("$xavp(g=>hithere)", "value_bye")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>hithere)"), "value_bye")
        assertEquals(self.sr.pv.get("$xavp(g[1]=>hithere)"), "value")
    end

    function TestSRMock:test_xavp_sets1_multi()
        self.sr.pv.sets("$xavp(g=>hithere)", "value1")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>hithere)"), "value1")
        self.sr.pv.sets("$xavp(g[0]=>hithere)", "value0")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>hithere)"), "value0")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>hithere[1])"), "value1")
        self.sr.pv.sets("$xavp(g=>hithere)", "value_bye")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>hithere)"), "value_bye")
        assertEquals(self.sr.pv.get("$xavp(g[1]=>hithere)"), "value0")
    end

    function TestSRMock:test_xavp_seti()
        self.sr.pv.seti("$xavp(t=>hithere)", 0)
        assertEquals(self.sr.pv.get("$xavp(t[0]=>hithere)"), 0)
        assertEquals(self.sr.pv.get("$xavp(t=>hithere)"), 0)
        assertError(self.sr.pv.seti, "$xavp(t=>hithere)", "1")
        assertError(self.sr.pv.seti, "$xavp(t[6]=>hithere)", "1")
    end

    function TestSRMock:test_xavp_get()
        self.sr.pv.sets("$xavp(g=>hithere)", "value")
        assertTrue(self.sr.pv.get, "$xavp(g)")
    end

    function TestSRMock:test_xavp_get_multi()
        self.sr.pv.sets("$xavp(g=>hithere)", "value1")
        self.sr.pv.sets("$xavp(g[0]=>hithere)", "value2")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>hithere[0])"), "value2")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>hithere[1])"), "value1")
    end

    function TestSRMock:test_avp_get_simple()
        self.sr.pv.sets("$avp(s:hithere)", "value")
        assertEquals(self.sr.pv.get("$avp(s:hithere)"), "value")
    end

    function TestSRMock:test_avp_get_simple2()
        self.sr.pv.seti("$avp(s:hithere)", 1)
        assertEquals(self.sr.pv.get("$avp(s:hithere)"), 1)
    end

    function TestSRMock:test_avp_get()
        local vals = {1,2,3}
        for i=1,#vals do
            self.sr.pv.seti("$avp(s:hithere)", vals[i])
        end
        local l = self.sr.pv.get("$(avp(s:hithere)[*])")
        assertTrue(type(l), 'table')
        assertEquals(#l,#vals)
        --print(table.tostring(l))
        v = 1
        for i=#vals,1,-1 do
           assertEquals(l[i],vals[v])
           v = v + 1
        end
    end

    function TestSRMock:test_avp_get_all()
        self.sr.pv.sets("$avp(s:hithere)", "value")
        assertEquals(self.sr.pv.get("$avp(hithere)"), "value")
        assertEquals(self.sr.pv.get("$(avp(hithere)[*])"), {"value"})
        self.sr.pv.sets("$avp(s:hithere)", "value1")
        assertEquals(self.sr.pv.get("$(avp(hithere)[*])"), {"value1","value"})
        self.sr.pv.sets("$(avp(s:hithere)[*])", "new_value")
        assertEquals(self.sr.pv.get("$avp(s:hithere)"), "new_value")
        assertEquals(self.sr.pv.get("$(avp(s:hithere)[*])"), {"new_value"})
    end

    function TestSRMock:test_hdr_get()
        self.sr.hdr.insert("From: hola\r\n")
        assertEquals(self.sr.hdr.headers, {"From: hola\r\n"})
        assertEquals(self.sr.pv.get("$hdr(From)"), "hola")
    end

    function TestSRMock:test_pv_seti()
        self.sr.pv.seti("$rU", 0)
        assertEquals(self.sr.pv.get("$rU"), 0)
    end

    function TestSRMock:test_pv_sets()
        self.sr.pv.sets("$rU", "0")
        assertEquals(self.sr.pv.get("$rU"), "0")
    end

    function TestSRMock:test_unset_var()
        self.sr.pv.sets("$var(hithere)", "value")
        assertEquals(self.sr.pv.get("$var(hithere)"), "value")
        self.sr.pv.unset("$var(hithere)")
        assertEquals(self.sr.pv.get("$var(hithere)"), nil)
        self.sr.pv.unset("$var(hithere)")
    end

    function TestSRMock:test_unset_avp()
        self.sr.pv.sets("$avp(s:hithere)", "value")
        assertEquals(self.sr.pv.get("$avp(hithere)"), "value")
        self.sr.pv.unset("$avp(s:hithere)")
        assertEquals(self.sr.pv.get("$avp(hithere)"), nil)
        self.sr.pv.unset("$avp(s:hithere)")
        assertEquals(self.sr.pv.get("$avp(s:hithere)"), nil)
    end

    function TestSRMock:test_unset_xavp()
        self.sr.pv.sets("$xavp(g=>t)", "value")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>t)"), "value")
        self.sr.pv.sets("$xavp(g=>t)", "value1")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>t)"), "value1")
        assertEquals(self.sr.pv.get("$xavp(g[1]=>t)"), "value")
        --
        self.sr.pv.unset("$xavp(g[0]=>t)")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>t)"), nil)
        assertEquals(self.sr.pv.get("$xavp(g[1]=>t)"), "value")
        --
        self.sr.pv.unset("$xavp(g[1])")
        assertFalse(self.sr.pv.get("$xavp(g[1])"))
        self.sr.pv.unset("$xavp(g)")
        assertEquals(self.sr.pv.get("$xavp(g)"), nil)
    end

    function TestSRMock:test_unset_xavp1()
        self.sr.pv.sets("$xavp(g=>t)", "value")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>t)"), "value")
        self.sr.pv.sets("$xavp(g=>t)", "value1")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>t)"), "value1")
        assertEquals(self.sr.pv.get("$xavp(g[1]=>t)"), "value")
        self.sr.pv.sets("$xavp(g[1]=>z)", "value_z")
        assertEquals(self.sr.pv.get("$xavp(g[1]=>z)"), "value_z")
        --
        self.sr.pv.unset("$xavp(g[0])")
        assertEquals(self.sr.pv.get("$xavp(g[0]=>t)"), nil)
        assertEquals(self.sr.pv.get("$xavp(g[1]=>t)"), "value")
        assertEquals(self.sr.pv.get("$xavp(g[1]=>z)"), "value_z")
        assertFalse(self.sr.pv.get("$xavp(g[0])"))
        --
        self.sr.pv.unset("$xavp(g[1])")
        assertFalse(self.sr.pv.get("$xavp(g[1])"))
        self.sr.pv.unset("$xavp(g)")
        assertEquals(self.sr.pv.get("$xavp(g)"), nil)
    end

    function TestSRMock:test_is_null()
        assertTrue(self.sr.pv.is_null("$avp(s:hithere)"))
        self.sr.pv.unset("$avp(s:hithere)")
        assertTrue(self.sr.pv.is_null("$avp(s:hithere)"))
        self.sr.pv.sets("$avp(s:hithere)", "value")
        assertFalse(self.sr.pv.is_null("$avp(s:hithere)"))
        self.sr.pv.sets("$avp(s:hithere)", "value")
        assertFalse(self.sr.pv.is_null("$avp(s:hithere)"))
    end

    function TestSRMock:test_log()
        assertTrue(self.sr.log)
        self.sr.log("dbg", "Hi dude!")
        assertError(self.sr.log, "debug", "Hi dude!")
    end

    function TestSRMock:test_avp_set_clean()
        self.sr.pv.seti("$(avp(s:hithere)[*])", 0)
        assertEquals(self.sr.pv.get("$avp(s:hithere)"), 0)
        assertEquals(self.sr.pv.get("$(avp(s:hithere)[*])"), {0})
        self.sr.pv.seti("$(avp(s:hithere)[*])", 1)
        assertEquals(self.sr.pv.get("$avp(s:hithere)"), 1)
        assertEquals(self.sr.pv.get("$(avp(s:hithere)[*])"), {1})
    end
-- end class

TestXAVPMock = {}
    function TestXAVPMock:setUp()
        self.pv = pvMock:new()
        self.xavp = xavpMock:new(self.pv)

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
        assertTrue(l)
        assertItemsEquals(l, {"uno", "dos", "tres"})
    end

    function TestXAVPMock:test_get_keys_1()
        local l = self.xavp.get_keys("test", 1)
        assertTrue(l)
        assertItemsEquals(l, {"uno", "dos"})
    end

    function TestXAVPMock:test_get_simple()
        local l = self.xavp.get("test", 0, 1)
        assertTrue(l)
        assertItemsEquals(l, {uno=1, dos="dos", tres=3})
    end

    function TestXAVPMock:test_get_simple_1()
        local l = self.xavp.get("test", 1, 1)
        assertTrue(l)
        assertItemsEquals(l, {uno="uno", dos=2})
    end

    function TestXAVPMock:test_get()
        local l = self.xavp.get("test", 0, 0)
        assertTrue(l)
        assertItemsEquals(l, {uno={1,3}, dos={"dos"}, tres={3}})
    end

    function TestXAVPMock:test_get_1()
        local l = self.xavp.get("test", 1, 0)
        assertTrue(l)
        assertItemsEquals(l, {uno={"uno"}, dos={2,4}})
    end
--EOF