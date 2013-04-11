#!/usr/bin/env lua5.1
require('luaunit')
require 'ngcp.utils'
require 'tests_v.up_vars'
require('lemock')

if not sr then
    require 'mocks.sr'
    sr = srMock:new()
else
    argv = {}
end
local mc = nil

UPFetch = {
    __class__ = 'UPFetch',
    _i = 1
}
    function UPFetch:new()
        t = {}
        return setmetatable(t, { __index = UPFetch })
    end

    function UPFetch:val(uuid)
        self._i = self._i + 1
        return up_vars[uuid][self._i-1]
    end

    function UPFetch:reset()
        self._i = 1
    end

TestNGCPUserPrefs = {} --class

    function TestNGCPUserPrefs:setUp()
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

        require 'ngcp.up'

        self.d = NGCPUserPrefs:new(self.config)
        self.up_vars = UPFetch:new()
    end

    function TestNGCPUserPrefs:tearDown()
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

    function TestNGCPUserPrefs:test_caller_load_empty()
        assertTrue(self.d.config)
        assertEquals(self.d:caller_load(), {})
    end

    function TestNGCPUserPrefs:test_callee_load_empty()
        assertTrue(self.d.config)
        assertEquals(self.d:callee_load(), {})
    end

    function TestNGCPUserPrefs:test_init()
        --print("TestNGCPUserPrefs:test_init")
        assertEquals(self.d.db_table, "usr_preferences")
    end

    function TestNGCPUserPrefs:test_caller_load()
        assertTrue(self.d.config)
        self.config:getDBConnection() ;mc :returns(self.con)
        self.con:execute("SELECT * FROM usr_preferences WHERE uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        local keys = self.d:caller_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>account_id)"),2)
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>cli)"),"4311001")
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>cc)"),"43")
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>ac)"),"1")
        assertItemsEquals(keys, {"account_id", "cli", "cc", "ac"})
    end

    function TestNGCPUserPrefs:test_callee_load()
        assertTrue(self.d.config)
        self.config:getDBConnection() ;mc :returns(self.con)
        self.con:execute("SELECT * FROM usr_preferences WHERE uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        local keys = self.d:callee_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>account_id)"),2)
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>cli)"),"4311001")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>cc)"),"43")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>ac)"),"1")
        assertItemsEquals(keys, {"account_id", "cli", "cc", "ac"})
    end
    
    function TestNGCPUserPrefs:test_clean()
        local xavp = NGCPUserPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        self.d:clean()
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>dummy)"), "callee")
    end

    function TestNGCPUserPrefs:test_callee_clean()
        local callee_xavp = NGCPUserPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPUserPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
        self.d:clean('callee')
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(callee_usr_prefs=>testid)"))
        assertFalse(sr.pv.get("$xavp(callee_usr_prefs=>foo)"))
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
    end

    function TestNGCPUserPrefs:test_caller_clean()
        local callee_xavp = NGCPUserPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPUserPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
        self.d:clean('caller')
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assertFalse(sr.pv.get("$xavp(caller_usr_prefs=>other)"))
        assertFalse(sr.pv.get("$xavp(caller_usr_prefs=>otherfoo)"))
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
    end
-- class TestNGCPUserPrefs
--EOF