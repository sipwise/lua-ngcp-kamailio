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
        assertItemsEquals(self.avp(), "1")
        assertItemsEquals(self.avp:all(),{"1","value"})
    end

    function TestNGCPAvp:test_avp_set()
        local vals = {1,2,3}
        local okvals = {3,2,1}
        local i
        for i=1,#vals do
            self.avp(vals[i])
            assertEquals(self.avp(),vals[i])
        end
        assertEquals(self.avp:all(), okvals)
    end

    function TestNGCPAvp:test_avp_set2()
        local vals = {1,2,"3"}
        local okvals = {"3",2,1}
        local i
        for i=1,#vals do
            self.avp(vals[i])
            assertEquals(self.avp(),vals[i])
        end
        assertEquals(self.avp:all(), okvals)
    end

    function TestNGCPAvp:test_clean()
        self.avp(1)
        self.avp:clean()
        assertFalse(self.avp())
    end

    function TestNGCPAvp:test_log()
        self.avp:log()
    end
-- class TestNGCPAvp
--EOF