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
require 'tests_v.dp_vars'
require 'tests_v.pp_vars'
require 'tests_v.up_vars'

if not sr then
    require 'mocks.sr'
    sr = srMock:new()
else
    argv = {}
end

local mc,env

TestNGCP = {} --class

    function TestNGCP:setUp()
        mc = lemock.controller()
        env = mc:mock()
        self.con  = mc:mock()
        self.cur  = mc:mock()

        package.loaded.luasql = nil
        package.preload['luasql.mysql'] = function ()
            luasql = {}
            luasql.mysql = function ()
                return env
            end
        end

        require 'ngcp.ngcp'

        self.ngcp = NGCP:new()
        self.dp_vars = DPFetch:new()
        self.pp_vars = PPFetch:new()
        self.up_vars = UPFetch:new()
    end

    function TestNGCP:tearDown()
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

    function TestNGCP:test_config()
        assertTrue(self.ngcp.config)
    end

    function TestNGCP:test_config_get_defaults_all()
        local defaults = NGCPConfig.get_defaults(self.ngcp.config, 'peer')
        assertItemsEquals(defaults, self.ngcp.config.default.peer)
    end

    function TestNGCP:test_config_get_defaults_real()
        local defaults = NGCPConfig.get_defaults(self.ngcp.config, 'usr')
        local usr_defaults = table.deepcopy(self.ngcp.config.default.usr)
        assertItemsEquals(defaults, usr_defaults)
    end

    function TestNGCP:test_prefs_init()
        sr.log("dbg", "TestNGCP:test_prefs_init")
        assertTrue(self.ngcp)
        assertTrue(self.ngcp.prefs)
        assertTrue(self.ngcp.prefs.peer)
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        assertTrue(self.ngcp.prefs.usr)
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
        assertTrue(self.ngcp.prefs.dom)
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        assertTrue(self.ngcp.prefs.real)
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
    end

    function TestNGCP:test_log_pref()
        self.ngcp:log_pref()
        assertError(self.ngcp.log_pref, self.ngcp, "dbg", "foo_var")
    end

    function TestNGCP:test_log_pref_info()
        self.ngcp:log_pref("info")
    end

    function TestNGCP:test_log_pref_peer()
        self.ngcp:log_pref("dbg", "peer")
    end

    function TestNGCP:test_caller_usr_load_empty()
        assertEquals(self.ngcp:caller_usr_load(), {})
    end

    function TestNGCP:test_caller_usr_load_empty_dom()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute("SELECT * FROM usr_preferences WHERE uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        local keys = self.ngcp:caller_usr_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>account_id)"), 2)
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>cli)"), "4311001")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>cc)"), "43")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>ac)"), "1")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>no_nat_sipping)"), "no")
    end

    function TestNGCP:test_caller_usr_load_empty_usr()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute("SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        local keys = self.ngcp:caller_usr_load(nil, "192.168.51.56")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>dummy)"), "caller")
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        --- the default is on real and dom NOT in usr
        assertIsNil(sr.pv.get("$xavp(caller_usr_prefs=>sst_enable)"))
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>sst_enable)"), "no")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>sst_enable)"), "no")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertIsNil(sr.pv.get("$xavp(caller_real_prefs=>force_outbound_calls_to_peer)"))
        assertIsNil(sr.pv.get("$xavp(caller_dom_prefs=>force_outbound_calls_to_peer)"))
    end

    function TestNGCP:test_caller_usr_load()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute("SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute("SELECT * FROM usr_preferences WHERE uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        local keys = self.ngcp:caller_usr_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c", "192.168.51.56")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        --- the default is on real NOT in usr
        assertIsNil(sr.pv.get("$xavp(caller_usr_prefs=>sst_enable)"))
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>sst_enable)"), "no")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>force_outbound_calls_to_peer)"), 1)
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>force_outbound_calls_to_peer)"), 1)
    end

    function TestNGCP:test_callee_usr_load_empty()
        assertEquals(self.ngcp:callee_usr_load(), {})
    end

    function TestNGCP:test_callee_usr_load()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute("SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute("SELECT * FROM usr_preferences WHERE uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        local keys = self.ngcp:callee_usr_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c", "192.168.51.56")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>dummy)"), "callee")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>sst_enable)"), "no")
        --- the default is on real NOT in usr
        assertIsNil(sr.pv.get("$xavp(callee_usr_prefs=>sst_enable)"))
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>sst_enable)"), "no")
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
    end

    function TestNGCP:test_caller_peer_load_empty()
        assertEquals(self.ngcp:caller_peer_load(), {})
    end

    function TestNGCP:test_caller_peer_load()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute(mc.ANYARGS)  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.pp_vars:val("p_2")) --sst_enable: "no"
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.pp_vars:val("p_2")) --sst_refresh_method: "UPDATE_FALLBACK_INVITE"
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        local keys = self.ngcp:caller_peer_load("2")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"), "caller")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>sst_enable)"), "no")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
    end

    function TestNGCP:test_callee_peer_load_empty()
        assertEquals(self.ngcp:callee_peer_load(), {})
    end

    function TestNGCP:test_callee_peer_load()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute(mc.ANYARGS)  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.pp_vars:val("p_2")) --sst_enable: "no"
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(self.pp_vars:val("p_2")) --sst_refresh_method: "UPDATE_FALLBACK_INVITE"
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        local keys = self.ngcp:callee_peer_load("2")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"), "callee")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>sst_enable)"), "no")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
    end

    function TestNGCP:test_clean()
        local xavp = NGCPXAvp:new('callee','usr_prefs')
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        self.ngcp:clean()
        assertEquals(sr.pv.get("$avp(s:callee_cfb)"),nil)
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
        assertIsNil(sr.pv.get("$xavp(user)"))
    end

    function TestNGCP:test_clean_caller_groups()
        local groups = {"peer", "usr", "dom", "real"}
        local _,v

        for _,v in pairs(groups) do
            xavp = self.ngcp.prefs[v]:xavp("caller")
            xavp(string.format("test_%s", v), v)
            assertEquals(sr.pv.get(string.format("$xavp(caller_%s_prefs=>test_%s)", v, v)), v)
            assertEquals(sr.pv.get(string.format("$xavp(caller_%s_prefs=>dummy)", v)), "caller")
            self.ngcp:clean("caller", v)
            assertEquals(sr.pv.get(string.format("$xavp(caller_%s_prefs=>dummy)", v)), "caller")
        end
        assertError(self.ngcp.clean, self.ngcp, "caller", "whatever")
    end


    function TestNGCP:test_clean_callee_groups()
        local groups = {"peer", "usr", "dom", "real"}
        local _,v, xavp

        for _,v in pairs(groups) do
            xavp = self.ngcp.prefs[v]:xavp("callee")
            xavp(string.format("test_%s", v), v)
            assertEquals(sr.pv.get(string.format("$xavp(callee_%s_prefs=>test_%s)", v, v)), v)
            assertEquals(sr.pv.get(string.format("$xavp(callee_%s_prefs=>dummy)", v)), "callee")
            self.ngcp:clean("callee", v)
            assertEquals(sr.pv.get(string.format("$xavp(callee_%s_prefs=>dummy)", v)), "callee")
        end
        assertError(self.ngcp.clean, self.ngcp, "callee", "whatever")
    end

    function TestNGCP:test_callee_clean()
        local callee_xavp = NGCPDomainPrefs:xavp('callee')
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        callee_xavp("testid",1)
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>testid)"),1)
        callee_xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>foo)"),"foo")
        local caller_xavp = NGCPDomainPrefs:xavp('caller')
        caller_xavp("other",1)
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        self.ngcp:clean('callee')
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>dummy)"),'caller')
        assertIsNil(sr.pv.get("$xavp(callee_dom_prefs=>testid)"))
        assertIsNil(sr.pv.get("$xavp(callee_dom_prefs=>foo)"))
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>dummy)"), "callee")
    end

    function TestNGCP:test_caller_clean()
        local callee_xavp = NGCPXAvp:new('callee','peer_prefs')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPXAvp:new('caller','peer_prefs')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        self.ngcp:clean('caller')
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assertFalse(sr.pv.get("$xavp(caller_peer_prefs=>other)"))
        assertFalse(sr.pv.get("$xavp(caller_peer_prefs=>otherfoo)"))
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
    end

    function TestNGCP:test_tostring()
        assertEquals(tostring(self.ngcp), 'caller_usr_prefs:{dummy="caller"}\ncallee_usr_prefs:{dummy="callee"}\ncaller_real_prefs:{dummy="caller"}\ncallee_real_prefs:{dummy="callee"}\ncaller_peer_prefs:{dummy="caller"}\ncallee_peer_prefs:{dummy="callee"}\ncaller_dom_prefs:{dummy="caller"}\ncallee_dom_prefs:{dummy="callee"}\n')
    end
-- class TestNGCP
--EOF