#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
require 'ngcp.utils'

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

require 'ngcp.up'
require 'tests_v.up_vars'

TestNGCPUserPrefs = {} --class

    function TestNGCPUserPrefs:setUp()
        --print("TestNGCPUserPrefs:setUp")
        self.d = NGCPUserPrefs:new(config)
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
        config:getDBConnection() ;mc :returns(con)
        con:execute("SELECT * FROM usr_preferences WHERE uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(cur)
        cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars["ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"])
        cur:close()
        con:close()

        mc:replay()
        self.d:caller_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        mc:verify()

        assertTrue(self.d.xavp)
        assertEquals(self.d.xavp("cli"),"4311001")
        assertEquals(self.d.xavp("cc"),"43")
        assertEquals(self.d.xavp("ac"),"1")
        assertEquals(self.d.xavp("cli"),"4311001")
    end
-- class TestNGCPUserPrefs

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF