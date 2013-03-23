#!/usr/bin/env lua5.1
require('luaunit')
require 'ngcp.ngcp'
require 'mocks.sr'
require 'utils'

sr = srMock:new()

TestNGCPPrefs = {} --class

    function TestNGCPPrefs:setUp()
        self.prefs = NGCPPrefs:new()
    end

    function TestNGCPPrefs:test_prefs_init()
        assertItemsEquals(self.prefs.groups, {"inbound","outbound","common"})
        assertTrue(self.prefs.inbound)
        assertTrue(self.prefs.outbound)
        assertTrue(self.prefs.common)
    end

    function TestNGCPPrefs:test_pref_clean()
        --self.prefs:clean()
        assertError(self.prefs.clean, nil)
    end
-- class TestNGCPPrefs

TestNGCP = {} --class

    function TestNGCP:setUp()
        self.ngcp = NGCP:new()
    end

    function TestNGCP:test_config()
        assertTrue(self.ngcp.config)
    end

    function TestNGCP:test_prefs_init()
        --print("TestNGCP:test_prefs_init")
        assertTrue(self.ngcp)
        assertTrue(self.ngcp.prefs)
        assertTrue(self.ngcp.prefs.peer)
        assertTrue(self.ngcp.prefs.domain)
    end

    function TestNGCP:test_peerpref_clean()
        --print("TestNGCP:test_peerpref_clean")
        assertTrue(self.ngcp.prefs.peer)
        self.ngcp.prefs.peer.inbound.peer_peer_callee_auth_user = "usertest"
        self.ngcp.prefs.peer:clean("outbound")
        assertEquals(self.ngcp.prefs.peer.inbound.peer_peer_callee_auth_user, "usertest")
        self.ngcp.prefs.peer:clean("inbound")
        assertEquals(self.ngcp.prefs.peer.inbound.peer_peer_callee_auth_user, "")
        self.ngcp.prefs.peer.inbound.peer_peer_callee_auth_user = "usertest"
        assertEquals(self.ngcp.prefs.peer.inbound.peer_peer_callee_auth_user, "usertest")
        self.ngcp.prefs.peer:clean()
        assertEquals(self.ngcp.prefs.peer.inbound.peer_peer_callee_auth_user, "")
    end

    function TestNGCP:test_domainpref_clean()
        --print("TestNGCP:test_domainpref_clean")
        assertTrue(self.ngcp.prefs.domain)
        self.ngcp.prefs.domain:clean()
    end
-- class TestNGCP

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF