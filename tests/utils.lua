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

    function TestUtils:test_table_del()
        assertEquals(self.simple_list, {1,2,3})
        table.del(self.simple_list, 1)
        assertEquals(self.simple_list, {2,3})
        table.del(self.simple_list, 3)
        assertEquals(self.simple_list, {2})
        table.del(self.simple_list, 2)
        assertEquals(self.simple_list, {})
    end

    function TestUtils:test_table_del_multy()
        assertEquals(self.simple_list, {1,2,3})
        table.insert(self.simple_list, 2)
        assertEquals(self.simple_list, {1,2,3,2})
        table.del(self.simple_list, 1)
        assertEquals(self.simple_list, {2,3,2})
        table.del(self.simple_list, 2)
        assertEquals(self.simple_list, {3})
        table.del(self.simple_list, 3)
        assertEquals(self.simple_list, {})
    end

    function TestUtils:test_table_del_empty()
        local t = {}
        table.del(t, 4)
        assertEquals(t, {})
    end

    function TestUtils:test_table_size()
        local t = table.size(nil)
        assertEquals(t, 0)
        t = table.size({1,2})
        assertEquals(t, 2)
        t = table.size({})
        assertEquals(t, 0)
        t = table.size({hola={1,2},adios=2})
        assertEquals(t, 2)
    end

    function TestUtils:test_table_shuffle()
        assertEquals(self.simple_list, {1,2,3})
        table.add(self.simple_list, 4)
        table.add(self.simple_list, 5)
        table.add(self.simple_list, 6)
        local tmp = table.shuffle(self.simple_list)
        assertItemsEquals(self.simple_list, tmp)
        assertNotEquals(self.simple_list, tmp)
        local tmp2 = table.shuffle(self.simple_list)
        assertItemsEquals(self.simple_list, tmp2)
        --print(table.tostring(tmp))
        --print(table.tostring(tmp2))
        assertNotEquals(tmp2, tmp)
    end

    function TestUtils:test_table_shift()
        assertEquals(self.simple_list, {1,2,3})
        table.add(self.simple_list, 4)
        table.add(self.simple_list, 5)
        table.add(self.simple_list, 6)
        table.shift(self.simple_list, 2)
        assertEquals(self.simple_list, {3,4,5,6,1,2})
    end

    function TestUtils:test_table_shift2()
        local tmp = table.deepcopy(self.simple_list)
        assertEquals(tmp, {1,2,3})
        table.shift(tmp, 0)
        assertEquals(tmp, {1,2,3})
        tmp = table.deepcopy(self.simple_list)
        table.shift(tmp, 1)
        assertEquals(tmp, {2,3,1})
        tmp = table.deepcopy(self.simple_list)
        table.shift(tmp, 2)
        assertEquals(tmp, {3,1,2})
        tmp = table.deepcopy(self.simple_list)
        table.shift(tmp, 3)
        assertEquals(tmp, {1,2,3})
        tmp = table.deepcopy(self.simple_list)
        table.shift(tmp, 4)
        assertEquals(tmp, {2,3,1})
    end

    function TestUtils:test_table_tostring()
        assertError(table.tostring, "nil")
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

    function TestUtils:test_table_merge()
        assertEquals(self.simple_list, {1,2,3})
        table.merge(self.simple_list, {1})
        assertEquals(self.simple_list, {1,2,3})
        table.merge(self.simple_list, {5})
        assertEquals(self.simple_list, {1,2,3,5})
        table.merge(self.simple_list, {5,4})
        assertEquals(self.simple_list, {1,2,3,5,4})
        table.merge(nil, nil)
        table.merge(nil, {})
        local tmp = {}
        table.merge(tmp, {1,2,3,5,4})
        assertEquals(tmp, {1,2,3,5,4})
    end
-- class TestUtils

TestStack = {}
    function TestStack:test()
        local s = Stack:new()
        assertEquals(type(s), 'table')
        assertEquals(s.__class__, 'Stack')
    end

    function TestStack:test_size()
        local s = Stack:new()
        assertEquals(s:size(),0)
        s:push(1)
        assertEquals(s:size(),1)
        s:pop()
        assertEquals(s:size(),0)
    end

    function TestStack:test_push()
        local s s = Stack:new()
        s:push(1)
        assertEquals(s:size(),1)
    end

    function TestStack:test_pop()
        local s = Stack:new()
        assertEquals(s:pop(), nil)
        s:push(1)
        assertEquals(s:size(),1)
        assertEquals(s:pop(),1)
        assertEquals(s:size(),0)
    end

    function TestStack:test_get()
        local s = Stack:new()
        s:push(1)
        assertEquals(s:get(0),1)
        s:push({1,2,3})
        assertEquals(s:get(0),{1,2,3})
        assertEquals(s:get(1),1)
        assertError(s.get, s, -1)
        assertIsNil(s:get(2))
    end

    function TestStack:test_get_op()
        local s = Stack:new()
        s:push(1)
        assertEquals(s[0],1)
        s:push({1,2,3})
        assertEquals(s[0],{1,2,3})
        assertEquals(s[1],1)
        assertIsNil(s[2])
    end

    function TestStack:test_set()
        local s = Stack:new()
        s:push(1)
        s:push({1,2,3})
        assertEquals(s:size(),2)
        assertEquals(s:get(0),{1,2,3})
        assertEquals(s:get(1),1)
        s:set(1, 2)
        assertEquals(s:size(),2)
        assertEquals(s:get(0),{1,2,3})
        assertEquals(s:get(1),2)
        s:set(2, 3)
        assertEquals(s:size(),2)
        assertEquals(s:get(0),{1,2,3})
        assertEquals(s:get(1),2)
        assertIsNil(s:get(2))
        assertError(s.set, s, "no", -1)
        assertError(s.set, s, -1, 2)
    end

    function TestStack:test_set_op()
        local s = Stack:new()
        s:push(1)
        s:push({1,2,3})
        assertEquals(s:size(),2)
        assertEquals(s:get(0),{1,2,3})
        assertEquals(s:get(1),1)
        s[1] = 2
        assertEquals(s:size(),2)
        assertEquals(s:get(0),{1,2,3})
        assertEquals(s:get(1),2)
        s[0] = "new"
        assertEquals(s:size(),2)
        assertEquals(s:get(0),"new")
        assertEquals(s:get(1),2)
        s[1] = "old"
        assertEquals(s:get(0),"new")
        assertEquals(s:get(1),"old")
        assertEquals(s:size(),2)
        s[2] = "error"
        assertEquals(s:get(0),"new")
        assertEquals(s:get(1),"old")
        assertIsNil(s:get(2))
        assertEquals(s:size(),2)
    end

    function TestStack:test_list()
        local s = Stack:new()
        local l = s:list()
        assertEquals(#l, 0)
        s:push(1)
        s:push({1,2,3})
        assertEquals(s:size(),2)
        l = s:list()
        assertItemsEquals(l[1],{1,2,3})
        assertEquals(l[2],1)
        assertEquals(s:size(),2)
    end

    function TestStack:test_tostring()
        local s = Stack:new()
        s:push(1)
        assertEquals(tostring(s), "{1}")
        s:push(2)
        assertEquals(tostring(s), "{2,1}")
    end
-- class TestStack
--EOF