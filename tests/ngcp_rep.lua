--
-- Copyright 2013-2023 SipWise Team <development@sipwise.com>
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
local REPFetch = require 'tests_v.rep_vars'


local ksrMock = require 'mocks.ksr'
KSR = ksrMock:new()

local mc,env,con
local rep_vars = REPFetch:new()

package.loaded.luasql = nil
package.preload['luasql.mysql'] = function ()
    local luasql = {}
    luasql.mysql = function ()
        return env
    end
end
local NGCPConfig = require 'ngcp.config'
local NGCPResellerPrefs = require 'ngcp.rep'
-- luacheck: ignore TestNGCPResellerPrefs
TestNGCPResellerPrefs = {} --class

    function TestNGCPResellerPrefs:setUp()
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

        self.d = NGCPResellerPrefs:new(self.config)
        rep_vars:reset()
    end

    function TestNGCPResellerPrefs:tearDown()
        KSR.pv.vars = {}
    end

    function TestNGCPResellerPrefs:test_init()
        --print("TestNGCPResellerPrefs:test_init")
        lu.assertEquals(self.d.db_table, "reseller_preferences")
    end

    function TestNGCPResellerPrefs:get_defaults(level, set)
        local keys_expected = {}
        local defaults = self.d.config:get_defaults('reseller')

        if set then
            keys_expected = utable.deepcopy(set)
            for _,v in pairs(keys_expected) do
                KSR.log("dbg", string.format("removed key:%s is been loaded.", v))
                defaults[v] = nil
            end
        end

        for k,v in pairs(defaults) do
            utable.add(keys_expected, k)
            lu.assertEquals(KSR.pv.get("$xavp("..level.."_reseller_prefs=>"..k..")"), v)
        end
        return keys_expected
    end

    function TestNGCPResellerPrefs:test_caller_load_empty()
        lu.assertEvalToTrue(self.d.config)
        mc:replay()
        lu.assertEquals(self.d:caller_load(), {})
        lu.assertEquals(self.d:caller_load(''), {})
        mc:verify()
    end

    function TestNGCPResellerPrefs:test_callee_load_empty()
        lu.assertEvalToTrue(self.d.config)
        mc:replay()
        lu.assertEquals(self.d:callee_load(), {})
        lu.assertEquals(self.d:callee_load(''), {})
        mc:verify()
    end

    function TestNGCPResellerPrefs:test_caller_load()
        lu.assertEvalToTrue(self.d.config)
        con:execute("SELECT * FROM reseller_preferences WHERE uuid = '1'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(rep_vars:val("r_1"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(rep_vars:val("r_1"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:caller_load("1")
        mc:verify()

        local lkeys = {
            "concurrent_max_in",
            "concurrent_max_out"
        }

        lu.assertItemsEquals(keys, lkeys)
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>dummy)"), "caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>concurrent_max_in)"), 10)
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>concurrent_max_out)"), 5)
    end

    function TestNGCPResellerPrefs:test_callee_load()
        lu.assertEvalToTrue(self.d.config)
        con:execute("SELECT * FROM reseller_preferences WHERE uuid = '2'")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(rep_vars:val("r_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(rep_vars:val("r_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(rep_vars:val("r_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:callee_load("2")
        mc:verify()

        local lkeys = {
          "concurrent_max",
          "concurrent_max_in",
          "concurrent_max_out"
        }

        lu.assertItemsEquals(keys, lkeys)
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>dummy)"), "callee")
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>concurrent_max)"), 5)
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>concurrent_max_in)"), 5)
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>concurrent_max_out)"), 2)
    end

    function TestNGCPResellerPrefs:test_clean()
        local xavp = NGCPResellerPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>dummy)"),"callee")
        self.d:clean()
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>dummy)"),"callee")
        lu.assertNil(KSR.pv.get("$xavp(reseller)"))
    end

    function TestNGCPResellerPrefs:test_callee_clean()
        local callee_xavp = NGCPResellerPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPResellerPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>dummy)"),"callee")
        self.d:clean('callee')
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>dummy)"),'caller')
        lu.assertNil(KSR.pv.get("$xavp(callee_reseller_prefs=>testid)"))
        lu.assertNil(KSR.pv.get("$xavp(callee_reseller_prefs=>foo)"))
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>dummy)"),"callee")
    end

    function TestNGCPResellerPrefs:test_caller_clean()
        local callee_xavp = NGCPResellerPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPResellerPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>dummy)"),"callee")
        self.d:clean('caller')
        lu.assertEquals(KSR.pv.get("$xavp(caller_reseller_prefs=>dummy)"),"caller")
        lu.assertNil(KSR.pv.get("$xavp(caller_reseller_prefs=>other)"))
        lu.assertNil(KSR.pv.get("$xavp(caller_reseller_prefs=>otherfoo)"))
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_reseller_prefs=>dummy)"),"callee")
    end

    function TestNGCPResellerPrefs:test_tostring()
        local callee_xavp = NGCPResellerPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPResellerPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(tostring(self.d), 'caller_reseller_prefs:{other={1},otherfoo={"foo"},dummy={"caller"}}\ncallee_reseller_prefs:{dummy={"callee"},testid={1},foo={"foo"}}\n')
    end
-- class TestNGCPResellerPrefs
--EOF
