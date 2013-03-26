#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'

TestMock = {}
    function TestMock:testMock()
        m = mc:mock()
        m.pv = mc:mock()
        m.titi( 42 )
        m.toto( 33, "abc", { 21} )
    end

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

    function TestSRMock:test_sets()
        self.sr.pv.sets("$avp(s:hithere)", "value")
        assertEquals(self.sr.pv.vars["$avp(s:hithere)"], "value")
        assertError(self.sr.pv.sets, "$avp(s:hithere)", 1)
    end

    function TestSRMock:test_seti()
        self.sr.pv.seti("$avp(s:hithere)", 0)
        assertEquals(self.sr.pv.vars["$avp(s:hithere)"], 0)
        assertError(self.sr.pv.seti, "$avp(s:hithere)", "1")
    end

    function TestSRMock:test_get()
        local vals = {1,2,3}
        self.sr.pv.sets("$avp(s:hithere)", "value")
        assertEquals(self.sr.pv.get("$avp(s:hithere)"), "value")
        self.sr.pv.unset("$avp(s:hithere)")
        self.sr.pv.seti("$avp(s:hithere)", 1)
        assertEquals(self.sr.pv.get("$avp(s:hithere)"), 1)
        for i=1,#vals do
            self.sr.pv.seti("$avp(s:hithere)", vals[i])
        end
        local l = self.sr.pv.get("$avp(s:hithere)")
        assertTrue(type(l), 'table')
        --print(table.tostring(l))
        v = 1
        for i=#vals,1,-1 do
           assertEquals(l[i],vals[v])
           v = v + 1 
        end        
    end

    function TestSRMock:test_unset()
        self.sr.pv.sets("$avp(s:hithere)", "value")
        self.sr.pv.unset("$avp(s:hithere)")
        assertEquals(self.sr.pv.vars["$avp(s:hithere)"], nil)
        self.sr.pv.unset("$avp(s:hithere)")
        assertEquals(self.sr.pv.vars["$avp(s:hithere)"], nil)

        self.sr.pv.sets("$xavp(g=>t)", "value")
        assertEquals(self.sr.pv.vars["$xavp(g[0]=>t)"], value)
        assertEquals(self.sr.pv.vars["$xavp(g=>t)"], nil)

        self.sr.pv.sets("$xavp(g[0]=>v)", "value")
        self.sr.pv.unset("$xavp(g[1])")
        assertEquals(self.sr.pv.vars["$xavp(g[1])"], nil)
        assertEquals(self.sr.pv.vars["$xavp(g[0]=>t)"], "value")
        assertEquals(self.sr.pv.vars["$xavp(g[0]=>v)"], "value")

        self.sr.pv.sets("$xavp(g[1]=>v)", "value")
        self.sr.pv.unset("$xavp(g[1])")
        assertEquals(self.sr.pv.vars["$xavp(g[1]=>v)"], nil)
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
---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF