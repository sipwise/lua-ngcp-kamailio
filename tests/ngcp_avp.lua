#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
require 'ngcp.avp'

sr = srMock:new()

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
        assertItemsEquals(self.avp(),{"1","value"})
    end

    function TestNGCPAvp:test_avp_set()
        local vals = {1,2,3}
        for i=1,#vals do
            self.avp(vals[i])
        end
        local l = self.avp()
        assertTrue(type(l), 'table')
        --print(table.tostring(l))
        v = 1
        for i=#vals,1,-1 do
           assertEquals(l[i],vals[v])
           v = v + 1 
        end        
    end

    function TestNGCPAvp:test_avp_set2()
        local vals = {1,2,"3"}
        for i=1,#vals do
            self.avp(vals[i])
        end
        local l = self.avp()
        assertTrue(type(l), 'table')
        --print(table.tostring(l))
        v = 1
        for i=#vals,1,-1 do
           assertEquals(l[i],vals[v])
           v = v + 1 
        end        
    end

    function TestNGCPAvp:test_clean()
        self.avp(1)
        self.avp:clean()
        assertFalse(self.avp())
    end
-- class TestNGCPAvp

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF