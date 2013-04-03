#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
require 'ngcp.xavp'

sr = srMock:new()
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
    function TestNGCPXAvp:setUp()
        self.xavp = NGCPXAvp:new("caller", "peer", vals)
    end

    function TestNGCPXAvp:tearDown()
        sr.pv.vars = {}
    end

    function TestNGCPXAvp:test_xavp_id()
        assertEquals(self.xavp.level, 0)
        assertEquals(self.xavp.group, "peer")
    end

    function TestNGCPXAvp:test_xavp_get()
        sr.pv.sets("$xavp(peer[0]=>testid)", "value")
        assertEquals(self.xavp("testid"), "value")
        sr.pv.sets("$xavp(peer[0]=>testid)", "1")
        assertItemsEquals(self.xavp("testid"), "1")
    end

    function TestNGCPXAvp:test_xavp_set()
        local vals = {1,"2",3,nil}
        for i=1,#vals do
            self.xavp("testid",vals[i])
            assertEquals(self.xavp("testid"), vals[i])
            assertEquals(sr.pv.get("$xavp(peer[0]=>testid)"),vals[i])
        end
    end

    function TestNGCPXAvp:test_clean()
        self.xavp("testid", 1)
        assertEquals(sr.pv.get("$xavp(peer[0]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(peer[0]=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(peer[1]=>dummy)"),"callee")
        self.xavp:clean()
        assertFalse(self.xavp("testid"))
        assertFalse(sr.pv.get("$xavp(peer[0]=>testid)"))
        assertEquals(sr.pv.get("$xavp(peer[0]=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(peer[1]=>dummy)"),"callee")
    end

    function TestNGCPXAvp:test_keys()
        assertItemsEquals(self.xavp.keys, {"account_id","whatever","elsewhere"})
        self.xavp("testid", 1)
        assertItemsEquals(self.xavp.keys, {"account_id","whatever","elsewhere","testid"})
        self.xavp:clean()
        assertItemsEquals(self.xavp.keys, {"account_id","whatever","elsewhere","testid"})
    end

-- class TestNGCPXAvp

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF