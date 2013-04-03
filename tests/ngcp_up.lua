#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
require 'ngcp.utils'
require 'tests_v.up_vars'

sr = srMock:new()
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
        sr.pv.vars = {}
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

        assertEquals(sr.pv.get("$xavp(user[0]=>account_id)"),2)
        assertEquals(sr.pv.get("$xavp(user[0]=>cli)"),"4311001")
        assertEquals(sr.pv.get("$xavp(user[0]=>cc)"),"43")
        assertEquals(sr.pv.get("$xavp(user[0]=>ac)"),"1")
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

        assertEquals(sr.pv.get("$xavp(user[1]=>account_id)"),2)
        assertEquals(sr.pv.get("$xavp(user[1]=>cli)"),"4311001")
        assertEquals(sr.pv.get("$xavp(user[1]=>cc)"),"43")
        assertEquals(sr.pv.get("$xavp(user[1]=>ac)"),"1")
        assertItemsEquals(keys, {"account_id", "cli", "cc", "ac"})
    end
    
    function TestNGCPUserPrefs:test_clean()
        local xavp = NGCPXAvp:new('callee','user',{})
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(user[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(user[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(user[0]=>dummy)"),"caller")
        self.d:clean()
        assertFalse(sr.pv.get("$xavp(user[0]=>dummy)"))
        assertFalse(sr.pv.get("$xavp(user[1]=>dummy)"))
        assertFalse(sr.pv.get("$xavp(user)"))
    end

    function TestNGCPUserPrefs:test_callee_clean()
        local callee_xavp = NGCPXAvp:new('callee','user',{})
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPXAvp:new('caller','user',{})
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(user[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(user[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(user[0]=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(user[0]=>other)"),1)
        assertEquals(sr.pv.get("$xavp(user[0]=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(user[1]=>dummy)"),"callee")
        self.d:clean('callee')
        assertEquals(sr.pv.get("$xavp(user[0]=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(user[1]=>testid)"))
        assertFalse(sr.pv.get("$xavp(user[1]=>foo)"))
        assertEquals(sr.pv.get("$xavp(user[0]=>other)"),1)
        assertEquals(sr.pv.get("$xavp(user[0]=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(user[1]=>dummy)"),"callee")
    end

    function TestNGCPUserPrefs:test_caller_clean()
        local callee_xavp = NGCPXAvp:new('callee','user',{})
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPXAvp:new('caller','user',{})
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(user[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(user[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(user[0]=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(user[0]=>other)"),1)
        assertEquals(sr.pv.get("$xavp(user[0]=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(user[1]=>dummy)"),"callee")
        self.d:clean('caller')
        assertEquals(sr.pv.get("$xavp(user[0]=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(user[0]=>other)"))
        assertFalse(sr.pv.get("$xavp(user[0]=>otherfoo)"))
        assertEquals(sr.pv.get("$xavp(user[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(user[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(user[1]=>dummy)"),"callee")
    end
-- class TestNGCPUserPrefs

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF