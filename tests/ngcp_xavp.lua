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
require 'ngcp.xavp'

if not sr then
    require 'mocks.sr'
    sr = srMock:new()
else
    argv = {}
end

vals = {
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
TestNGCPXAvp = {} --class
    function TestNGCPXAvp:test_create()
        local xavp = NGCPXAvp:new("caller", "peer", {})
        assertEquals(sr.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        xavp = NGCPXAvp:new("callee", "peer", {})
        assertEquals(sr.pv.get("$xavp(callee_peer=>dummy)"),"callee")
    end

    function TestNGCPXAvp:test_xavp_id()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        assertEquals(xavp.level, "caller")
        assertEquals(xavp.group, "peer")
        assertEquals(xavp.name, "caller_peer")
        assertItemsEquals(xavp.keys, {"account_id","whatever","elsewhere"})
    end

    function TestNGCPXAvp:test_xavp_get()
        xavp = NGCPXAvp:new("caller", "peer", vals)
        sr.pv.sets("$xavp(caller_peer=>testid)", "value")
        assertEquals(xavp("testid"), "value")
        sr.pv.sets("$xavp(caller_peer=>testid)", "1")
        assertItemsEquals(xavp("testid"), "1")
    end

    function TestNGCPXAvp:test_xavp_set()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        local vals = {1,"2",3,nil}
        for i=1,#vals do
            xavp("testid",vals[i])
            assertEquals(xavp("testid"), vals[i])
            assertEquals(sr.pv.get("$xavp(caller_peer=>testid)"),vals[i])
        end
    end

    function TestNGCPXAvp:test_clean()
        xavp = NGCPXAvp:new("caller", "peer", vals)
        xavp("testid", 1)
        assertEquals(sr.pv.get("$xavp(caller_peer=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        xavp:clean()
        assertEquals(sr.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        assertFalse(xavp("testid"))
        assertFalse(sr.pv.get("$xavp(caller_peer=>testid)"))
    end

    function TestNGCPXAvp:test_clean_all()
        local xavp_caller = NGCPXAvp:new("caller", "peer", {})
        assertEquals(sr.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        local xavp_callee = NGCPXAvp:new("callee", "peer", {})
        assertEquals(sr.pv.get("$xavp(callee_peer=>dummy)"),"callee")

        xavp_caller:clean()
        assertEquals(sr.pv.get("$xavp(caller_peer=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_peer=>dummy)"),"callee")

        xavp_callee:clean()
        assertEquals(sr.pv.get("$xavp(callee_peer=>dummy)"), "callee")
        assertEquals(sr.pv.get("$xavp(caller_peer=>dummy)"), "caller")
    end

    function TestNGCPXAvp:test_tostring()
        local xavp = NGCPXAvp:new("caller", "peer", {})
        assertEquals(tostring(xavp), '{dummy="caller"}')
    end

    function TestNGCPXAvp:test_keys()
        local xavp = NGCPXAvp:new("caller", "peer", vals)
        xavp("testid", 1)
        assertItemsEquals(xavp.keys, {"account_id","whatever","elsewhere","testid"})
        xavp:clean()
        assertItemsEquals(xavp.keys, {"account_id","whatever","elsewhere","testid"})
    end

-- class TestNGCPXAvp
--EOF