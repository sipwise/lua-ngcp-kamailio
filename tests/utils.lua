--
-- Copyright 2013-2020 SipWise Team <development@sipwise.com>
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
local lu = require('luaunit')
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
        lu.assertNotIs(utils.table.deepcopy(self.simple_hash), self.simple_hash)
        -- if the parameter is not a table... it has te be the same
        lu.assertIs(utils.table.deepcopy("hola"), "hola")
    end

    function TestUtils:test_table_contains()
        lu.assertTrue(utils.table.contains(self.simple_hash, 3))
        lu.assertFalse(utils.table.contains(self.simple_hash, 4))
        lu.assertFalse(utils.table.contains(nil))
        lu.assertError(utils.table.contains, "hola",1)
    end

    function TestUtils:test_table_add()
        lu.assertEquals(self.simple_list, {1,2,3})
        utils.table.add(self.simple_list, 1)
        lu.assertEquals(self.simple_list, {1,2,3})
        utils.table.add(self.simple_list, 5)
        lu.assertEquals(self.simple_list, {1,2,3,5})
        utils.table.add(self.simple_list, 4)
        lu.assertEquals(self.simple_list, {1,2,3,5,4})
    end

    function TestUtils:test_table_del()
        lu.assertEquals(self.simple_list, {1,2,3})
        utils.table.del(self.simple_list, 1)
        lu.assertEquals(self.simple_list, {2,3})
        utils.table.del(self.simple_list, 3)
        lu.assertEquals(self.simple_list, {2})
        utils.table.del(self.simple_list, 2)
        lu.assertEquals(self.simple_list, {})
    end

    function TestUtils:test_table_del_multy()
        lu.assertEquals(self.simple_list, {1,2,3})
        table.insert(self.simple_list, 2)
        lu.assertEquals(self.simple_list, {1,2,3,2})
        utils.table.del(self.simple_list, 1)
        lu.assertEquals(self.simple_list, {2,3,2})
        utils.table.del(self.simple_list, 2)
        lu.assertEquals(self.simple_list, {3})
        utils.table.del(self.simple_list, 3)
        lu.assertEquals(self.simple_list, {})
    end

    function TestUtils:test_table_del_empty()
        local t = {}
        utils.table.del(t, 4)
        lu.assertEquals(t, {})
    end

    function TestUtils:test_table_size()
        local t = utils.table.size(nil)
        lu.assertEquals(t, 0)
        t = utils.table.size({1,2})
        lu.assertEquals(t, 2)
        t = utils.table.size({})
        lu.assertEquals(t, 0)
        t = utils.table.size({hola={1,2},adios=2})
        lu.assertEquals(t, 2)
    end

    function TestUtils:test_table_shuffle()
        lu.assertEquals(self.simple_list, {1,2,3})
        utils.table.add(self.simple_list, 4)
        utils.table.add(self.simple_list, 5)
        utils.table.add(self.simple_list, 6)
        local tmp = utils.table.shuffle(self.simple_list)
        lu.assertItemsEquals(self.simple_list, tmp)
        lu.assertNotEquals(self.simple_list, tmp)
        local tmp2 = utils.table.shuffle(self.simple_list)
        lu.assertItemsEquals(self.simple_list, tmp2)
        --print(table.tostring(tmp))
        --print(table.tostring(tmp2))
        lu.assertNotEquals(tmp2, tmp)
    end

    function TestUtils:test_table_shift()
        lu.assertEquals(self.simple_list, {1,2,3})
        utils.table.add(self.simple_list, 4)
        utils.table.add(self.simple_list, 5)
        utils.table.add(self.simple_list, 6)
        utils.table.shift(self.simple_list, 2)
        lu.assertEquals(self.simple_list, {3,4,5,6,1,2})
    end

    function TestUtils:test_table_shift2()
        local tmp = utils.table.deepcopy(self.simple_list)
        lu.assertEquals(tmp, {1,2,3})
        utils.table.shift(tmp, 0)
        lu.assertEquals(tmp, {1,2,3})
        tmp = utils.table.deepcopy(self.simple_list)
        utils.table.shift(tmp, 1)
        lu.assertEquals(tmp, {2,3,1})
        tmp = utils.table.deepcopy(self.simple_list)
        utils.table.shift(tmp, 2)
        lu.assertEquals(tmp, {3,1,2})
        tmp = utils.table.deepcopy(self.simple_list)
        utils.table.shift(tmp, 3)
        lu.assertEquals(tmp, {1,2,3})
        tmp = utils.table.deepcopy(self.simple_list)
        utils.table.shift(tmp, 4)
        lu.assertEquals(tmp, {2,3,1})
    end

    function TestUtils:test_table_tostring()
        lu.assertError(utils.table.tostring, "nil")
        lu.assertEquals(utils.table.tostring(self.simple_list), "{1,2,3}")
        lu.assertEvalToTrue(utils.table.tostring(self.simple_hash))
        --print(table.tostring(self.simple_hash) .. "\n")
        lu.assertEvalToTrue(utils.table.tostring(self.complex_hash))
        --print(table.tostring(self.complex_hash))
    end

    function TestUtils:test_implode()
        lu.assertEquals(utils.implode(',', self.simple_list, "'"), "'1','2','3'")
        lu.assertError(utils.implode, nil, self.simple_list, "'")
        lu.assertError(utils.implode, ',', nil, "'")
    end

    function TestUtils:test_explode()
        lu.assertItemsEquals(utils.explode(',',"1,2,3"), {'1','2','3'})
        lu.assertItemsEquals(utils.explode('=>',"1=>2=>3"), {'1','2','3'})
    end

    function TestUtils:test_string_explode_values()
        lu.assertError(utils.string.explode_values, nil)
        lu.assertItemsEquals(utils.string.explode_values(''), {})
        lu.assertItemsEquals(utils.string.explode_values('1'), {'1'})
        lu.assertItemsEquals(utils.string.explode_values('123'), {'1','12','123'})
    end

    function TestUtils:test_starts()
        lu.assertError(utils.string.stats, nil, "g")
        lu.assertTrue(utils.string.starts("goga", "g"))
        lu.assertTrue(utils.string.starts("goga", "go"))
        lu.assertTrue(utils.string.starts("goga", "gog"))
        lu.assertTrue(utils.string.starts("goga", "goga"))
        lu.assertFalse(utils.string.starts("goga", "a"))
        lu.assertError(utils.string.starts, "goga", nil)
        lu.assertTrue(utils.string.starts("$goga", "$"))
        lu.assertTrue(utils.string.starts("(goga)", "("))
    end

    function TestUtils:test_ends()
        lu.assertError(utils.string.ends, nil, "g")
        lu.assertTrue(utils.string.ends("goga", "a"))
        lu.assertTrue(utils.string.ends("goga", "ga"))
        lu.assertTrue(utils.string.ends("goga", "oga"))
        lu.assertTrue(utils.string.ends("goga", "goga"))
        lu.assertFalse(utils.string.ends("goga", "f"))
        lu.assertError(utils.string.ends, "goga", nil)
    end

    function TestUtils:test_table_merge()
        lu.assertEquals(self.simple_list, {1,2,3})
        utils.table.merge(self.simple_list, {1})
        lu.assertEquals(self.simple_list, {1,2,3})
        utils.table.merge(self.simple_list, {5})
        lu.assertEquals(self.simple_list, {1,2,3,5})
        utils.table.merge(self.simple_list, {5,4})
        lu.assertEquals(self.simple_list, {1,2,3,5,4})
        utils.table.merge(nil, nil)
        utils.table.merge(nil, {})
        local tmp = {}
        utils.table.merge(tmp, {1,2,3,5,4})
        lu.assertEquals(tmp, {1,2,3,5,4})
    end
