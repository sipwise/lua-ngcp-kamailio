#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
require 'ngcp.utils'

sr = srMock:new()

local mc = lemock.controller()
local mysql = mc:mock()
local env   = mc:mock()
local con   = mc:mock()
local cur   = mc:mock()

package.loaded.luasql = nil
package.preload['luasql.mysql'] = function ()
    luasql = {}
    luasql.mysql = mysql
    return mysql
end

require 'ngcp.ngcp'

TestNGCP = {} --class

    function TestNGCP:setUp()
        self.ngcp = NGCP:new()
    end

    function TestNGCP:test_config()
        assertTrue(self.ngcp.config)
    end

    function TestNGCP:test_connection()
        assertTrue(self.ngcp.config)
        local c = self.ngcp.config
        luasql.mysql() ;mc :returns(env)
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(con)

        mc:replay()
        c:getDBConnection()
        mc:verify()
        assertTrue(self.ngcp.config)
    end

    function TestNGCP:test_prefs_init()
        --print("TestNGCP:test_prefs_init")
        assertTrue(self.ngcp)
        assertTrue(self.ngcp.prefs)
        assertTrue(self.ngcp.prefs.peer)
        assertTrue(self.ngcp.prefs.user)
        assertTrue(self.ngcp.prefs.domain)
        assertTrue(self.ngcp.prefs.real)
    end

-- class TestNGCP

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF