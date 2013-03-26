#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
require 'utils'

sr = srMock:new()

local mc = lemock.controller()
local config = mc:mock()
local mysql = mc:mock()
local env = mc:mock()
local con = mc:mock()
local cur = mc:mock()

package.loaded.luasql = nil
package.preload['luasql.mysql'] = function ()
    luasql = {}
    luasql.mysql = mysql
    return mysql
end

require 'ngcp.pp'
require 'tests.pp_vars'

TestNGCPPeerPrefs = {} --class

    function TestNGCPPeerPrefs:setUp()
        --print("TestNGCPPeerPrefs:setUp")
        self.d = NGCPPeerPrefs:new(config)
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
        config:getDBConnection() ;mc :returns(con)
        con:execute("SELECT * FROM peer_preferences WHERE uuid = '2'")  ;mc :returns(cur)
        cur:fetch(mc.ANYARGS)    ;mc :returns(pp_vars["p_2"])
        cur:close()
        con:close()

        mc:replay()
        self.d:caller_load("2")
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