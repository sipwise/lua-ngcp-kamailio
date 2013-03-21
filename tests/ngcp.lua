#!/usr/bin/env lua5.1
require('luaunit')
require 'ngcp'

TestNGCP = {} --class

    function TestNGCP:setUp()
        self.ngcp = NGCP()
    end

    function TestNGCP:test_config()
        assertEquals( self.ngcp.preference.domain.name , 'name' )
        assertEquals( self.ngcp.preference.peer.name , 'peer' )
    end
-- class TestNGCP

---- Control test output:
lu = LuaUnit
-- lu:setOutputType( "NIL" )
lu:setOutputType( "TAP" )
lu:setVerbosity( 0 )
lu:run()
--EOF