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
        self.d:caller_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        mc:verify()

        assertTrue(self.d.xavp)
        assertEquals(self.d.xavp("cli"),"4311001")
        assertEquals(self.d.xavp("cc"),"43")
        assertEquals(self.d.xavp("ac"),"1")
        assertEquals(self.d.xavp("cli"),"4311001")
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
        self.d:callee_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        mc:verify()

        assertTrue(self.d.xavp)
        assertEquals(self.d.xavp("cli"),"4311001")
        assertEquals(self.d.xavp("cc"),"43")
        assertEquals(self.d.xavp("ac"),"1")
        assertEquals(self.d.xavp("cli"),"4311001")
        assertIsNil(self.d.xavp("error_key"))
    end
-- class TestNGCPUserPrefs

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF