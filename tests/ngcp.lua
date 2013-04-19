#!/usr/bin/env lua5.1
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
        sr.log("dbg", "TestNGCP:setUp")
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
        sr.log("dbg", "TestNGCP:tearDown")
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

    function TestNGCP:test_caller_usr_load_empty()
        assertEquals(self.ngcp:caller_usr_load(), {})
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
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        local keys = self.ngcp:caller_usr_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c", "192.168.51.56")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>sst_enable)"), "no")
        assertEquals(sr.pv.get("$avp(caller_sst_enable)"), "no")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertEquals(sr.pv.get("$avp(caller_sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
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
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        self.con:close()

        mc:replay()
        local keys = self.ngcp:callee_usr_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c", "192.168.51.56")
        mc:verify()

        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>dummy)"), "callee")
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>sst_enable)"), "no")
        assertEquals(sr.pv.get("$avp(callee_sst_enable)"), "no")
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertEquals(sr.pv.get("$avp(callee_sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
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
        assertEquals(sr.pv.get("$avp(peer_callee_sst_enable)"), "no")
        assertEquals(sr.pv.get("$xavp(caller_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertEquals(sr.pv.get("$avp(peer_callee_sst_refresh_refresh_method)"), "UPDATE_FALLBACK_INVITE")
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
        assertEquals(sr.pv.get("$avp(peer_caller_sst_enable)"), "no")
        assertEquals(sr.pv.get("$xavp(callee_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertEquals(sr.pv.get("$avp(peer_caller_sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
    end

    function TestNGCP:test_clean()
        local xavp = NGCPXAvp:new('callee','usr_prefs')
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        self.ngcp:clean()
        assertEquals(sr.pv.get("$avp(s:callee_outbound_from_display)"),nil)
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
        assertFalse(sr.pv.get("$xavp(user)"))
    end

    function TestNGCP:test_clean_vars()
        local avp = NGCPAvp:new('callee_outbound_from_display')
        avp("foofighters")
        assertEquals(sr.pv.get("$avp(s:callee_outbound_from_display)"),"foofighters")
        self.ngcp:clean()
        assertEquals(sr.pv.get("$avp(s:callee_outbound_from_display)"),nil)
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

    function TestNGCP:test_clean_caller_groups_vars()
        local groups = {"peer", "usr", "dom", "real"}
        local _,v
        local avp = NGCPAvp:new('callee_outbound_from_display')
        avp("foofighters")
        assertEquals(sr.pv.get("$avp(s:callee_outbound_from_display)"),"foofighters")

        for _,v in pairs(groups) do
            xavp = self.ngcp.prefs[v]:xavp("caller")
            xavp(string.format("test_%s", v), v)
            assertEquals(sr.pv.get(string.format("$xavp(caller_%s_prefs=>test_%s)", v, v)), v)
            assertEquals(sr.pv.get(string.format("$xavp(caller_%s_prefs=>dummy)", v)), "caller")
            self.ngcp:clean("caller", v)
            assertEquals(sr.pv.get(string.format("$xavp(caller_%s_prefs=>dummy)", v)), "caller")
        end
        assertEquals(sr.pv.get("$avp(s:callee_outbound_from_display)"),nil)
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

    function TestNGCP:test_clean_callee_groups_vars()
        local groups = {"peer", "usr", "dom", "real"}
        local _,v, xavp
        local avp = NGCPAvp:new('callee_outbound_from_display')
        avp("foofighters")
        assertEquals(sr.pv.get("$avp(s:callee_outbound_from_display)"),"foofighters")

        for _,v in pairs(groups) do
            xavp = self.ngcp.prefs[v]:xavp("callee")
            xavp(string.format("test_%s", v), v)
            assertEquals(sr.pv.get(string.format("$xavp(callee_%s_prefs=>test_%s)", v, v)), v)
            assertEquals(sr.pv.get(string.format("$xavp(callee_%s_prefs=>dummy)", v)), "callee")
            self.ngcp:clean("callee", v)
            assertEquals(sr.pv.get(string.format("$xavp(callee_%s_prefs=>dummy)", v)), "callee")
        end
        assertEquals(sr.pv.get("$avp(s:callee_outbound_from_display)"),nil)
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
        assertFalse(sr.pv.get("$xavp(callee_dom_prefs=>testid)"))
        assertFalse(sr.pv.get("$xavp(callee_dom_prefs=>foo)"))
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>dummy)"), "callee")
    end

    function TestNGCP:test_caller_clean()
        local avp = NGCPAvp:new('callee_outbound_from_display')
        avp("foofighters")
        assertEquals(sr.pv.get("$avp(s:callee_outbound_from_display)"),"foofighters")
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
        assertEquals(sr.pv.get("$avp(s:callee_outbound_from_display)"),nil)
    end

    function TestNGCP:test_caller_peer_clean_vars()
        self:test_caller_peer_load()

        assertEquals(sr.pv.get("$avp(peer_callee_sst_enable)"), "no")
        assertEquals(sr.pv.get("$avp(peer_callee_sst_refresh_refresh_method)"), "UPDATE_FALLBACK_INVITE")

        self.ngcp:clean('caller', 'peer')

        assertEquals(sr.pv.get("$avp(s:peer_peer_caller_auth_user)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_peer_caller_auth_pass)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_peer_caller_auth_realm)"), nil)

        assertEquals(sr.pv.get("$avp(s:callee_use_rtpproxy)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_callee_ipv46_for_rtpproxy)"), nil)

        assertEquals(sr.pv.get("$avp(s:peer_callee_concurrent_max)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_callee_concurrent_max_out)"), nil)

        assertEquals(sr.pv.get("$avp(s:peer_callee_outbound_socket)"), nil)

        assertEquals(sr.pv.get("$avp(s:pstn_dp_caller_in_id)"), nil)
        assertEquals(sr.pv.get("$avp(s:pstn_dp_callee_in_id)"), nil)
        assertEquals(sr.pv.get("$avp(s:pstn_dp_caller_out_id)"), nil)
        assertEquals(sr.pv.get("$avp(s:pstn_dp_callee_out_id)"), nil)

        assertEquals(sr.pv.get("$avp(s:rewrite_caller_in_dpid)"), nil)
        assertEquals(sr.pv.get("$avp(s:rewrite_caller_out_dpid)"), nil)
        assertEquals(sr.pv.get("$avp(s:rewrite_callee_in_dpid)"), nil)
        assertEquals(sr.pv.get("$avp(s:rewrite_callee_out_dpid)"), nil)

        assertEquals(sr.pv.get("$avp(s:peer_callee_sst_enable)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_callee_sst_expires)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_callee_sst_min_timer)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_callee_sst_max_timer)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_callee_sst_refresh_method)"), nil)

        assertEquals(sr.pv.get("$avp(s:callee_outbound_from_display)"), nil)
        assertEquals(sr.pv.get("$avp(s:callee_outbound_from_user)"), nil)
        assertEquals(sr.pv.get("$avp(s:callee_outbound_pai_user)"), nil)
        assertEquals(sr.pv.get("$avp(s:callee_outbound_ppi_user)"), nil)
        assertEquals(sr.pv.get("$avp(s:callee_outbound_diversion)"), nil)

        assertEquals(sr.pv.get("$avp(s:concurrent_max)"), nil)
        assertEquals(sr.pv.get("$avp(s:concurrent_max_out)"), nil)
        assertEquals(sr.pv.get("$avp(s:concurrent_max_per_account)"), nil)
        assertEquals(sr.pv.get("$avp(s:concurrent_max_out_per_account)"), nil)
    end

    function TestNGCP:test_callee_peer_clean_vars()
        self:test_callee_peer_load()

        assertEquals(sr.pv.get("$avp(peer_caller_sst_enable)"), "no")
        assertEquals(sr.pv.get("$avp(peer_caller_sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")

        self.ngcp:clean('callee', 'peer')

        assertEquals(sr.pv.get("$avp(s:peer_peer_callee_auth_user)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_peer_callee_auth_pass)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_peer_callee_auth_realm)"), nil)


        assertEquals(sr.pv.get("$avp(s:caller_use_rtpproxy)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_caller_ipv46_for_rtpproxy)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_force_outbound_calls_to_peer)"), nil)

        assertEquals(sr.pv.get("$avp(s:peer_caller_find_subscriber_by_uuid)"), nil)

        assertEquals(sr.pv.get("$avp(s:pstn_dp_caller_in_id)"), nil)
        assertEquals(sr.pv.get("$avp(s:pstn_dp_callee_in_id)"), nil)
        assertEquals(sr.pv.get("$avp(s:pstn_dp_caller_out_id)"), nil)
        assertEquals(sr.pv.get("$avp(s:pstn_dp_callee_out_id)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_peer_concurrent_max)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_caller_sst_enable)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_caller_sst_expires)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_caller_sst_min_timer)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_caller_sst_max_timer)"), nil)
        assertEquals(sr.pv.get("$avp(s:peer_caller_sst_refresh_method)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_inbound_upn)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_inbound_npn)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_inbound_uprn)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_ip_header)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_ip_val)"), nil)
    end

    function TestNGCP:test_caller_usr_clean_vars()
        self:test_caller_usr_load()

        self.ngcp:clean('caller', 'usr')

        assertEquals(sr.pv.get("$avp(s:caller_account_id)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_lock)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_allowed_clis)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_user_cli)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_cc)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_ac)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_emergency_cli)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_emergency_prefix)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_emergency_suffix)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_block_out_mode)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_block_out_list)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_adm_block_out_mode)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_adm_block_out_list)"), nil)

        assertEquals(sr.pv.get("$avp(s:allowed_ips_grp)"), nil)
        assertEquals(sr.pv.get("$avp(s:man_allowed_ips_grp)"), nil)
        assertEquals(sr.pv.get("$avp(s:ignore_allowed_ips)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_ncos_id)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_adm_ncos_id)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_dom_ncos_id)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_dom_adm_ncos_id)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_block_override)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_adm_block_override)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_peer_auth_user)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_peer_auth_pass)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_peer_auth_realm)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_ext_subscriber_id)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_ext_contract_id)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_prepaid)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_ipv46_for_rtpproxy)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_use_rtpproxy)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_force_outbound_calls_to_peer)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_concurrent_max)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_concurrent_max_out)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_concurrent_max_per_account)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_concurrent_max_out_per_account)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_sst_enable)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_sst_expires)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_sst_min_timer)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_sst_max_timer)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_sst_refresh_method)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_reject_emergency)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_inbound_upn)"), nil)
        assertEquals(sr.pv.get("$avp(s:caller_inbound_uprn)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_extension_in_npn)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_allow_out_foreign_domain)"), nil)

        assertEquals(sr.pv.get("$avp(s:rewrite_caller_in_dpid)"), nil)
        assertEquals(sr.pv.get("$avp(s:rewrite_caller_out_dpid)"), nil)
        assertEquals(sr.pv.get("$avp(s:rewrite_callee_in_dpid)"), nil)
        assertEquals(sr.pv.get("$avp(s:rewrite_callee_out_dpid)"), nil)

        assertEquals(sr.pv.get("$avp(s:caller_ip_header)"), nil)
    end
-- class TestNGCP
--EOF