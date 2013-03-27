#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
require 'ngcp.utils'
require 'tests_v.dp_vars'

sr = srMock:new()
local mc = nil

DPFetch = {
    __class__ = 'DPFetch',
    _i = 1
}
    function DPFetch:new()
        t = {}
        return setmetatable(t, { __index = DPFetch })
    end

    function DPFetch:val(uuid)
        self._i = self._i + 1
        return dp_vars[uuid][self._i-1]
    end

    function DPFetch:reset()
        self._i = 1
    end

TestNGCPDomainPrefs = {} --class

    function TestNGCPDomainPrefs:setUp()
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

        require 'ngcp.dp'

        self.d = NGCPDomainPrefs:new(self.config)
        self.dp_vars = DPFetch:new()
    end

    function TestNGCPDomainPrefs:tearDown()
        sr.pv.vars = {}
    end

    function TestNGCPDomainPrefs:test_init()
        --print("TestNGCPDomainPrefs:test_init")
        assertEquals(self.d.db_table, "dom_preferences")
    end

    function TestNGCPDomainPrefs:test_caller_load()
        assertTrue(self.d.config)
        self.config:getDBConnection() ;mc :returns(self.con)
        self.con:execute("SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        self.d:caller_load("192.168.51.56")
        mc:verify()

        assertTrue(self.d.xavp)
        assertEquals(self.d.xavp("sst_enable"),"no")
        assertEquals(sr.pv.vars["$xavp(domain[0]=>dummy)"], "")
        assertEquals(self.d.xavp("dummy"),"")
        assertEquals(sr.pv.vars["$xavp(domain[0]=>sst_enable)"],"no")
        assertEquals(sr.pv.vars["$xavp(domain[0]=>sst_refresh_method)"], "UPDATE_FALLBACK_INVITE")
        assertIsNil(self.d.xavp("error_key"))
    end

    function TestNGCPDomainPrefs:test_callee_load()
        assertTrue(self.d.config)
        self.config:getDBConnection() ;mc :returns(self.con)
        self.con:execute("SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        self.d:callee_load("192.168.51.56")
        mc:verify()

        assertTrue(self.d.xavp)
        assertEquals(self.d.xavp("sst_enable"),"no")
        --print(table.tostring(sr.pv.vars))
        assertFalse(sr.pv.vars["$xavp(domain[1]=>dummy)"])
        assertEquals(sr.pv.vars["$xavp(domain[1]=>sst_enable)"],"no")
        assertEquals(sr.pv.vars["$xavp(domain[1]=>sst_refresh_method)"], "UPDATE_FALLBACK_INVITE")
        assertIsNil(self.d.xavp("error_key"))
    end
-- class TestNGCPDomainPrefs

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF