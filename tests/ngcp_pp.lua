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
local utils = require 'ngcp.utils'
local utable = utils.table
local PPFetch = require 'tests_v.pp_vars'
local NGCPXAvp = require 'ngcp.xavp'

local ksrMock = require 'mocks.ksr'
KSR = ksrMock:new()

local mc,env,con
local pp_vars = PPFetch:new()

package.loaded.luasql = nil
package.preload['luasql.mysql'] = function ()
    local luasql = {}
    luasql.mysql = function ()
        return env
    end
end
local NGCPConfig = require 'ngcp.config'
local NGCPPeerPrefs = require 'ngcp.pp'
-- luacheck: ignore TestNGCPPeerPrefs
TestNGCPPeerPrefs = {} --class

    function TestNGCPPeerPrefs:setUp()
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

        self.d = NGCPPeerPrefs:new(self.config)
        pp_vars:reset()
    end

    function TestNGCPPeerPrefs:tearDown()
        KSR.pv.vars = {}
    end

    function TestNGCPPeerPrefs:test_init()
        --print("TestNGCPPeerPrefs:test_init")
        lu.assertEquals(self.d.db_table, "peer_preferences")
    end

    function TestNGCPPeerPrefs:get_defaults(level, set)
        local keys_expected = {}
        local defaults = self.d.config:get_defaults('peer')

        if set then
            keys_expected = utable.deepcopy(set)
            for _,v in pairs(keys_expected) do
                KSR.log("dbg", string.format("removed key:%s is been loaded.", v))
                defaults[v] = nil
            end
        end

        for k,v in pairs(defaults) do
            utable.add(keys_expected, k)
            lu.assertEquals(KSR.pv.get("$xavp("..level.."_peer_prefs=>"..k..")"), v)
        end
        return keys_expected
    end

    function TestNGCPPeerPrefs:test_caller_load_empty()
        lu.assertEvalToTrue(self.d.config)
        mc:replay()
        lu.assertEquals(self.d:caller_load(), {})
        lu.assertEquals(self.d:caller_load(''), {})
        mc:verify()
    end

    function TestNGCPPeerPrefs:test_callee_load_empty()
        lu.assertEvalToTrue(self.d.config)
        mc:replay()
        lu.assertEquals(self.d:callee_load(), {})
        lu.assertEquals(self.d:callee_load(''), {})
        mc:verify()
    end

    function TestNGCPPeerPrefs:test_caller_load()
        lu.assertEvalToTrue(self.d.config)
        con:execute("SELECT * FROM peer_preferences WHERE uuid = '2'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pp_vars:val("p_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pp_vars:val("p_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:caller_load("2")
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
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>sst_enable)"),"no")
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>sst_min_timer)"), 90)
        lu.assertItemsEquals(keys, TestNGCPPeerPrefs:get_defaults("caller", {"sst_enable", "sst_refresh_method"}))
    end

    function TestNGCPPeerPrefs:test_callee_load()
        lu.assertEvalToTrue(self.d.config)
        con:execute("SELECT * FROM peer_preferences WHERE uuid = '2'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pp_vars:val("p_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(pp_vars:val("p_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:callee_load("2")
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
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>sst_enable)"),"no")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>sst_refresh_method)"), "UPDATE_FALLBACK_INVITE")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>sst_min_timer)"), 90)
        lu.assertItemsEquals(keys, TestNGCPPeerPrefs:get_defaults("callee", {"sst_enable", "sst_refresh_method"}))
    end

    function TestNGCPPeerPrefs:test_clean()
        local xavp = NGCPPeerPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        self.d:clean()
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        lu.assertNil(KSR.pv.get("$xavp(peer)"))
    end

    function TestNGCPPeerPrefs:test_callee_clean()
        local callee_xavp = NGCPPeerPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPPeerPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        self.d:clean('callee')
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),'caller')
        lu.assertNil(KSR.pv.get("$xavp(callee_peer_prefs=>testid)"))
        lu.assertNil(KSR.pv.get("$xavp(callee_peer_prefs=>foo)"))
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
    end

    function TestNGCPPeerPrefs:test_caller_clean()
        local callee_xavp = NGCPPeerPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPPeerPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        self.d:clean('caller')
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        lu.assertNil(KSR.pv.get("$xavp(caller_peer_prefs=>other)"))
        lu.assertNil(KSR.pv.get("$xavp(caller_peer_prefs=>otherfoo)"))
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
    end

    function TestNGCPPeerPrefs:test_clean_prefs()
        local xavp_pref = NGCPXAvp:new('callee', 'prefs')
        local xavp = NGCPPeerPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        xavp_pref("two",2)
        lu.assertEquals(KSR.pv.get("$xavp(callee_prefs=>two)"),2)
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        self.d:clean('callee')
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        lu.assertNil(KSR.pv.get("$xavp(peer)"))
        lu.assertEquals(KSR.pv.get("$xavp(callee_prefs=>dummy)"), "callee")
    end

    function TestNGCPPeerPrefs:test_tostring()
        local callee_xavp = NGCPPeerPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPPeerPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(tostring(self.d), 'caller_peer_prefs:{other={1},otherfoo={"foo"},dummy={"caller"}}\ncallee_peer_prefs:{dummy={"callee"},testid={1},foo={"foo"}}\n')
    end
-- class TestNGCPPeerPrefs
--EOF
