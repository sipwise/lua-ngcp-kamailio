--
-- Copyright 2020 SipWise Team <development@sipwise.com>
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
require 'busted.runner'()

describe("utils", function()
    local ut
    local simple_hash
    local simple_list, long_list
    local complex_hash

    setup(function()
        ut = require("ngcp.utils")
    end)

    before_each(function()
        simple_hash = {
            one = 1, two = 2, three = 3
        }
        simple_list = {
            1, 2, 3
        }
        long_list = {
            1, 2, 3, 4 ,5, 6
        }
        complex_hash = {
            cone = simple_list,
            ctwo = simple_hash
        }
    end)

    describe("table", function()
        it("deepcopy", function()
            local res = ut.table.deepcopy(simple_hash)
            assert.same(res, simple_hash)
            assert.is_not(res, simple_hash)
        end)

        it("contains should find the value", function()
            assert.True(ut.table.contains(simple_hash, 3))
        end)

        it("contains should not find the value", function()
            assert.False(ut.table.contains(simple_hash, 4))
        end)

        it("contains should not find anything in nil", function()
            assert.False(ut.table.contains(nil))
        end)

        it("contains should throw an error with a string", function()
            local f = function()
                ut.table.contains("hola", 1)
            end
            assert.has_error(f,
                "bad argument #1 to 'pairs' (table expected, got string)")
        end)

        it("add", function ()
            assert.same(simple_list, {1,2,3})
            ut.table.add(simple_list, 1)
            assert.same(simple_list, {1,2,3})
            ut.table.add(simple_list, 5)
            assert.same(simple_list, {1,2,3,5})
            ut.table.add(simple_list, 4)
            assert.same(simple_list, {1,2,3,5,4})
        end)

        it("del", function()
            assert.same(simple_list, {1,2,3})
            ut.table.del(simple_list, 1)
            assert.same(simple_list, {2,3})
            ut.table.del(simple_list, 3)
            assert.same(simple_list, {2})
            ut.table.del(simple_list, 2)
            assert.same(simple_list, {})
        end)

        it("del_multy", function()
            assert.same(simple_list, {1,2,3})
            table.insert(simple_list, 2)
            assert.same(simple_list, {1,2,3,2})
            ut.table.del(simple_list, 1)
            assert.same(simple_list, {2,3,2})
            ut.table.del(simple_list, 2)
            assert.same(simple_list, {3})
            ut.table.del(simple_list, 3)
            assert.same(simple_list, {})
        end)

        it("del_empty", function()
            local t = {}
            ut.table.del(t, 4)
            assert.same(t, {})
        end)

        it("size", function()
            local t = ut.table.size(nil)
            assert.same(t, 0)
            t = ut.table.size({1,2})
            assert.same(t, 2)
            t = ut.table.size({})
            assert.same(t, 0)
            t = ut.table.size({hola={1,2},adios=2})
            assert.same(t, 2)
        end)

        it("shuffle", function()
            assert.same(long_list, {1, 2, 3, 4, 5, 6})
            local tmp = ut.table.shuffle(long_list)
            assert.equal_items(long_list, tmp)
            assert.not_same(long_list, tmp)
            local tmp2 = ut.table.shuffle(long_list)
            assert.equal_items(long_list, tmp2)
            assert.not_same(tmp2, tmp)
        end)

        it("shift", function()
            assert.same(long_list, {1, 2, 3, 4, 5, 6})
            ut.table.shift(long_list, 2)
            assert.same(long_list, {3,4,5,6,1,2})
        end)

        it("shift2", function()
            local tmp = ut.table.deepcopy(simple_list)
            assert.same(tmp, {1,2,3})
            ut.table.shift(tmp, 0)
            assert.same(tmp, {1,2,3})
            tmp = ut.table.deepcopy(simple_list)
            ut.table.shift(tmp, 1)
            assert.same(tmp, {2,3,1})
            tmp = ut.table.deepcopy(simple_list)
            ut.table.shift(tmp, 2)
            assert.same(tmp, {3,1,2})
            tmp = ut.table.deepcopy(simple_list)
            ut.table.shift(tmp, 3)
            assert.same(tmp, {1,2,3})
            tmp = ut.table.deepcopy(simple_list)
            ut.table.shift(tmp, 4)
            assert.same(tmp, {2,3,1})
        end)

        it("tostring", function()
            local f = function()
                ut.table.tostring("nil")
            end
            assert.has_error(f)
            assert.same(ut.table.tostring(simple_list), "{1,2,3}")
            assert.not_nil(ut.table.tostring(simple_hash))
            assert.not_nil(ut.table.tostring(complex_hash))
        end)
    end) -- end table

    it("implode", function()
        assert.same(ut.implode(',', simple_list, "'"), "'1','2','3'")
    end)

    it("implode should error with nil string", function()
        local f = function()
            ut.implode(nil, simple_list, "'")
        end
        assert.has_error(f)
    end)

    it("implode should error with nil table", function()
        local f = function()
            ut.implode(',', nil, "'")
        end
        assert.has_error(f)
    end)

    it("explode", function()
        assert.equal_items(ut.explode(',',"1,2,3"), {'1','2','3'})
        assert.equal_items(ut.explode('=>',"1=>2=>3"), {'1','2','3'})
    end)

    describe("string", function()

        it("explode_values should error with nil", function()
            local f = function()
                ut.string.explode_values(nil)
            end
            assert.has_error(f)
        end)

        it("explode_values", function()
            assert.equal_items(ut.string.explode_values(''), {})
            assert.equal_items(ut.string.explode_values('1'), {'1'})
            assert.equal_items(ut.string.explode_values('123'), {'1','12','123'})
        end)
    end) -- end string
end)
