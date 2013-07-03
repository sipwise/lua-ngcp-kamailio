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
require('lemock')
require 'ngcp.utils'
require 'tests_v.pp_vars'

if not sr then
    require 'mocks.sr'
    sr = srMock:new()
else
    argv = {}
end
local mc,env,con

TestNGCPPeerPrefs = {} --class

    function TestNGCPPeerPrefs:setUp()
        mc = lemock.controller()
        env = mc:mock()
        con = mc:mock()
        self.cur = mc:mock()

        package.loaded.luasql = nil
        package.preload['luasql.mysql'] = function ()
            luasql = {}
            luasql.mysql = function ()
                return env
            end
        end

        require 'ngcp.dp'

        self.config = NGCPConfig:new()
        self.config.getDBConnection = function ()
            return con
        end

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

    function TestNGCPPeerPrefs:get_defaults(level)
        local keys_expected = {"sst_enable", "sst_refresh_method"}
        local defaults = self.d.config:get_defaults('peer')
        local k,v

        for k,v in pairs(defaults) do
            table.add(keys_expected, k)
            assertEquals(sr.pv.get("$xavp("..level.."_peer_prefs=>"..k..")"), v)
        end
        return keys_expected
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
        con:execute("SELECT * FROM peer_preferences WHERE uuid = '2'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.pp_vars:val("p_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.pp_vars:val("p_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        con:close()

        mc:replay()
        local keys = self.d:caller_load("2")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"), "caller")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>sst_enable)"),"no")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertItemsEquals(keys, TestNGCPPeerPrefs:get_defaults("caller"))
    end

    function TestNGCPPeerPrefs:test_callee_load()
        assertTrue(self.d.config)
        con:execute("SELECT * FROM peer_preferences WHERE uuid = '2'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.pp_vars:val("p_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.pp_vars:val("p_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        con:close()

        mc:replay()
        local keys = self.d:callee_load("2")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"), "callee")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>sst_enable)"),"no")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertItemsEquals(keys, TestNGCPPeerPrefs:get_defaults("callee"))
    end

    function TestNGCPPeerPrefs:test_clean()
        local xavp = NGCPPeerPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        self.d:clean()
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
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
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
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
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assertFalse(sr.pv.get("$xavp(caller_peer_prefs=>other)"))
        assertFalse(sr.pv.get("$xavp(caller_peer_prefs=>otherfoo)"))
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
    end

    function TestNGCPPeerPrefs:test_tostring()
        local callee_xavp = NGCPPeerPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPPeerPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(tostring(self.d), 'caller_peer_prefs:{other=1,otherfoo="foo",dummy="caller"}\ncallee_peer_prefs:{dummy="callee",testid=1,foo="foo"}\n')
    end
-- class TestNGCPPeerPrefs
--EOF