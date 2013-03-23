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
    
    function TestSRMock:test_ini()
        assertTrue(self.sr.pv)
        self.sr.pv.sets("$avp('hithere')", "value")
    end

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF