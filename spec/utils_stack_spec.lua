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

describe("utils stack", function()
    local ut
    local s

    setup(function()
        ut = require("ngcp.utils")
    end)

    before_each(function()
        s = ut.Stack:new()
    end)

    it("class checks", function()
        assert.same(type(s), 'table')
        assert.same(s.__class__, 'Stack')
    end)

    it("size", function()
        assert.same(s:size(), 0)
        s:push(1)
        assert.same(s:size(), 1)
        s:pop()
        assert.same(s:size(), 0)
    end)

    it("push", function()
        s:push(1)
        assert.same(s:size(),1)
    end)

    it("pop", function()
        assert.same(s:pop(), nil)
        s:push(1)
        assert.same(s:size(),1)
        assert.same(s:pop(),1)
        assert.same(s:size(),0)
    end)

    it("get", function()
        s:push(1)
        assert.same(s:get(0),1)
        s:push({1,2,3})
        assert.same(s:get(0),{1,2,3})
        assert.same(s:get(1),1)
        assert.has_error(function() s.get(s, -1) end)
        assert.is_nil(s:get(2))
    end)

    it("get_op", function()
        s:push(1)
        assert.same(s[0],1)
        s:push({1,2,3})
        assert.same(s[0],{1,2,3})
        assert.same(s[1],1)
        assert.is_nil(s[2])
    end)

    it("set", function()
        s:push(1)
        s:push({1,2,3})
        assert.same(s:size(),2)
        assert.same(s:get(0),{1,2,3})
        assert.same(s:get(1),1)
        s:set(1, 2)
        assert.same(s:size(),2)
        assert.same(s:get(0),{1,2,3})
        assert.same(s:get(1),2)
        s:set(2, 3)
        assert.same(s:size(),2)
        assert.same(s:get(0),{1,2,3})
        assert.same(s:get(1),2)
        assert.is_nil(s:get(2))
        assert.has_error(function() s.set(s, "no", -1) end)
        assert.has_error(function() s.set(s, -1, 2) end)
    end)

    it("set_op", function()
        s:push(1)
        s:push({1,2,3})
        assert.same(s:size(),2)
        assert.same(s:get(0),{1,2,3})
        assert.same(s:get(1),1)
        s[1] = 2
        assert.same(s:size(),2)
        assert.same(s:get(0),{1,2,3})
        assert.same(s:get(1),2)
        s[0] = "new"
        assert.same(s:size(),2)
        assert.same(s:get(0),"new")
        assert.same(s:get(1),2)
        s[1] = "old"
        assert.same(s:get(0),"new")
        assert.same(s:get(1),"old")
        assert.same(s:size(),2)
        s[2] = "error"
        assert.same(s:get(0),"new")
        assert.same(s:get(1),"old")
        assert.is_nil(s:get(2))
        assert.same(s:size(),2)
    end)

    it("list", function()
        local l = s:list()
        assert.same(#l, 0)
        s:push(1)
        s:push({1, 2, 3})
        assert.same(s:size(), 2)
        l = s:list()
        assert.equal_items(l[1], {1,2,3})
        assert.same(l[2], 1)
        assert.same(s:size(), 2)
    end)

    it("totring", function()
        s:push(1)
        assert.same(tostring(s), "{1}")
        s:push(2)
        assert.same(tostring(s), "{2,1}")
    end)
end)
