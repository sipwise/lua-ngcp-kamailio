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

    function TestNGCP:tearDown()
        sr.pv.unset("$xavp(caller_dom_prefs)")
        sr.pv.unset("$xavp(callee_dom_prefs)")
        sr.pv.unset("$xavp(caller_peer_prefs)")
        sr.pv.unset("$xavp(callee_peer_prefs)")
        sr.pv.unset("$xavp(caller_usr_prefs)")
        sr.pv.unset("$xavp(callee_usr_prefs)")
        sr.pv.unset("$xavp(caller_real_prefs)")
        sr.pv.unset("$xavp(callee_real_prefs)")
        sr.log("info", "---cleaned---")
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
        assertTrue(self.ngcp.prefs.usr)
        assertTrue(self.ngcp.prefs.dom)
        assertTrue(self.ngcp.prefs.real)
    end

    function TestNGCP:test_load_caller()
        assertEquals(self.ngcp:caller_load(), {real={}, peer={}})
    end

    function TestNGCP:test_load_callee()
        assertEquals(self.ngcp:callee_load(), {real={}, peer={}})
    end

    function TestNGCP:test_clean()
        local xavp = NGCPXAvp:new('callee','usr_prefs')
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assertFalse(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"))
        self.ngcp:clean()
        assertFalse(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"))
        assertFalse(sr.pv.get("$xavp(callee_usr_prefs=>dummy)"))
        assertFalse(sr.pv.get("$xavp(user)"))
    end

    function TestNGCP:test_clean_caller_groups()
        local groups = {"peer", "usr", "dom", "real"}
        local _,v

        for _,v in pairs(groups) do
            assertEquals(sr.pv.get(string.format("$xavp(caller_%s_prefs=>dummy)", v), "caller"))
            self.ngcp:clean("caller", v)
            assertFalse(sr.pv.get(string.format("$xavp(caller_%s_prefs=>dummy)", v)))
        end
        assertError(self.ngcp.clean, self.ngcp, "caller", "whatever")
    end

    function TestNGCP:test_clean_callee_groups()
        local groups = {"peer", "usr", "dom", "real"}
        local _,v

        for _,v in pairs(groups) do
            assertEquals(sr.pv.get(string.format("$xavp(callee_%s_prefs=>dummy)", v), "callee"))
            self.ngcp:clean("callee", v)
            assertFalse(sr.pv.get(string.format("$xavp(callee_%s_prefs=>dummy)", v)))
        end
        assertError(self.ngcp.clean, self.ngcp, "callee", "whatever")
    end

    function TestNGCP:test_callee_clean()
        local callee_xavp = NGCPDomainPrefs:xavp('callee')
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        callee_xavp("testid",1)
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>testid)"),1)
        callee_xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>foo)"),"foo")
        local caller_xavp = NGCPDomainPrefs:xavp('caller')
        caller_xavp("other",1)
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        self.ngcp:clean('callee')
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(callee_dom_prefs=>testid)"))
        assertFalse(sr.pv.get("$xavp(callee_dom_prefs=>foo)"))
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        assertFalse(sr.pv.get("$xavp(callee_dom_prefs=>dummy)"))
    end

    function TestNGCP:test_caller_clean()
        local callee_xavp = NGCPXAvp:new('callee','peer_prefs')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPXAvp:new('caller','peer_prefs')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        self.ngcp:clean('caller')
        assertFalse(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"))
        assertFalse(sr.pv.get("$xavp(caller_peer_prefs=>other)"))
        assertFalse(sr.pv.get("$xavp(caller_peer_prefs=>otherfoo)"))
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
    end

-- class TestNGCP
--EOF