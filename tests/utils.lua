#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
require 'utils'

TestUtils = {} --class

    function TestUtils:setUp()
        self.simple_hash = {
            one = 1, two = 2, three = 3
        }
        self.simple_list = {
            1, 2, 3
        }
        self.complex_hash = {
            cone = self.simple_list,
            ctwo = self.simple_hash
        }
    end

    function TestUtils:test_table_deepcopy()
        assertNotEquals(table.deepcopy(self.simple_hash), self.simple_hash)
        -- if the parameter is not a table... it has te be the same
        assertEquals(table.deepcopy("hola"), "hola")
    end

    function TestUtils:test_table_contains()
        assertTrue(table.contains(self.simple_hash, 3))
        assertFalse(table.contains(self.simple_hash, 4))
        assertFalse(table.contains(nil))
        assertError(table.contains, "hola",1)
    end

    function TestUtils:test_table_tostring()
        assertError(table.tostring,nil)
        assertEquals(table.tostring(self.simple_list), "{1,2,3}")
        assertTrue(table.tostring(self.simple_hash))
        --print(table.tostring(self.simple_hash) .. "\n")
        assertTrue(table.tostring(self.complex_hash))
        --print(table.tostring(self.complex_hash))
    end

    function TestUtils:test_implode()
        assertEquals(implode(',', self.simple_list, "'"), "'1','2','3'")
        assertError(implode, nil, self.simple_list, "'")
        assertError(implode, ',', nil, "'")
    end

    function TestUtils:test_explode()
        assertItemsEquals(explode(',',"1,2,3"), {'1','2','3'})
    end
-- class TestUtils

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF