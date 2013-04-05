#!/usr/bin/env lua5.1
require('luaunit')
require 'ngcp.utils'
require 'tests_v.pp_vars'
require('lemock')

if not sr then
    require 'mocks.sr'
    sr = srMock:new()
else
    argv = {}
end
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

    function TestNGCPPeerPrefs:test_init()
        --print("TestNGCPPeerPrefs:test_init")
        assertEquals(self.d.db_table, "peer_preferences")
    end

    function TestNGCPPeerPrefs:test_caller_load_empty()
        assertTrue(self.d.config)
        assertEquals(self.d:caller_load(), {})
    end

    function TestNGCPPeerPrefs:test_callee_load_empty()
        assertTrue(self.d.config)
        assertEquals(self.d:callee_load(), {})
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
        local keys = self.d:caller_load("2")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"), "caller")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>sst_enable)"),"no")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
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
        local keys = self.d:callee_load("2")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"), "callee")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>sst_enable)"),"no")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
    end

    function TestNGCPPeerPrefs:test_clean()
        local xavp = NGCPPeerPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assertFalse(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"))
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        self.d:clean()
        assertFalse(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"))
        assertFalse(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"))
        assertFalse(sr.pv.get("$xavp(peer)"))
    end

    function TestNGCPPeerPrefs:test_callee_clean()
        local callee_xavp = NGCPPeerPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPPeerPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        self.d:clean('callee')
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(callee_peer_prefs=>testid)"))
        assertFalse(sr.pv.get("$xavp(callee_peer_prefs=>foo)"))
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>otherfoo)"),"foo")
        assertFalse(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"))
    end

    function TestNGCPPeerPrefs:test_caller_clean()
        local callee_xavp = NGCPPeerPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPPeerPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        self.d:clean('caller')
        assertFalse(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"))
        assertFalse(sr.pv.get("$xavp(caller_peer_prefs=>other)"))
        assertFalse(sr.pv.get("$xavp(caller_peer_prefs=>otherfoo)"))
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
    end
-- class TestNGCPPeerPrefs
--EOF