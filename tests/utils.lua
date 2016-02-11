--
-- Copyright 2013-2015 SipWise Team <development@sipwise.com>
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
local utils = require 'ngcp.utils'

-- luacheck: ignore TestUtils
TestUtils = {}

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
        assertNotIs(utils.table.deepcopy(self.simple_hash), self.simple_hash)
        -- if the parameter is not a table... it has te be the same
        assertIs(utils.table.deepcopy("hola"), "hola")
    end

    function TestUtils:test_table_contains()
        assertTrue(utils.table.contains(self.simple_hash, 3))
        assertFalse(utils.table.contains(self.simple_hash, 4))
        assertFalse(utils.table.contains(nil))
        assertError(utils.table.contains, "hola",1)
    end

    function TestUtils:test_table_add()
        assertEquals(self.simple_list, {1,2,3})
        utils.table.add(self.simple_list, 1)
        assertEquals(self.simple_list, {1,2,3})
        utils.table.add(self.simple_list, 5)
        assertEquals(self.simple_list, {1,2,3,5})
        utils.table.add(self.simple_list, 4)
        assertEquals(self.simple_list, {1,2,3,5,4})
    end

    function TestUtils:test_table_del()
        assertEquals(self.simple_list, {1,2,3})
        utils.table.del(self.simple_list, 1)
        assertEquals(self.simple_list, {2,3})
        utils.table.del(self.simple_list, 3)
        assertEquals(self.simple_list, {2})
        utils.table.del(self.simple_list, 2)
        assertEquals(self.simple_list, {})
    end

    function TestUtils:test_table_del_multy()
        assertEquals(self.simple_list, {1,2,3})
        table.insert(self.simple_list, 2)
        assertEquals(self.simple_list, {1,2,3,2})
        utils.table.del(self.simple_list, 1)
        assertEquals(self.simple_list, {2,3,2})
        utils.table.del(self.simple_list, 2)
        assertEquals(self.simple_list, {3})
        utils.table.del(self.simple_list, 3)
        assertEquals(self.simple_list, {})
    end

    function TestUtils:test_table_del_empty()
        local t = {}
        utils.table.del(t, 4)
        assertEquals(t, {})
    end

    function TestUtils:test_table_size()
        local t = utils.table.size(nil)
        assertEquals(t, 0)
        t = utils.table.size({1,2})
        assertEquals(t, 2)
        t = utils.table.size({})
        assertEquals(t, 0)
        t = utils.table.size({hola={1,2},adios=2})
        assertEquals(t, 2)
    end

    function TestUtils:test_table_shuffle()
        assertEquals(self.simple_list, {1,2,3})
        utils.table.add(self.simple_list, 4)
        utils.table.add(self.simple_list, 5)
        utils.table.add(self.simple_list, 6)
        local tmp = utils.table.shuffle(self.simple_list)
        assertItemsEquals(self.simple_list, tmp)
        assertNotEquals(self.simple_list, tmp)
        local tmp2 = utils.table.shuffle(self.simple_list)
        assertItemsEquals(self.simple_list, tmp2)
        --print(table.tostring(tmp))
        --print(table.tostring(tmp2))
        assertNotEquals(tmp2, tmp)
    end

    function TestUtils:test_table_shift()
        assertEquals(self.simple_list, {1,2,3})
        utils.table.add(self.simple_list, 4)
        utils.table.add(self.simple_list, 5)
        utils.table.add(self.simple_list, 6)
        utils.table.shift(self.simple_list, 2)
        assertEquals(self.simple_list, {3,4,5,6,1,2})
    end

    function TestUtils:test_table_shift2()
        local tmp = utils.table.deepcopy(self.simple_list)
        assertEquals(tmp, {1,2,3})
        utils.table.shift(tmp, 0)
        assertEquals(tmp, {1,2,3})
        tmp = utils.table.deepcopy(self.simple_list)
        utils.table.shift(tmp, 1)
        assertEquals(tmp, {2,3,1})
        tmp = utils.table.deepcopy(self.simple_list)
        utils.table.shift(tmp, 2)
        assertEquals(tmp, {3,1,2})
        tmp = utils.table.deepcopy(self.simple_list)
        utils.table.shift(tmp, 3)
        assertEquals(tmp, {1,2,3})
        tmp = utils.table.deepcopy(self.simple_list)
        utils.table.shift(tmp, 4)
        assertEquals(tmp, {2,3,1})
    end

    function TestUtils:test_table_tostring()
        assertError(utils.table.tostring, "nil")
        assertEquals(utils.table.tostring(self.simple_list), "{1,2,3}")
        assertTrue(utils.table.tostring(self.simple_hash))
        --print(table.tostring(self.simple_hash) .. "\n")
        assertTrue(utils.table.tostring(self.complex_hash))
        --print(table.tostring(self.complex_hash))
    end

    function TestUtils:test_implode()
        assertEquals(utils.implode(',', self.simple_list, "'"), "'1','2','3'")
        assertError(utils.implode, nil, self.simple_list, "'")
        assertError(utils.implode, ',', nil, "'")
    end

    function TestUtils:test_explode()
        assertItemsEquals(utils.explode(',',"1,2,3"), {'1','2','3'})
        assertItemsEquals(utils.explode('=>',"1=>2=>3"), {'1','2','3'})
    end

    function TestUtils:test_string_explode_lnp()
        assertError(utils.string.explode_lnp, nil)
        assertItemsEquals(utils.string.explode_lnp(''), {})
        assertItemsEquals(utils.string.explode_lnp('1'), {'1'})
        assertItemsEquals(utils.string.explode_lnp('123'), {'1','12','123'})
    end

    function TestUtils:test_starts()
        assertError(utils.string.stats, nil, "g")
        assertTrue(utils.string.starts("goga", "g"))
        assertTrue(utils.string.starts("goga", "go"))
        assertTrue(utils.string.starts("goga", "gog"))
        assertTrue(utils.string.starts("goga", "goga"))
        assertFalse(utils.string.starts("goga", "a"))
        assertError(utils.string.starts, "goga", nil)
        assertTrue(utils.string.starts("$goga", "$"))
        assertTrue(utils.string.starts("(goga)", "("))
    end

    function TestUtils:test_ends()
        assertError(utils.string.ends, nil, "g")
        assertTrue(utils.string.ends("goga", "a"))
        assertTrue(utils.string.ends("goga", "ga"))
        assertTrue(utils.string.ends("goga", "oga"))
        assertTrue(utils.string.ends("goga", "goga"))
        assertFalse(utils.string.ends("goga", "f"))
        assertError(utils.string.ends, "goga", nil)
    end

    function TestUtils:test_table_merge()
        assertEquals(self.simple_list, {1,2,3})
        utils.table.merge(self.simple_list, {1})
        assertEquals(self.simple_list, {1,2,3})
        utils.table.merge(self.simple_list, {5})
        assertEquals(self.simple_list, {1,2,3,5})
        utils.table.merge(self.simple_list, {5,4})
        assertEquals(self.simple_list, {1,2,3,5,4})
        utils.table.merge(nil, nil)
        utils.table.merge(nil, {})
        local tmp = {}
        utils.table.merge(tmp, {1,2,3,5,4})
        assertEquals(tmp, {1,2,3,5,4})
    end
