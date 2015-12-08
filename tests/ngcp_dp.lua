--
-- Copyright 2013 SipWise Team <development@sipwise.com>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This package is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
-- .
-- On Debian systems, the complete text of the GNU General
-- Public License version 3 can be found in "/usr/share/common-licenses/GPL-3".
--
require('luaunit')
local utils = require 'ngcp.utils'
local utable = utils.table
local lemock = require('lemock')
local DPFetch = require 'tests_v.dp_vars'

local srMock = require 'mocks.sr'
sr = srMock:new()

local mc,env,con
local dp_vars = DPFetch:new()

package.loaded.luasql = nil
package.preload['luasql.mysql'] = function ()
    local luasql = {}
    luasql.mysql = function ()
        return env
    end
end
local NGCPConfig = require 'ngcp.config'
local NGCPDomainPrefs = require 'ngcp.dp'

-- luacheck: ignore TestNGCPDomainPrefs
TestNGCPDomainPrefs = {} --class

    function TestNGCPDomainPrefs:setUp()
        mc = lemock.controller()
        env = mc:mock()
        con = mc:mock()
        self.cur = mc:mock()

        self.config = NGCPConfig:new()
        self.config.env = env
        self.config.getDBConnection = function ()
            return con
        end
        self.d = NGCPDomainPrefs:new(self.config)
        dp_vars:reset()
    end

    function TestNGCPDomainPrefs:tearDown()
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

    function TestNGCPDomainPrefs:test_init()
        --print("TestNGCPDomainPrefs:test_init")
        assertEquals(self.d.db_table, "dom_preferences")
    end

    function TestNGCPDomainPrefs:test_caller_load_empty()
        assertTrue(self.d.config)
        assertEquals(self.d:caller_load(), {})
    end

    function TestNGCPDomainPrefs:test_callee_load_empty()
        assertTrue(self.d.config)
        assertEquals(self.d:callee_load(), {})
    end

    function TestNGCPDomainPrefs:get_defaults()
        local keys_expected = {"sst_enable", "sst_refresh_method"}
        local defaults = NGCPConfig.get_defaults(self.d.config, 'dom')

        for k,_ in pairs(defaults) do
            utable.add(keys_expected, k)
        end
        return keys_expected
    end

    function TestNGCPDomainPrefs:test_caller_load()
        assertTrue(self.d.config)
        con:execute("SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:caller_load("192.168.51.56")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>sst_enable)"),"no")
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertItemsEquals(keys, TestNGCPDomainPrefs:get_defaults())
    end

    function TestNGCPDomainPrefs:test_callee_load()
        assertTrue(self.d.config)
        con:execute("SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:callee_load("192.168.51.56")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>sst_enable)"),"no")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertItemsEquals(keys, TestNGCPDomainPrefs:get_defaults())
    end

    function TestNGCPDomainPrefs:test_clean()
        local xavp = NGCPDomainPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>dummy)"),"caller")
        self.d:clean()
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        assertFalse(sr.pv.get("$xavp(domain)"))
    end

    function TestNGCPDomainPrefs:test_callee_clean()
        local callee_xavp = NGCPDomainPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPDomainPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        self.d:clean('callee')
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(callee_dom_prefs=>testid)"))
        assertFalse(sr.pv.get("$xavp(callee_dom_prefs=>foo)"))
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
    end

    function TestNGCPDomainPrefs:test_caller_clean()
        local callee_xavp = NGCPDomainPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPDomainPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        self.d:clean('caller')
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>dummy)"),"caller")
        assertFalse(sr.pv.get("$xavp(caller_dom_prefs=>other)"))
        assertFalse(sr.pv.get("$xavp(caller_dom_prefs=>otherfoo)"))
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
    end

    function TestNGCPDomainPrefs:test_tostring()
        local callee_xavp = NGCPDomainPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPDomainPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(tostring(self.d), 'caller_dom_prefs:{other={1},otherfoo={"foo"},dummy={"caller"}}\ncallee_dom_prefs:{dummy={"callee"},testid={1},foo={"foo"}}\n')
    end
-- class TestNGCPDomainPrefs
--EOF
