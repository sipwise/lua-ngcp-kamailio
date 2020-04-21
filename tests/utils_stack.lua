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
local Stack = utils.Stack

-- luacheck: ignore TestStack
TestStack = {}
    function TestStack:test()
        local s = Stack.new()
        lu.assertEquals(type(s), 'table')
        lu.assertEquals(s.__class__, 'Stack')
    end

    function TestStack:test_size()
        local s = Stack:new()
        lu.assertEquals(s:size(),0)
        s:push(1)
        lu.assertEquals(s:size(),1)
        s:pop()
        lu.assertEquals(s:size(),0)
    end

    function TestStack:test_push()
        local s s = Stack:new()
        s:push(1)
        lu.assertEquals(s:size(),1)
    end

    function TestStack:test_pop()
        local s = Stack:new()
        lu.assertEquals(s:pop(), nil)
        s:push(1)
        lu.assertEquals(s:size(),1)
        lu.assertEquals(s:pop(),1)
        lu.assertEquals(s:size(),0)
    end

    function TestStack:test_get()
        local s = Stack:new()
        s:push(1)
        lu.assertEquals(s:get(0),1)
        s:push({1,2,3})
        lu.assertEquals(s:get(0),{1,2,3})
        lu.assertEquals(s:get(1),1)
        lu.assertError(s.get, s, -1)
        lu.assertIsNil(s:get(2))
    end

    function TestStack:test_get_op()
        local s = Stack:new()
        s:push(1)
        lu.assertEquals(s[0],1)
        s:push({1,2,3})
        lu.assertEquals(s[0],{1,2,3})
        lu.assertEquals(s[1],1)
        lu.assertIsNil(s[2])
    end

    function TestStack:test_set()
        local s = Stack:new()
        s:push(1)
        s:push({1,2,3})
        lu.assertEquals(s:size(),2)
        lu.assertEquals(s:get(0),{1,2,3})
        lu.assertEquals(s:get(1),1)
        s:set(1, 2)
        lu.assertEquals(s:size(),2)
        lu.assertEquals(s:get(0),{1,2,3})
        lu.assertEquals(s:get(1),2)
        s:set(2, 3)
        lu.assertEquals(s:size(),2)
        lu.assertEquals(s:get(0),{1,2,3})
        lu.assertEquals(s:get(1),2)
        lu.assertIsNil(s:get(2))
        lu.assertError(s.set, s, "no", -1)
        lu.assertError(s.set, s, -1, 2)
    end

    function TestStack:test_set_op()
        local s = Stack:new()
        s:push(1)
        s:push({1,2,3})
        lu.assertEquals(s:size(),2)
        lu.assertEquals(s:get(0),{1,2,3})
        lu.assertEquals(s:get(1),1)
        s[1] = 2
        lu.assertEquals(s:size(),2)
        lu.assertEquals(s:get(0),{1,2,3})
        lu.assertEquals(s:get(1),2)
        s[0] = "new"
        lu.assertEquals(s:size(),2)
        lu.assertEquals(s:get(0),"new")
        lu.assertEquals(s:get(1),2)
        s[1] = "old"
        lu.assertEquals(s:get(0),"new")
        lu.assertEquals(s:get(1),"old")
        lu.assertEquals(s:size(),2)
        s[2] = "error"
        lu.assertEquals(s:get(0),"new")
        lu.assertEquals(s:get(1),"old")
        lu.assertIsNil(s:get(2))
        lu.assertEquals(s:size(),2)
    end

    function TestStack:test_list()
        local s = Stack:new()
        local l = s:list()
        lu.assertEquals(#l, 0)
        s:push(1)
        s:push({1,2,3})
        lu.assertEquals(s:size(),2)
        l = s:list()
        lu.assertItemsEquals(l[1],{1,2,3})
        lu.assertEquals(l[2],1)
        lu.assertEquals(s:size(),2)
    end

    function TestStack:test_tostring()
        local s = Stack:new()
        s:push(1)
        lu.assertEquals(tostring(s), "{1}")
        s:push(2)
        lu.assertEquals(tostring(s), "{2,1}")
    end
