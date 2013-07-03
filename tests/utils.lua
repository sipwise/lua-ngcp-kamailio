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
require 'ngcp.utils'

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
        assertNotIs(table.deepcopy(self.simple_hash), self.simple_hash)
        -- if the parameter is not a table... it has te be the same
        assertIs(table.deepcopy("hola"), "hola")
    end

    function TestUtils:test_table_contains()
        assertTrue(table.contains(self.simple_hash, 3))
        assertFalse(table.contains(self.simple_hash, 4))
        assertFalse(table.contains(nil))
        assertError(table.contains, "hola",1)
    end

    function TestUtils:test_table_add()
        assertEquals(self.simple_list, {1,2,3})
        table.add(self.simple_list, 1)
        assertEquals(self.simple_list, {1,2,3})
        table.add(self.simple_list, 5)
        assertEquals(self.simple_list, {1,2,3,5})
        table.add(self.simple_list, 4)
        assertEquals(self.simple_list, {1,2,3,5,4})
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
        assertItemsEquals(explode('=>',"1=>2=>3"), {'1','2','3'})
    end

    function TestUtils:test_starts()
        assertError(string.stats, nil, "g")
        assertTrue(string.starts("goga", "g"))
        assertTrue(string.starts("goga", "go"))
        assertTrue(string.starts("goga", "gog"))
        assertTrue(string.starts("goga", "goga"))
        assertFalse(string.starts("goga", "a"))
        assertError(string.starts, "goga", nil)
        assertTrue(string.starts("$goga", "$"))
        assertTrue(string.starts("(goga)", "("))
    end

    function TestUtils:test_ends()
        assertError(string.ends, nil, "g")
        assertTrue(string.ends("goga", "a"))
        assertTrue(string.ends("goga", "ga"))
        assertTrue(string.ends("goga", "oga"))
        assertTrue(string.ends("goga", "goga"))
        assertFalse(string.ends("goga", "f"))
        assertError(string.ends, "goga", nil)
    end
-- class TestUtils

TestStack = {}
    function TestStack:test()
        s = Stack:new()
        assertEquals(#s._et,0)
        assertEquals(s:pop(), nil)
        s:push(1)
        assertEquals(#s._et,1)
        assertEquals(s:pop(),1)
        assertEquals(s:size(),0)
        s:push(1)
        s:push({1,2,3})
        assertEquals(s:size(),2)
        local l = s:list()
        assertItemsEquals(l[1],{1,2,3})
        assertEquals(l[2],1)
    end

    function TestStack:test_tostring()
        s = Stack:new()
        s:push(1)
        assertEquals(tostring(s), "{1}")
        s:push(2)
        assertEquals(tostring(s), "{2,1}")
    end
-- class TestStack
--EOF