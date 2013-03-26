#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
require 'ngcp.utils'
require 'tests_v.pp_vars'

sr = srMock:new()
local mc = nil

TestNGCPPeerPrefs = {} --class

    function TestNGCPPeerPrefs:setUp()
        mc = lemock.controller()
        self.config = mc:mock()
        self.mysql = mc:mock()
        self.env = mc:mock()
        self.con = mc:mock()
        self.cur = mc:mock()

        package.loaded.luasql = nil
        package.preload['luasql.mysql'] = function ()
            luasql = {}
            luasql.mysql = mysql
            return mysql
        end

        require 'ngcp.pp'

        self.d = NGCPPeerPrefs:new(self.config)
    end

    function TestNGCPPeerPrefs:tearDown()
        sr.pv.vars = {}
    end

    function TestNGCPPeerPrefs:test_init()
        --print("TestNGCPPeerPrefs:test_init")
        assertEquals(self.d.db_table, "peer_preferences")
    end

    function TestNGCPPeerPrefs:test_caller_load()
        assertTrue(self.d.config)
        self.config:getDBConnection() ;mc :returns(self.con)
        self.con:execute("SELECT * FROM peer_preferences WHERE uuid = '2'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pp_vars["p_2"])
        self.cur:close()
        self.con:close()

        mc:replay()
        self.d:caller_load("2")
        mc:verify()

        assertTrue(self.d.xavp)
        assertEquals(self.d.xavp("sst_enable"),"no")
        assertFalse(self.d.xavp("cc"),"43")
        assertEquals(self.d.xavp("use_rtpproxy"),"ice_strip_candidates")
        assertEquals(self.d.xavp("rewrite_caller_in_dpid"),1)
    end

    function TestNGCPPeerPrefs:test_callee_load()
        assertTrue(self.d.config)
        self.config:getDBConnection() ;mc :returns(self.con)
        self.con:execute("SELECT * FROM peer_preferences WHERE uuid = '2'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pp_vars["p_2"])
        self.cur:close()
        self.con:close()

        mc:replay()
        self.d:callee_load("2")
        mc:verify()

        assertTrue(self.d.xavp)
        assertEquals(self.d.xavp("sst_enable"),"no")
        assertFalse(self.d.xavp("cc"),"43")
        assertEquals(self.d.xavp("use_rtpproxy"),"ice_strip_candidates")
        assertEquals(self.d.xavp("rewrite_caller_in_dpid"),1)
    end
-- class TestNGCPPeerPrefs

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF