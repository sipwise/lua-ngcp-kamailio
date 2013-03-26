#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
require 'ngcp.xavp'

sr = srMock:new()

TestNGCPXAvp = {} --class
    function TestNGCPXAvp:setUp()
        self.vals = {}
        self.vals[1] = {
            id = 1,
            uuid = "ae736f72-21d1-4ea6-a3ea-4d7f56b3887c",
            username = "testuser1",
            domain = "192.168.51.56",
            attribute = "account_id",
            type = 1,
            value = 2,
            last_modified = "1900-01-01 00:00:01"
        }
        self.vals[2] = {
            id = 2,
            uuid = "94023caf-dfba-4f33-8bdb-b613ce627613",
            username = "testuser2",
            domain = "192.168.51.56",
            attribute = "account_id",
            type = 1,
            value = 2,
            last_modified = "1900-01-01 00:00:01"
        }
        self.vals[3] = {
            id = 3,
            uuid = "94023caf-dfba-4f33-8bdb-b613ce627613",
            username = "testuser2",
            domain = "192.168.51.56",
            attribute = "account_id",
            type = 0,
            value = "2",
            last_modified = "1900-01-01 00:00:01"
        }
        self.xavp = NGCPXAvp:new(1, "peer", self.vals)
    end

    function TestNGCPXAvp:tearDown()
        sr.pv.vars = {}
    end

    function TestNGCPXAvp:test_xavp_id()
        assertEquals(self.xavp.level, 1)
        assertEquals(self.xavp.group, "peer")
    end

    function TestNGCPXAvp:test_xavp_get()
        sr.pv.sets("$xavp(peer[1]=>testid)", "value")
        assertEquals(self.xavp("testid"), "value")
        sr.pv.sets("$xavp(peer[1]=>testid)", "1")
        assertItemsEquals(self.xavp("testid"),{"1","value"})
    end

    function TestNGCPXAvp:test_xavp_set()
        local vals = {1,2,3}
        for i=1,#vals do
            self.xavp("testid",vals[i])
        end
        local l = self.xavp("testid")
        assertTrue(type(l), 'table')
        --print(table.tostring(l))
        v = 1
        for i=#vals,1,-1 do
           assertEquals(l[i],vals[v])
           v = v + 1 
        end        
    end

    function TestNGCPXAvp:test_xavp_set2()
        local vals = {1,2,"3"}
        for i=1,#vals do
            self.xavp("testid", vals[i])
        end
        local l = self.xavp("testid")
        assertTrue(type(l), 'table')
        --print(table.tostring(l))
        v = 1
        for i=#vals,1,-1 do
           assertEquals(l[i],vals[v])
           v = v + 1 
        end        
    end

    function TestNGCPXAvp:test_clean()
        self.xavp("testid", 1)
        self.xavp:clean()
        assertFalse(self.xavp("testid"))
    end
-- class TestNGCPXAvp

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF