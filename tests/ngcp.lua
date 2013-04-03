#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
require 'ngcp.utils'

sr = srMock:new()

local mc = lemock.controller()
local mysql = mc:mock()
local env   = mc:mock()
local con   = mc:mock()
local cur   = mc:mock()

package.loaded.luasql = nil
package.preload['luasql.mysql'] = function ()
    luasql = {}
    luasql.mysql = mysql
    return mysql
end

require 'ngcp.ngcp'

TestNGCP = {} --class

    function TestNGCP:setUp()
        self.ngcp = NGCP:new()
    end

    function TestNGCP:test_config()
        assertTrue(self.ngcp.config)
    end

    function TestNGCP:test_connection()
        assertTrue(self.ngcp.config)
        local c = self.ngcp.config
        luasql.mysql() ;mc :returns(env)
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(con)

        mc:replay()
        c:getDBConnection()
        mc:verify()
        assertTrue(self.ngcp.config)
    end

    function TestNGCP:test_prefs_init()
        --print("TestNGCP:test_prefs_init")
        assertTrue(self.ngcp)
        assertTrue(self.ngcp.prefs)
        assertTrue(self.ngcp.prefs.peer)
        assertTrue(self.ngcp.prefs.user)
        assertTrue(self.ngcp.prefs.domain)
        assertTrue(self.ngcp.prefs.real)
    end

    function TestNGCP:test_clean()
        local xavp = NGCPXAvp:new('callee','user',{})
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(user[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(user[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(user[0]=>dummy)"),"caller")
        self.ngcp:clean()
        assertFalse(sr.pv.get("$xavp(user[0]=>dummy)"))
        assertFalse(sr.pv.get("$xavp(user[1]=>dummy)"))
        assertFalse(sr.pv.get("$xavp(user)"))
    end

    function TestNGCP:test_callee_clean()
        local callee_xavp = NGCPXAvp:new('callee','domain',{})
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPXAvp:new('caller','domain',{})
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(domain[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(domain[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(domain[0]=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(domain[0]=>other)"),1)
        assertEquals(sr.pv.get("$xavp(domain[0]=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(domain[1]=>dummy)"),"callee")
        self.ngcp:clean('callee')
        assertEquals(sr.pv.get("$xavp(domain[0]=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(domain[1]=>testid)"))
        assertFalse(sr.pv.get("$xavp(domain[1]=>foo)"))
        assertEquals(sr.pv.get("$xavp(domain[0]=>other)"),1)
        assertEquals(sr.pv.get("$xavp(domain[0]=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(domain[1]=>dummy)"),"callee")
    end

    function TestNGCP:test_caller_clean()
        local callee_xavp = NGCPXAvp:new('callee','peer',{})
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPXAvp:new('caller','peer',{})
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(peer[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(peer[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(peer[0]=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(peer[0]=>other)"),1)
        assertEquals(sr.pv.get("$xavp(peer[0]=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(peer[1]=>dummy)"),"callee")
        self.ngcp:clean('caller')
        assertEquals(sr.pv.get("$xavp(peer[0]=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(peer[0]=>other)"))
        assertFalse(sr.pv.get("$xavp(peer[0]=>otherfoo)"))
        assertEquals(sr.pv.get("$xavp(peer[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(peer[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(peer[1]=>dummy)"),"callee")
    end

-- class TestNGCP

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF