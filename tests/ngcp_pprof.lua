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
local lemock = require('lemock')
local PProfFetch = require 'tests_v.pprof_vars'

local srMock = require 'mocks.sr'
sr = srMock:new()

local mc,env,con
local pprof_vars = PProfFetch:new()

package.loaded.luasql = nil
package.preload['luasql.mysql'] = function ()
    local luasql = {}
    luasql.mysql = function ()
        return env
    end
end
local NGCPConfig = require 'ngcp.config'
local NGCPProfilePrefs = require 'ngcp.pprof'
-- luacheck: ignore TestNGCPProfilePrefs
TestNGCPProfilePrefs = {} --class

    function TestNGCPProfilePrefs:setUp()
        mc = lemock.controller()
        env = mc:mock()
        con = mc:mock()
        self.cur = mc:mock()

        package.loaded.luasql = nil
        package.preload['luasql.mysql'] = function ()
            local luasql = {}
            luasql.mysql = function ()
                return env
            end
        end

        self.config = NGCPConfig:new()
        self.config.env = env
        self.config.getDBConnection = function ()
            return con
        end

        self.d = NGCPProfilePrefs:new(self.config)
        pprof_vars:reset()
    end

    function TestNGCPProfilePrefs:tearDown()
        sr.pv.unset("$xavp(caller_dom_prefs)")
        sr.pv.unset("$xavp(callee_dom_prefs)")
        sr.pv.unset("$xavp(caller_prof_prefs)")
        sr.pv.unset("$xavp(callee_prof_prefs)")
        sr.pv.unset("$xavp(caller_prof_prefs)")
        sr.pv.unset("$xavp(callee_prof_prefs)")
        sr.pv.unset("$xavp(caller_usr_prefs)")
        sr.pv.unset("$xavp(callee_usr_prefs)")
        sr.pv.unset("$xavp(caller_real_prefs)")
        sr.pv.unset("$xavp(callee_real_prefs)")
        sr.log("info", "---TestNGCPProfilePrefs::cleaned---")
    end

    function TestNGCPProfilePrefs:test_init()
        --print("TestNGCPProfilePrefs:test_init")
        assertEquals(self.d.db_table, "prof_preferences")
    end

    function TestNGCPProfilePrefs:test_caller_load_empty()
        assertTrue(self.d.config)
        assertEquals(self.d:caller_load(), {})
    end

    function TestNGCPProfilePrefs:test_callee_load_empty()
        assertTrue(self.d.config)
        assertEquals(self.d:callee_load(), {})
    end

    function TestNGCPProfilePrefs:test_caller_load()
        assertTrue(self.d.config)
        con:execute("SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN prof_preferences AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = 'ah736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pprof_vars:val("prof_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pprof_vars:val("prof_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pprof_vars:val("prof_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:caller_load("ah736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        mc:verify()

        assertItemsEquals(keys, {"sst_enable", "sst_refresh_method", "outbound_from_user"})
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>dummy)"), "caller")
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>sst_enable)"),"yes")
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>outbound_from_user)"), "upn")
    end

    function TestNGCPProfilePrefs:test_callee_load()
        assertTrue(self.d.config)
        con:execute("SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN prof_preferences AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = 'ah736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pprof_vars:val("prof_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pprof_vars:val("prof_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pprof_vars:val("prof_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:callee_load("ah736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        mc:verify()

        assertItemsEquals(keys, {"sst_enable", "sst_refresh_method", "outbound_from_user"})
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>dummy)"), "callee")
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>sst_enable)"),"yes")
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>outbound_from_user)"), "upn")
    end

    function TestNGCPProfilePrefs:test_clean()
        local xavp = NGCPProfilePrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>dummy)"),"callee")
        self.d:clean()
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>dummy)"),"callee")
        assertFalse(sr.pv.get("$xavp(prof)"))
    end

    function TestNGCPProfilePrefs:test_callee_clean()
        local callee_xavp = NGCPProfilePrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPProfilePrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>dummy)"),"callee")
        self.d:clean('callee')
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(callee_prof_prefs=>testid)"))
        assertFalse(sr.pv.get("$xavp(callee_prof_prefs=>foo)"))
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>dummy)"),"callee")
    end

    function TestNGCPProfilePrefs:test_caller_clean()
        local callee_xavp = NGCPProfilePrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPProfilePrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>dummy)"),"callee")
        self.d:clean('caller')
        assertEquals(sr.pv.get("$xavp(caller_prof_prefs=>dummy)"),"caller")
        assertFalse(sr.pv.get("$xavp(caller_prof_prefs=>other)"))
        assertFalse(sr.pv.get("$xavp(caller_prof_prefs=>otherfoo)"))
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_prof_prefs=>dummy)"),"callee")
    end

    function TestNGCPProfilePrefs:test_tostring()
        local callee_xavp = NGCPProfilePrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPProfilePrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(tostring(self.d), 'caller_prof_prefs:{other={1},otherfoo={"foo"},dummy={"caller"}}\ncallee_prof_prefs:{dummy={"callee"},testid={1},foo={"foo"}}\n')
    end
-- class TestNGCPProfilePrefs
--EOF
