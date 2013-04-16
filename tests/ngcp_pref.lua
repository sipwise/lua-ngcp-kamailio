require('luaunit')
require 'ngcp.pref'

TestNGCPPrefs = {} --class

	function TestNGCPPrefs:tearDown()
		sr.pv.vars = {}
	end

    function TestNGCPPrefs:test_set_avp_empty()
        sr.pv.sets("$avp(s:loquesea)", "one")
        assertEquals(sr.pv.get("$avp(s:loquesea)"),"one")
        NGCPPrefs.set_avp("loquesea")
        assertEquals(sr.pv.get("$avp(s:loquesea)"), nil)
    end

    function TestNGCPPrefs:test_set_avp_val()
        sr.pv.sets("$avp(s:loquesea)", "one")
        sr.pv.sets("$xavp(callee_peer_prefs=>hola)", "two")
        assertEquals(sr.pv.get("$avp(s:loquesea)"),"one")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs[0]=>hola)"),"two")
        NGCPPrefs.set_avp("loquesea", "callee_peer_prefs=>hola")
        assertEquals(sr.pv.get("$avp(s:loquesea)"), "two")
    end
-- class TestNGCP
--EOF