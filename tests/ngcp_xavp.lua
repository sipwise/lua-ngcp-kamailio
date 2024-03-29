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
local NGCPXAvp = require 'ngcp.xavp'

local ksrMock = require 'mocks.ksr'
KSR = ksrMock:new()

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
-- luacheck: ignore TestNGCPXAvp
TestNGCPXAvp = {} --class
    function TestNGCPXAvp:tearDown()
        KSR.pv.vars = {}
    end

    function TestNGCPXAvp:test_create()
        local xavp = NGCPXAvp:new("caller", "peer", {})
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        xavp = NGCPXAvp:new("callee", "peer", {})
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer=>dummy)"),"callee")
    end

    function TestNGCPXAvp:test_xavp_id()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        lu.assertEquals(xavp.level, "caller")
        lu.assertEquals(xavp.group, "peer")
        lu.assertEquals(xavp.name, "caller_peer")
        lu.assertItemsEquals(xavp.keys, {"account_id","whatever","elsewhere"})
    end

    function TestNGCPXAvp:test_xavp_get()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        KSR.pv.sets("$xavp(caller_peer=>testid)", "value")
        lu.assertEquals(xavp("testid"), "value")
        KSR.pv.sets("$xavp(caller_peer=>testid)", "1")
        lu.assertItemsEquals(xavp("testid"), "1")
    end

    function TestNGCPXAvp:test_xavp_get_all()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        KSR.pv.sets("$xavp(caller_peer=>testid)", "value")
        lu.assertEquals(xavp("testid"), "value")
        KSR.pv.sets("$xavp(caller_peer[0]=>testid)", "1")
        lu.assertItemsEquals(xavp:all("testid"), {"1", "value"})
    end

    function TestNGCPXAvp:test_xavp_set()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        local lvals = {1,"2",3,nil}
        for i=1,#lvals do
            xavp("testid",lvals[i])
            lu.assertEquals(xavp("testid"), lvals[i])
            lu.assertEquals(KSR.pv.get("$xavp(caller_peer=>testid)"),lvals[i])
        end
    end

    function TestNGCPXAvp:test_clean()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        xavp("testid", 1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        xavp:clean()
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        lu.assertNil(xavp("testid"))
        lu.assertNil(KSR.pv.get("$xavp(caller_peer=>testid)"))
    end

    function TestNGCPXAvp:test_clean_all()
        local xavp_caller = NGCPXAvp:new("caller", "peer", {})
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        local xavp_callee = NGCPXAvp:new("callee", "peer", {})
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer=>dummy)"),"callee")

        xavp_caller:clean()
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer=>dummy)"),"callee")

        xavp_callee:clean()
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer=>dummy)"), "callee")
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer=>dummy)"), "caller")
    end

    function TestNGCPXAvp:test_clean_key()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        local lvals = {1,"2",3,nil}
        for i=1,#lvals do
            xavp("testid",lvals[i])
            lu.assertEquals(xavp("testid"), lvals[i])
            lu.assertEquals(KSR.pv.get("$xavp(caller_peer=>testid)"),lvals[i])
        end
        xavp("other", 1)
        xavp("other", 2)
        xavp("other", 3)
        lu.assertItemsEquals(xavp:all("other"), {3,2,1})
        xavp:clean("testid")
        lu.assertIsNil(xavp("testid"))
        lu.assertItemsEquals(xavp:all("other"), {3,2,1})
    end

    function TestNGCPXAvp:test_tostring()
        local xavp = NGCPXAvp:new("caller", "peer", {})
        lu.assertEquals(tostring(xavp), '{dummy={"caller"}}')
    end

    function TestNGCPXAvp:test_keys()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        xavp("testid", 1)
        lu.assertItemsEquals(xavp.keys, {"account_id","whatever","elsewhere","testid"})
        xavp:clean()
        lu.assertItemsEquals(xavp.keys, {"account_id","whatever","elsewhere","testid"})
    end

-- class TestNGCPXAvp
