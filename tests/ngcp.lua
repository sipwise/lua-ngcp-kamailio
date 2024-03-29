--
-- Copyright 2013-2020 SipWise Team <development@sipwise.com>
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
local lu = require('luaunit')
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
KSR = ksrMock:new()

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

local out = [[
caller_contract_prefs:{dummy={"caller"}}
callee_contract_prefs:{dummy={"callee"}}
caller_usr_prefs:{dummy={"caller"}}
callee_usr_prefs:{dummy={"callee"}}
caller_peer_prefs:{dummy={"caller"}}
callee_peer_prefs:{dummy={"callee"}}
caller_dom_prefs:{dummy={"caller"}}
callee_dom_prefs:{dummy={"callee"}}
caller_prof_prefs:{dummy={"caller"}}
callee_prof_prefs:{dummy={"callee"}}
caller_fax_prefs:{dummy={"caller"}}
callee_fax_prefs:{dummy={"callee"}}
caller_reseller_prefs:{dummy={"caller"}}
callee_reseller_prefs:{dummy={"callee"}}
caller_real_prefs:{dummy={"caller"}}
callee_real_prefs:{dummy={"callee"}}
]]

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
        lu.assertNotNil(self.ngcp.config)
        lu.assertNotNil(self.ngcp.config.env)
        lu.assertIsNil(self.ngcp.config.con)
    end

    function TestNGCP:test_custom_config()
        local ngcp = NGCP:new({db_port=1111})
        lu.assertEquals(ngcp.config.db_port, 1111)
        lu.assertEquals(ngcp.config.default.usr.ringtimeout, 180)
    end

    function TestNGCP:test_config_get_defaults_all()
        local defaults = NGCPConfig.get_defaults(self.ngcp.config, 'peer')
        lu.assertItemsEquals(defaults, self.ngcp.config.default.peer)
    end

    function TestNGCP:test_config_get_defaults_real()
        local defaults = NGCPConfig.get_defaults(self.ngcp.config, 'usr')
        local usr_defaults = utable.deepcopy(self.ngcp.config.default.usr)
        lu.assertItemsEquals(defaults, usr_defaults)
    end

    function TestNGCP:test_config_get_defaults_dom()
        local defaults = NGCPConfig.get_defaults(self.ngcp.config, 'dom')
        lu.assertItemsEquals(defaults, self.ngcp.config.default.dom)
    end

    function TestNGCP:test_prefs_init()
        KSR.log("dbg", "TestNGCP:test_prefs_init")
        lu.assertNotNil(self.ngcp)
        lu.assertNotNil(self.ngcp.prefs)
        lu.assertNotNil(self.ngcp.prefs.peer)
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        lu.assertNotNil(self.ngcp.prefs.usr)
        lu.assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
        lu.assertNotNil(self.ngcp.prefs.dom)
        lu.assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        lu.assertNotNil(self.ngcp.prefs.real)
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
        lu.assertNotNil(self.ngcp.prefs.prof)
        lu.assertEquals(KSR.pv.get("$xavp(caller_prof_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_prof_prefs=>dummy)"),"callee")
        lu.assertNotNil(self.ngcp.prefs.fax)
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"),"callee")
        lu.assertNotNil(self.ngcp.prefs.reseller)
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>dummy)"),"callee")
    end

    function TestNGCP:test_log_pref()
        self.ngcp:log_pref()
        lu.assertError(self.ngcp.log_pref, self.ngcp, "dbg", "foo_var")
    end

    function TestNGCP:test_log_pref_info()
        self.ngcp:log_pref("info")
    end

    function TestNGCP:test_log_pref_peer()
        self.ngcp:log_pref("dbg", "peer")
    end

    function TestNGCP:test_caller_usr_load_empty()
        lu.assertEquals(self.ngcp:caller_usr_load(), {})
    end

    function TestNGCP:test_caller_usr_load_empty_dom()
        local c = self.ngcp.config
        env:connect(c.db_database, c.db_username, c.db_pass, c.db_host, c.db_port) ;mc :returns(self.con)
        -- connection check
        self.con:ping()  ;mc :returns(true)
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
        self.con:ping()  ;mc :returns(true)
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
            "reseller_id",
            "ext_contract_id",
            "cli",
            "cc",
            "ac",
            "no_nat_sipping"
        }

        lu.assertItemsEquals(keys, lkeys)
        lu.assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>account_id)"), 2)
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>cli)"), "4311001")
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>cc)"), "43")
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>ac)"), "1")
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>no_nat_sipping)"), "no")
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
        lu.assertItemsEquals(keys, lkeys)
        lu.assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>dummy)"), "caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        --- the default is on real and dom NOT in usr
        lu.assertIsNil(KSR.pv.get("$xavp(caller_usr_prefs=>sst_enable)"))
        lu.assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>sst_enable)"), "no")
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>sst_enable)"), "no")
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        lu.assertIsNil(KSR.pv.get("$xavp(caller_real_prefs=>force_outbound_calls_to_peer)"))
        lu.assertIsNil(KSR.pv.get("$xavp(caller_dom_prefs=>force_outbound_calls_to_peer)"))
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
        self.con:ping()  ;mc :returns(true)
        --
        self.con:execute("SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN prof_preferences AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = 'ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns({}) -- this is what I got on real mysql
        self.cur:close()
        -- connection check
        self.con:ping()  ;mc :returns(true)
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
        self.con:ping()  ;mc :returns(true)
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
            "reseller_id",
            "ext_contract_id",
            "cli",
            "cc",
            "ac",
            "no_nat_sipping",
            "force_outbound_calls_to_peer"
        }

        lu.assertItemsEquals(keys, lkeys)
        lu.assertEquals(KSR.pv.get("$xavp(caller_usr_prefs[0]=>dummy)"), "caller")
        --- the default is on real NOT in usr
        lu.assertIsNil(KSR.pv.get("$xavp(caller_usr_prefs[0]=>sst_enable)"))
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs[0]=>sst_enable)"), "no")
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs[0]=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        lu.assertEquals(KSR.pv.get("$xavp(caller_usr_prefs[0]=>force_outbound_calls_to_peer)"), 1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs[0]=>force_outbound_calls_to_peer)"), 1)
    end

    function TestNGCP:test_callee_usr_load_empty()
        lu.assertEquals(self.ngcp:callee_usr_load(), {})
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
        self.con:ping()  ;mc :returns(true)
        --
        self.con:execute("SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN prof_preferences AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = 'ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pprof_vars:val("prof_1"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:ping()  ;mc :returns(true)
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
        self.con:ping()  ;mc :returns(true)
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
            "reseller_id",
            "ext_contract_id",
            "cli",
            "cc",
            "ac",
            "no_nat_sipping"
        }

        lu.assertItemsEquals(keys, lkeys)
        lu.assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"), "callee")
        lu.assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>sst_enable)"), "no")
        --- the default is on real NOT in usr
        lu.assertIsNil(KSR.pv.get("$xavp(callee_usr_prefs=>sst_enable)"))
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>sst_enable)"), "no")
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
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
        self.con:ping()  ;mc :returns(true)
        --
        self.con:execute("SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN prof_preferences AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = 'ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pprof_vars:val("prof_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:ping()  ;mc :returns(true)
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
        self.con:ping()  ;mc :returns(true)
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
            "reseller_id",
            "ext_contract_id",
            "cli",
            "cc",
            "ac",
            "no_nat_sipping"
        }

        lu.assertItemsEquals(keys, lkeys)
        lu.assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"), "callee")
        lu.assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>sst_enable)"), "no")
        lu.assertEquals(KSR.pv.get("$xavp(callee_prof_prefs=>sst_enable)"), "yes")
        --- the default is on real NOT in usr
        lu.assertIsNil(KSR.pv.get("$xavp(callee_usr_prefs=>sst_enable)"))
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>sst_enable)"), "yes")
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
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
        self.con:ping()  ;mc :returns(true)
        --
        self.con:execute("SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN prof_preferences AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = 'ah736f72-21d1-4ea6-a3ea-4d7f56b3887c'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pprof_vars:val("prof_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:ping()  ;mc :returns(true)
        --
        self.con:execute("SELECT * FROM usr_preferences WHERE uuid ='ah736f72-21d1-4ea6-a3ea-4d7f56b3887c' ORDER BY id DESC") ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ah736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()
        -- connection check
        self.con:ping()  ;mc :returns(true)
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
            "reseller_id",
            "ext_contract_id"
        }

        lu.assertItemsEquals(keys, lkeys)
        lu.assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"), "callee")
        lu.assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>sst_enable)"), "no")
        lu.assertEquals(KSR.pv.get("$xavp(callee_prof_prefs=>sst_enable)"), "yes")
        --- the default is on real NOT in usr
        lu.assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>sst_enable)"), "no")
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>sst_enable)"), "no")
    end

    function TestNGCP:test_caller_peer_load_empty()
        lu.assertEquals(self.ngcp:caller_peer_load(), {})
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

        lu.assertItemsEquals(keys, lkeys)
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"), "caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>sst_enable)"), "no")
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
    end

    function TestNGCP:test_callee_peer_load_empty()
        lu.assertEquals(self.ngcp:callee_peer_load(), {})
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

        lu.assertItemsEquals(keys, lkeys)
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"), "callee")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>sst_enable)"), "no")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
    end

    function TestNGCP:test_clean()
        local xavp = NGCPXAvp:new('callee','usr_prefs')
        xavp("testid",1)
        xavp("foo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        self.ngcp:clean()
        lu.assertEquals(KSR.pv.get("$avp(s:callee_cfb)"),nil)
        lu.assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
        lu.assertIsNil(KSR.pv.get("$xavp(user)"))
    end

    function TestNGCP:test_clean_caller_groups()
        local groups = {"peer", "usr", "dom", "real", "prof", "contract"}

        for _,v in pairs(groups) do
            local xavp = self.ngcp.prefs[v]:xavp("caller")
            xavp(string.format("test_%s", v), v)
            lu.assertEquals(KSR.pv.get(string.format("$xavp(caller_%s_prefs=>test_%s)", v, v)), v)
            lu.assertEquals(KSR.pv.get(string.format("$xavp(caller_%s_prefs=>dummy)", v)), "caller")
            self.ngcp:clean("caller", v)
            lu.assertEquals(KSR.pv.get(string.format("$xavp(caller_%s_prefs=>dummy)", v)), "caller")
        end
        lu.assertError(self.ngcp.clean, self.ngcp, "caller", "whatever")
    end


    function TestNGCP:test_clean_callee_groups()
        local groups = {"peer", "usr", "dom", "real", "prof", "contract"}

        for _,v in pairs(groups) do
            local xavp = self.ngcp.prefs[v]:xavp("callee")
            xavp(string.format("test_%s", v), v)
            lu.assertEquals(KSR.pv.get(string.format("$xavp(callee_%s_prefs=>test_%s)", v, v)), v)
            lu.assertEquals(KSR.pv.get(string.format("$xavp(callee_%s_prefs=>dummy)", v)), "callee")
            self.ngcp:clean("callee", v)
            lu.assertEquals(KSR.pv.get(string.format("$xavp(callee_%s_prefs=>dummy)", v)), "callee")
        end
        lu.assertError(self.ngcp.clean, self.ngcp, "callee", "whatever")
    end

    function TestNGCP:test_callee_clean()
        local callee_xavp = NGCPDomainPrefs:xavp('callee')
        lu.assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        callee_xavp("testid",1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>testid)"),1)
        callee_xavp("foo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>foo)"),"foo")
        local caller_xavp = NGCPDomainPrefs:xavp('caller')
        caller_xavp("other",1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        self.ngcp:clean('callee')
        lu.assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>dummy)"),'caller')
        lu.assertIsNil(KSR.pv.get("$xavp(callee_dom_prefs=>testid)"))
        lu.assertIsNil(KSR.pv.get("$xavp(callee_dom_prefs=>foo)"))
        lu.assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>dummy)"), "callee")
    end

    function TestNGCP:test_caller_clean()
        local callee_xavp = NGCPXAvp:new('callee','peer_prefs')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPXAvp:new('caller','peer_prefs')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        self.ngcp:clean('caller')
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        lu.assertNil(KSR.pv.get("$xavp(caller_peer_prefs=>other)"))
        lu.assertNil(KSR.pv.get("$xavp(caller_peer_prefs=>otherfoo)"))
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
    end

    function TestNGCP:test_tostring()
        lu.assertEquals(out, tostring(self.ngcp))
    end
-- class TestNGCP
--EOF
