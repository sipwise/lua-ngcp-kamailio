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

require 'ngcp.dp'
require 'tests.dp_vars'

TestNGCPDomainPrefs = {} --class

    function TestNGCPDomainPrefs:setUp()
        --print("TestNGCPDomainPrefs:setUp")
        self.d = NGCPDomainPrefs:new(config)
    end

    function TestNGCPDomainPrefs:test_init()
        --print("TestNGCPDomainPrefs:test_init")
        assertEquals(self.d.db_table, "dom_preferences")
    end

    function TestNGCPDomainPrefs:test_caller_load()
        assertTrue(self.d.config)
        config:getDBConnection() ;mc :returns(con)
        con:execute("SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'")  ;mc :returns(cur)
        cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars["d_192_168_51_56"])
        cur:close()
        con:close()

        mc:replay()
        self.d:caller_load("192.168.51.56")
        mc:verify()

        assertTrue(self.d.xavp)
        assertEquals(self.d.xavp("sst_enable"),"no")
        assertFalse(self.d.xavp("error_key"))
    end
-- class TestNGCPDomainPrefs

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF