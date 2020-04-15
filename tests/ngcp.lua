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
local NGCPXAvp = require 'ngcp.xavp'
local DPFetch = require 'tests_v.dp_vars'
local PPFetch = require 'tests_v.pp_vars'
local PProfFetch = require 'tests_v.pprof_vars'
local UPFetch = require 'tests_v.up_vars'
local FPFetch = require 'tests_v.fp_vars'
local utils = require 'ngcp.utils'
local utable = utils.table

local ksrMock = require 'mocks.ksr'
KSR = ksrMock.new()

local mc,env
local dp_vars = DPFetch:new()
local pp_vars = PPFetch:new()
local up_vars = UPFetch:new()
local pprof_vars = PProfFetch:new()
local fp_vars = FPFetch:new()

package.loaded.luasql = nil
package.preload['luasql.mysql'] = function ()
    local luasql = {}
    luasql.mysql = function ()
        return env
    end
end

local NGCP = require 'ngcp.ngcp'
local NGCPConfig = require 'ngcp.config'
local NGCPDomainPrefs = require 'ngcp.dp'
-- luacheck: ignore TestNGCP
TestNGCP = {} --class

    function TestNGCP:setUp()
        mc = lemock.controller()
        env = mc:mock()
        self.con  = mc:mock()
        self.cur  = mc:mock()

        self.ngcp = NGCP:new()
        self.ngcp.config.env = env
        self.ngcp.config.con = nil
        dp_vars:reset()
        pp_vars:reset()
        pprof_vars:reset()
        up_vars:reset()
        fp_vars:reset()
    end

    function TestNGCP:tearDown()
        KSR.pv.vars= {}
    end

    function TestNGCP:test_config()
        assertNotNil(self.ngcp.config)
        assert(self.ngcp.config.env)
        assertIsNil(self.ngcp.config.con)
    end

    function TestNGCP:test_config_get_defaults_all()
        local defaults = NGCPConfig.get_defaults(self.ngcp.config, 'peer')
        assertItemsEquals(defaults, self.ngcp.config.default.peer)
    end

    function TestNGCP:test_config_get_defaults_real()
        local defaults = NGCPConfig.get_defaults(self.ngcp.config, 'usr')
        local usr_defaults = utable.deepcopy(self.ngcp.config.default.usr)
        assertItemsEquals(defaults, usr_defaults)
    end

    function TestNGCP:test_config_get_defaults_dom()
        local defaults = NGCPConfig.get_defaults(self.ngcp.config, 'dom')
        assertItemsEquals(defaults, self.ngcp.config.default.dom)
    end

    function TestNGCP:test_prefs_init()
        KSR.log("dbg", "TestNGCP:test_prefs_init")
        assertNotNil(self.ngcp)
        assertNotNil(self.ngcp.prefs)
        assertNotNil(self.ngcp.prefs.peer)
        assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        assertNotNil(self.ngcp.prefs.usr)
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
        assertNotNil(self.ngcp.prefs.dom)
        assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>dummy)"),"caller")
        assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        assertNotNil(self.ngcp.prefs.real)
        assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
        assertNotNil(self.ngcp.prefs.prof)
        assertEquals(KSR.pv.get("$xavp(caller_prof_prefs=>dummy)"),"caller")
        assertEquals(KSR.pv.get("$xavp(callee_prof_prefs=>dummy)"),"callee")
        assertNotNil(self.ngcp.prefs.fax)
        assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"),"caller")
        assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"),"callee")
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
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN prof_preferences AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = 'ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        --
        self.con:execute("SELECT * FROM usr_preferences WHERE uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c' ORDER BY id DESC")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT fp.* FROM provisioning.voip_fax_preferences fp, provisioning.voip_subscribers s WHERE s.uuid = 'ae736f72-21d1-4ea6-a3ea-4d7f56b3887c' AND fp.subscriber_id = s.id")  ;mc :returns(self.cur)
        self.cur:getcolnames()        ;mc :returns(fp_vars:val("fp_keys"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(fp_vars:val("fp_1"))
        self.cur:close()

        mc:replay()
        local keys = self.ngcp:caller_usr_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        mc:verify()

        local lkeys = {
            "ext_subscriber_id",
            "ringtimeout",
            "account_id",
            "ext_contract_id",
            "cli",
            "cc",
            "ac",
            "no_nat_sipping"
        }

        assertItemsEquals(keys, lkeys)
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>account_id)"), 2)
        assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>cli)"), "4311001")
        assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>cc)"), "43")
        assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>ac)"), "1")
        assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>no_nat_sipping)"), "no")
    end

    function TestNGCP:test_caller_usr_load_empty_usr()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute("SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.ngcp:caller_usr_load(nil, "192.168.51.56")
        mc:verify()

        local lkeys = {
          "ip_header",
          "sst_enable",
          "outbound_from_user",
          "inbound_upn",
          "sst_expires",
          "sst_max_timer",
          "sst_min_timer",
          "sst_refresh_method",
          "inbound_uprn"
        }
        assertItemsEquals(keys, lkeys)
        assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>dummy)"), "caller")
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        --- the default is on real and dom NOT in usr
        assertIsNil(KSR.pv.get("$xavp(caller_usr_prefs=>sst_enable)"))
        assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>sst_enable)"), "no")
        assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>sst_enable)"), "no")
        assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertIsNil(KSR.pv.get("$xavp(caller_real_prefs=>force_outbound_calls_to_peer)"))
        assertIsNil(KSR.pv.get("$xavp(caller_dom_prefs=>force_outbound_calls_to_peer)"))
    end

    function TestNGCP:test_caller_usr_load()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute("SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN prof_preferences AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = 'ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns({}) -- this is what I got on real mysql
        self.cur:close()
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT * FROM usr_preferences WHERE uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c' ORDER BY id DESC")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT fp.* FROM provisioning.voip_fax_preferences fp, provisioning.voip_subscribers s WHERE s.uuid = 'ae736f72-21d1-4ea6-a3ea-4d7f56b3887c' AND fp.subscriber_id = s.id")  ;mc :returns(self.cur)
        self.cur:getcolnames()        ;mc :returns(fp_vars:val("fp_keys"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(fp_vars:val("fp_1"))
        self.cur:close()

        mc:replay()
        local keys = self.ngcp:caller_usr_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c", "192.168.51.56")
        mc:verify()

        local lkeys = {
            "ip_header",
            "sst_enable",
            "outbound_from_user",
            "inbound_upn",
            "sst_expires",
            "sst_max_timer",
            "sst_min_timer",
            "sst_refresh_method",
            "inbound_uprn",
            "ext_subscriber_id",
            "ringtimeout",
            "account_id",
            "ext_contract_id",
            "cli",
            "cc",
            "ac",
            "no_nat_sipping",
            "force_outbound_calls_to_peer"
        }

        assertItemsEquals(keys, lkeys)
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs[0]=>dummy)"), "caller")
        --- the default is on real NOT in usr
        assertIsNil(KSR.pv.get("$xavp(caller_usr_prefs[0]=>sst_enable)"))
        assertEquals(KSR.pv.get("$xavp(caller_real_prefs[0]=>sst_enable)"), "no")
        assertEquals(KSR.pv.get("$xavp(caller_real_prefs[0]=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs[0]=>force_outbound_calls_to_peer)"), 1)
        assertEquals(KSR.pv.get("$xavp(caller_real_prefs[0]=>force_outbound_calls_to_peer)"), 1)
    end

    function TestNGCP:test_callee_usr_load_empty()
        assertEquals(self.ngcp:callee_usr_load(), {})
    end

    function TestNGCP:test_callee_usr_load()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute("SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN prof_preferences AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = 'ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pprof_vars:val("prof_1"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT * FROM usr_preferences WHERE uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c' ORDER BY id DESC") ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT fp.* FROM provisioning.voip_fax_preferences fp, provisioning.voip_subscribers s WHERE s.uuid = 'ae736f72-21d1-4ea6-a3ea-4d7f56b3887c' AND fp.subscriber_id = s.id")  ;mc :returns(self.cur)
        self.cur:getcolnames()        ;mc :returns(fp_vars:val("fp_keys"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(fp_vars:val("fp_2"))
        self.cur:close()

        mc:replay()
        local keys = self.ngcp:callee_usr_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c", "192.168.51.56")
        mc:verify()

        local lkeys = {
            "ip_header",
            "sst_enable",
            "outbound_from_user",
            "inbound_upn",
            "sst_expires",
            "sst_max_timer",
            "sst_min_timer",
            "sst_refresh_method",
            "inbound_uprn",
            "ext_subscriber_id",
            "ringtimeout",
            "account_id",
            "ext_contract_id",
            "cli",
            "cc",
            "ac",
            "no_nat_sipping"
        }

        assertItemsEquals(keys, lkeys)
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"), "callee")
        assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>sst_enable)"), "no")
        --- the default is on real NOT in usr
        assertIsNil(KSR.pv.get("$xavp(callee_usr_prefs=>sst_enable)"))
        assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>sst_enable)"), "no")
        assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
    end

    function TestNGCP:test_callee_usr_load_prof()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute("SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN prof_preferences AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = 'ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pprof_vars:val("prof_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT * FROM usr_preferences WHERE uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c' ORDER BY id DESC") ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT fp.* FROM provisioning.voip_fax_preferences fp, provisioning.voip_subscribers s WHERE s.uuid = 'ae736f72-21d1-4ea6-a3ea-4d7f56b3887c' AND fp.subscriber_id = s.id")  ;mc :returns(self.cur)
        self.cur:getcolnames()        ;mc :returns(fp_vars:val("fp_keys"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(fp_vars:val("fp_2"))
        self.cur:close()

        mc:replay()
        local keys = self.ngcp:callee_usr_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c", "192.168.51.56")
        mc:verify()

        local lkeys = {
            "ip_header",
            "sst_enable",
            "outbound_from_user",
            "inbound_upn",
            "sst_expires",
            "sst_max_timer",
            "sst_min_timer",
            "sst_refresh_method",
            "inbound_uprn",
            "ext_subscriber_id",
            "ringtimeout",
            "account_id",
            "ext_contract_id",
            "cli",
            "cc",
            "ac",
            "no_nat_sipping"
        }

        assertItemsEquals(keys, lkeys)
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"), "callee")
        assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>sst_enable)"), "no")
        assertEquals(KSR.pv.get("$xavp(callee_prof_prefs=>sst_enable)"), "yes")
        --- the default is on real NOT in usr
        assertIsNil(KSR.pv.get("$xavp(callee_usr_prefs=>sst_enable)"))
        assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>sst_enable)"), "yes")
        assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
    end

    function TestNGCP:test_callee_usr_load_prof_usr()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute("SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(dp_vars:val("d_192_168_51_56"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN prof_preferences AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = 'ah736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pprof_vars:val("prof_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT * FROM usr_preferences WHERE uuid ='ah736f72-21d1-4ea6-a3ea-4d7f56b3887c' ORDER BY id DESC") ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ah736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:execute("SELECT 1")  ;mc :returns(self.cur)
        self.cur:fetch()              ;mc :returns({})
        self.cur:numrows()            ;mc :returns(1)
        self.cur:close()
        --
        self.con:execute("SELECT fp.* FROM provisioning.voip_fax_preferences fp, provisioning.voip_subscribers s WHERE s.uuid = 'ah736f72-21d1-4ea6-a3ea-4d7f56b3887c' AND fp.subscriber_id = s.id")  ;mc :returns(self.cur)
        self.cur:getcolnames()        ;mc :returns(fp_vars:val("fp_keys"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(fp_vars:val("fp_2"))
        self.cur:close()

        mc:replay()
        local keys = self.ngcp:callee_usr_load("ah736f72-21d1-4ea6-a3ea-4d7f56b3887c", "192.168.51.56")
        mc:verify()

        local lkeys = {
            "ip_header",
            "sst_enable",
            "outbound_from_user",
            "inbound_upn",
            "sst_expires",
            "sst_max_timer",
            "sst_min_timer",
            "sst_refresh_method",
            "inbound_uprn",
            "ext_subscriber_id",
            "ringtimeout",
            "account_id",
            "ext_contract_id"
        }

        assertItemsEquals(keys, lkeys)
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"), "callee")
        assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>sst_enable)"), "no")
        assertEquals(KSR.pv.get("$xavp(callee_prof_prefs=>sst_enable)"), "yes")
        --- the default is on real NOT in usr
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>sst_enable)"), "no")
        assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>sst_enable)"), "no")
    end

    function TestNGCP:test_caller_peer_load_empty()
        assertEquals(self.ngcp:caller_peer_load(), {})
    end

    function TestNGCP:test_caller_peer_load()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute("SELECT * FROM peer_preferences WHERE uuid = '2'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pp_vars:val("p_2")) --sst_enable: "no"
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pp_vars:val("p_2")) --sst_refresh_method: "UPDATE_FALLBACK_INVITE"
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.ngcp:caller_peer_load("2")
        mc:verify()

        local lkeys = {
            "ip_header",
            "sst_enable",
            "outbound_from_user",
            "inbound_upn",
            "sst_expires",
            "sst_max_timer",
            "inbound_npn",
            "sst_min_timer",
            "sst_refresh_method",
            "inbound_uprn"
        }

        assertItemsEquals(keys, lkeys)
        assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"), "caller")
        assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>sst_enable)"), "no")
        assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
    end

    function TestNGCP:test_callee_peer_load_empty()
        assertEquals(self.ngcp:callee_peer_load(), {})
    end

    function TestNGCP:test_callee_peer_load()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        self.con:execute("SELECT * FROM peer_preferences WHERE uuid = '2'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pp_vars:val("p_2")) --sst_enable: "no"
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pp_vars:val("p_2")) --sst_refresh_method: "UPDATE_FALLBACK_INVITE"
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.ngcp:callee_peer_load("2")
        mc:verify()

        local lkeys = {
            "ip_header",
            "sst_enable",
            "outbound_from_user",
            "inbound_upn",
            "sst_expires",
            "sst_max_timer",
            "inbound_npn",
            "sst_min_timer",
            "sst_refresh_method",
            "inbound_uprn"
        }

        assertItemsEquals(keys, lkeys)
        assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"), "callee")
        assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>sst_enable)"), "no")
        assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
    end

    function TestNGCP:test_clean()
        local xavp = NGCPXAvp:new('callee','usr_prefs')
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        self.ngcp:clean()
        assertEquals(KSR.pv.get("$avp(s:callee_cfb)"),nil)
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
        assertIsNil(KSR.pv.get("$xavp(user)"))
    end

    function TestNGCP:test_clean_caller_groups()
        local groups = {"peer", "usr", "dom", "real", "prof", "contract"}

        for _,v in pairs(groups) do
            local xavp = self.ngcp.prefs[v]:xavp("caller")
            xavp(string.format("test_%s", v), v)
            assertEquals(KSR.pv.get(string.format("$xavp(caller_%s_prefs=>test_%s)", v, v)), v)
            assertEquals(KSR.pv.get(string.format("$xavp(caller_%s_prefs=>dummy)", v)), "caller")
            self.ngcp:clean("caller", v)
            assertEquals(KSR.pv.get(string.format("$xavp(caller_%s_prefs=>dummy)", v)), "caller")
        end
        assertError(self.ngcp.clean, self.ngcp, "caller", "whatever")
    end


    function TestNGCP:test_clean_callee_groups()
        local groups = {"peer", "usr", "dom", "real", "prof", "contract"}

        for _,v in pairs(groups) do
            local xavp = self.ngcp.prefs[v]:xavp("callee")
            xavp(string.format("test_%s", v), v)
            assertEquals(KSR.pv.get(string.format("$xavp(callee_%s_prefs=>test_%s)", v, v)), v)
            assertEquals(KSR.pv.get(string.format("$xavp(callee_%s_prefs=>dummy)", v)), "callee")
            self.ngcp:clean("callee", v)
            assertEquals(KSR.pv.get(string.format("$xavp(callee_%s_prefs=>dummy)", v)), "callee")
        end
        assertError(self.ngcp.clean, self.ngcp, "callee", "whatever")
    end

    function TestNGCP:test_callee_clean()
        local callee_xavp = NGCPDomainPrefs:xavp('callee')
        assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        callee_xavp("testid",1)
        assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>testid)"),1)
        callee_xavp("foo","foo")
        assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>foo)"),"foo")
        local caller_xavp = NGCPDomainPrefs:xavp('caller')
        caller_xavp("other",1)
        assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        caller_xavp("otherfoo","foo")
        assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        self.ngcp:clean('callee')
        assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>dummy)"),'caller')
        assertIsNil(KSR.pv.get("$xavp(callee_dom_prefs=>testid)"))
        assertIsNil(KSR.pv.get("$xavp(callee_dom_prefs=>foo)"))
        assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>dummy)"), "callee")
    end

    function TestNGCP:test_caller_clean()
        local callee_xavp = NGCPXAvp:new('callee','peer_prefs')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPXAvp:new('caller','peer_prefs')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>other)"),1)
        assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>otherfoo)"),"foo")
        assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        self.ngcp:clean('caller')
        assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assertNil(KSR.pv.get("$xavp(caller_peer_prefs=>other)"))
        assertNil(KSR.pv.get("$xavp(caller_peer_prefs=>otherfoo)"))
        assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
    end

    function TestNGCP:test_tostring()
        assertEquals(tostring(self.ngcp), 'caller_contract_prefs:{dummy={"caller"}}\ncallee_contract_prefs:{dummy={"callee"}}\ncaller_peer_prefs:{dummy={"caller"}}\ncallee_peer_prefs:{dummy={"callee"}}\ncaller_dom_prefs:{dummy={"caller"}}\ncallee_dom_prefs:{dummy={"callee"}}\ncaller_prof_prefs:{dummy={"caller"}}\ncallee_prof_prefs:{dummy={"callee"}}\ncaller_fax_prefs:{dummy={"caller"}}\ncallee_fax_prefs:{dummy={"callee"}}\ncaller_usr_prefs:{dummy={"caller"}}\ncallee_usr_prefs:{dummy={"callee"}}\ncaller_real_prefs:{dummy={"caller"}}\ncallee_real_prefs:{dummy={"callee"}}\n')
    end
-- class TestNGCP
--EOF
