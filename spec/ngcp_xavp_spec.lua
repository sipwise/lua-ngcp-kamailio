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

describe("xavp", function()
    local NGCPXAvp
    local vals = {
        {
            id = 1,
            uuid = "ae736f72-21d1-4ea6-a3ea-4d7f56b3887c",
            username = "testuser1",
            domain = "192.168.51.56",
            attribute = "account_id",
            type = 1,
            value = 2,
            last_modified = "1900-01-01 00:00:01"
        },
        {
            id = 2,
            uuid = "ae736f72-21d1-4ea6-a3ea-4d7f56b3887c",
            username = "testuser1",
            domain = "192.168.51.56",
            attribute = "whatever",
            type = 1,
            value = 2,
            last_modified = "1900-01-01 00:00:01"
        },
        {
            id = 3,
            uuid = "ae736f72-21d1-4ea6-a3ea-4d7f56b3887c",
            username = "testuser1",
            domain = "192.168.51.56",
            attribute = "elsewhere",
            type = 0,
            value = "2",
            last_modified = "1900-01-01 00:00:01"
        }
    }

    setup(function()
        local ksrMock = require 'mocks.ksr'
        _G.KSR = ksrMock.new()
        NGCPXAvp = require 'ngcp.xavp'
    end)

    after_each(function()
        _G.KSR.pv.vars = {}
    end)

    it("create", function()
        NGCPXAvp:new("caller", "peer", {})
        assert.same(_G.KSR.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        NGCPXAvp:new("callee", "peer", {})
        assert.same(_G.KSR.pv.get("$xavp(callee_peer=>dummy)"),"callee")
    end)

    it("id", function()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        assert.same(xavp.level, "caller")
        assert.same(xavp.group, "peer")
        assert.same(xavp.name, "caller_peer")
        assert.equal_items(xavp.keys, {"account_id","whatever","elsewhere"})
    end)

    it("get", function()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        _G.KSR.pv.sets("$xavp(caller_peer=>testid)", "value")
        assert.same(xavp("testid"), "value")
        _G.KSR.pv.sets("$xavp(caller_peer=>testid)", "1")
        assert.equal_items(xavp("testid"), "1")
    end)

    it("get_all", function()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        _G.KSR.pv.sets("$xavp(caller_peer=>testid)", "value")
        assert.same(xavp("testid"), "value")
        _G.KSR.pv.sets("$xavp(caller_peer[0]=>testid)", "1")
        assert.equal_items(xavp:all("testid"), {"1", "value"})
    end)

    it("set", function()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        local lvals = {1,"2",3,nil}
        for i=1,#lvals do
            xavp("testid",lvals[i])
            assert.same(xavp("testid"), lvals[i])
            assert.same(_G.KSR.pv.get("$xavp(caller_peer=>testid)"),lvals[i])
        end
    end)

    it("clean", function()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        xavp("testid", 1)
        assert.same(_G.KSR.pv.get("$xavp(caller_peer=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        xavp:clean()
        assert.same(_G.KSR.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        assert.is_nil(xavp("testid"))
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_peer=>testid)"))
    end)

    it("clean_all", function()
        local xavp_caller = NGCPXAvp:new("caller", "peer", {})
        assert.same(_G.KSR.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        local xavp_callee = NGCPXAvp:new("callee", "peer", {})
        assert.same(_G.KSR.pv.get("$xavp(callee_peer=>dummy)"),"callee")

        xavp_caller:clean()
        assert.same(_G.KSR.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(callee_peer=>dummy)"),"callee")

        xavp_callee:clean()
        assert.same(_G.KSR.pv.get("$xavp(callee_peer=>dummy)"), "callee")
        assert.same(_G.KSR.pv.get("$xavp(caller_peer=>dummy)"), "caller")
    end)

    it("clean_key", function()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        local lvals = {1,"2",3,nil}
        for i=1,#lvals do
            xavp("testid",lvals[i])
            assert.same(xavp("testid"), lvals[i])
            assert.same(_G.KSR.pv.get("$xavp(caller_peer=>testid)"), lvals[i])
        end
        xavp("other", 1)
        xavp("other", 2)
        xavp("other", 3)
        assert.equal_items(xavp:all("other"), {3,2,1})
        xavp:clean("testid")
        assert.is_nil(xavp("testid"))
        assert.equal_items(xavp:all("other"), {3,2,1})
    end)

    it("tostring", function()
        assert.same({}, _G.KSR.pv.vars)
        local xavp = NGCPXAvp:new("caller", "peer", {})
        assert.same('{dummy={"caller"}}', tostring(xavp))
    end)

    it("keys", function()
        local expected = {"account_id", "whatever", "elsewhere", "testid"}
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        xavp("testid", 1)
        assert.equal_items(expected, xavp.keys)
        xavp:clean()
        assert.equal_items(expected, xavp.keys)
    end)
end)
