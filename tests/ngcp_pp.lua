#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
require 'ngcp.utils'
require 'tests_v.pp_vars'

sr = srMock:new()
local mc = nil

PPFetch = {
    __class__ = 'PPFetch',
    _i = 1
}
    function PPFetch:new()
        t = {}
        return setmetatable(t, { __index = PPFetch })
    end

    function PPFetch:val(uuid)
        self._i = self._i + 1
        return pp_vars[uuid][self._i-1]
    end

    function PPFetch:reset()
        self._i = 1
    end

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
        self.pp_vars = PPFetch:new()
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
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.pp_vars:val("p_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.pp_vars:val("p_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        self.d:caller_load("2")
        mc:verify()

        assertTrue(self.d.xavp)
        assertEquals(self.d.xavp("sst_enable"),"no")
        assertEquals(sr.pv.get("$xavp(domain[0]=>dummy)"), "caller")
        assertEquals(self.d.xavp("dummy"),"caller")
        assertEquals(sr.pv.get("$xavp(domain[0]=>sst_enable)"),"no")
        assertEquals(sr.pv.get("$xavp(domain[0]=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertIsNil(self.d.xavp("error_key"))
    end

    function TestNGCPPeerPrefs:test_callee_load()
        assertTrue(self.d.config)
        self.config:getDBConnection() ;mc :returns(self.con)
        self.con:execute("SELECT * FROM peer_preferences WHERE uuid = '2'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.pp_vars:val("p_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.pp_vars:val("p_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        self.d:callee_load("2")
        mc:verify()

        assertTrue(self.d.xavp)
        assertEquals(self.d.xavp("sst_enable"),"no")
        --print(table.tostring(sr.pv.vars))
        assertEquals(sr.pv.get("$xavp(domain[1]=>dummy)"), "callee")
        assertEquals(sr.pv.get("$xavp(domain[1]=>sst_enable)"),"no")
        assertEquals(sr.pv.get("$xavp(domain[1]=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertIsNil(self.d.xavp("error_key"))
    end

    function TestNGCPPeerPrefs:test_clean()
        local xavp = NGCPXAvp:new('callee','peer',{})
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(peer[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(peer[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(peer[0]=>dummy)"),"caller")
        self.d:clean()
        assertFalse(sr.pv.get("$xavp(peer[0]=>dummy)"))
        assertFalse(sr.pv.get("$xavp(peer[1]=>dummy)"))
        assertFalse(sr.pv.get("$xavp(peer)"))
    end

    function TestNGCPPeerPrefs:test_callee_clean()
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
        self.d:clean('callee')
        assertEquals(sr.pv.get("$xavp(peer[0]=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(peer[1]=>testid)"))
        assertFalse(sr.pv.get("$xavp(peer[1]=>foo)"))
        assertEquals(sr.pv.get("$xavp(peer[0]=>other)"),1)
        assertEquals(sr.pv.get("$xavp(peer[0]=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(peer[1]=>dummy)"),"callee")
    end

    function TestNGCPPeerPrefs:test_caller_clean()
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
        self.d:clean('caller')
        assertEquals(sr.pv.get("$xavp(peer[0]=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(peer[0]=>other)"))
        assertFalse(sr.pv.get("$xavp(peer[0]=>otherfoo)"))
        assertEquals(sr.pv.get("$xavp(peer[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(peer[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(peer[1]=>dummy)"),"callee")
    end
-- class TestNGCPPeerPrefs

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF