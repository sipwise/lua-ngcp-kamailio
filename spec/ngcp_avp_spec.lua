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

describe("avp", function()
    local NGCPAvp
    local avp

    setup(function()
        local ksrMock = require 'mocks.ksr'
        _G.KSR = ksrMock.new()
        NGCPAvp = require 'ngcp.avp'
    end)

    before_each(function()
        avp = NGCPAvp:new("testid")
    end)

    after_each(function()
        _G.KSR.pv.vars = {}
    end)

    it("id", function()
        assert.same(avp.id, "$avp(s:testid)")
    end)

    it("get", function()
        _G.KSR.pv.sets("$avp(s:testid)", "value")
        assert.same(avp(), "value")
        _G.KSR.pv.sets("$avp(s:testid)", "1")
        assert.equal_items(avp(), "1")
        assert.equal_items(avp:all(),{"1","value"})
    end)

    it("set", function()
        local vals = {1,2,3}
        local okvals = {3,2,1}
        for i=1,#vals do
            avp(vals[i])
            assert.same(avp(),vals[i])
        end
        assert.same(avp:all(), okvals)
    end)

    it("set with mixed values", function()
        local vals = {1,2,"3"}
        local okvals = {"3",2,1}
        for i=1,#vals do
            avp(vals[i])
            assert.same(avp(), vals[i])
        end
        assert.same(avp:all(), okvals)
    end)

    it("set with list value mixed", function()
        local vals = {1,2, {"3", 4}}
        local okvals = {4, "3", 2, 1}

        for i=1,#vals do
            avp(vals[i])
        end
        assert.equal_items(avp:all(), okvals)
    end)

    it("del", function()
        local vals = {1,2, {"3", 4}}
        local okvals = {4, "3", 2, 1}

        for i=1,#vals do
            avp(vals[i])
        end
        assert.equal_items(avp:all(), okvals)
        avp:del(1)
        assert.equal_items(avp:all(), {4, "3", 2})
        avp:del(4)
        assert.equal_items(avp:all(), {"3", 2})
        avp:del(1)
        assert.equal_items(avp:all(), {"3", 2})
        avp:del("3")
        assert.equal_items(avp:all(), {2})
        avp:del(2)
        assert.is_nil(avp:all())
        avp:del(nil)
        assert.is_nil(avp:all())
    end)

    it("clean", function()
        avp(1)
        avp:clean()
        assert.is_nil(avp())
    end)

    it("log", function()
        avp:log()
    end)

    it("tostring", function()
        avp(1)
        assert.same(tostring(avp), "$avp(s:testid):1")
        avp("hola")
        assert.same(tostring(avp), "$avp(s:testid):hola")
    end)
end)
