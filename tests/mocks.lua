#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
--require 'utils'

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
        self.sr = nil
    end

    function TestSRMock:test_ini()
        assertTrue(self.sr.pv)
    end

    function TestSRMock:test_sets()
        self.sr.pv.unset("$avp('hithere')")
        self.sr.pv.sets("$avp('hithere')", "value")
        assertEquals(self.sr.pv.vars["$avp('hithere')"], "value")
        assertError(self.sr.pv.sets, "$avp('hithere')", 1)
    end

    function TestSRMock:test_seti()
        self.sr.pv.unset("$avp('hithere')")
        self.sr.pv.seti("$avp('hithere')", 0)
        assertEquals(self.sr.pv.vars["$avp('hithere')"], 0)
        assertError(self.sr.pv.seti, "$avp('hithere')", "1")
    end

    function TestSRMock:test_get()
        local vals = {1,2,3}
        self.sr.pv.unset("$avp('hithere')")
        self.sr.pv.sets("$avp('hithere')", "value")
        assertEquals(self.sr.pv.get("$avp('hithere')"), "value")
        self.sr.pv.unset("$avp('hithere')")
        self.sr.pv.seti("$avp('hithere')", 1)
        assertEquals(self.sr.pv.get("$avp('hithere')"), 1)
        for i=1,#vals do
            self.sr.pv.seti("$avp('hithere')", vals[i])
        end
        local l = self.sr.pv.get("$avp('hithere')")
        assertTrue(type(l), 'table')
        --print(table.tostring(l))
        v = 1
        for i=#vals,1,-1 do
           assertEquals(l[i],vals[v])
           v = v + 1 
        end        
    end

    function TestSRMock:test_unset()
        self.sr.pv.sets("$avp('hithere')", "value")
        self.sr.pv.unset("$avp('hithere')")
        assertEquals(self.sr.pv.vars["$avp('hithere')"], nil)
        self.sr.pv.unset("$avp('hithere')")
        assertEquals(self.sr.pv.vars["$avp('hithere')"], nil)
    end

    function TestSRMock:test_is_null()
        self.sr.pv.unset("$avp('hithere')")
        assertTrue(self.sr.pv.is_null("$avp('hithere')"))
        self.sr.pv.sets("$avp('hithere')", "value")
        assertFalse(self.sr.pv.is_null("$avp('hithere')"))
        self.sr.pv.sets("$avp('hithere')", "value")
        assertFalse(self.sr.pv.is_null("$avp('hithere')"))
    end
---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF