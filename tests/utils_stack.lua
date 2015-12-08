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
local Stack = utils.Stack

-- luacheck: ignore TestStack
TestStack = {}
    function TestStack:test()
        local s = Stack.new()
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
