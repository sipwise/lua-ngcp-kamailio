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
local CPFetch = require 'tests_v.cp_vars'

local ksrMock = require 'mocks.ksr'
KSR = ksrMock.new()

local mc,env,con
local cp_vars = CPFetch:new()

package.loaded.luasql = nil
package.preload['luasql.mysql'] = function ()
    local luasql = {}
    luasql.mysql = function ()
        return env
    end
end
local NGCPConfig = require 'ngcp.config'
local NGCPContractPrefs = require 'ngcp.cp'
-- luacheck: ignore TestNGCPContractPrefs
TestNGCPContractPrefs = {} --class

    function TestNGCPContractPrefs:setUp()
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

        self.d = NGCPContractPrefs:new(self.config)
        cp_vars:reset()
    end

    function TestNGCPContractPrefs:tearDown()
        KSR.pv.vars= {}
    end

    function TestNGCPContractPrefs:test_init()
        --print("TestNGCPContractPrefs:test_init")
        lu.assertEquals(self.d.db_table, "contract_preferences")
    end

    function TestNGCPContractPrefs:test_caller_load_empty()
        lu.assertNotNil(self.d.config)
        lu.assertEquals(self.d:caller_load(), {})
    end

    function TestNGCPContractPrefs:test_callee_load_empty()
        lu.assertNotNil(self.d.config)
        lu.assertEquals(self.d:callee_load(), {})
    end

    function TestNGCPContractPrefs:test_caller_load()
        lu.assertNotNil(self.d.config)
        con:execute("SELECT * FROM contract_preferences WHERE uuid ='1' AND location_id IS NULL")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(cp_vars:val("cp_1"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:caller_load("1")
        mc:verify()

        lu.assertItemsEquals(keys, {"sst_enable"})
        lu.assertEquals(KSR.pv.get("$xavp(caller_contract_prefs=>sst_enable)"),"no")
        lu.assertNil(KSR.pv.get("$xavp(callee_contract_prefs=>location_id)"))
    end

    function TestNGCPContractPrefs:test_callee_load()
        lu.assertNotNil(self.d.config)
        local query = NGCPContractPrefs.query_location_id:format("2", "ipv4", "172.16.15.1", "ipv4", "172.16.15.1")
        con:execute(query)  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns({location_id = 1 })
        self.cur:close()
        con:execute("SELECT * FROM contract_preferences WHERE uuid ='2' AND location_id = 1")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(cp_vars:val("cp_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:callee_load("2", '172.16.15.1')
        mc:verify()

        lu.assertItemsEquals(keys, {"sst_enable"})
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>sst_enable)"),"yes")
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>location_id)"),1)
    end

    function TestNGCPContractPrefs:test_clean()
        local xavp = NGCPContractPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
        self.d:clean()
        lu.assertEquals(KSR.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
        lu.assertNil(KSR.pv.get("$xavp(prof)"))
    end

    function TestNGCPContractPrefs:test_callee_clean()
        local callee_xavp = NGCPContractPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPContractPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_contract_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_contract_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
        self.d:clean('callee')
        lu.assertEquals(KSR.pv.get("$xavp(caller_contract_prefs=>dummy)"),'caller')
        lu.assertNil(KSR.pv.get("$xavp(callee_contract_prefs=>testid)"))
        lu.assertNil(KSR.pv.get("$xavp(callee_contract_prefs=>foo)"))
        lu.assertEquals(KSR.pv.get("$xavp(caller_contract_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_contract_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
    end

    function TestNGCPContractPrefs:test_caller_clean()
        local callee_xavp = NGCPContractPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPContractPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_contract_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_contract_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
        self.d:clean('caller')
        lu.assertEquals(KSR.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        lu.assertNil(KSR.pv.get("$xavp(caller_contract_prefs=>other)"))
        lu.assertNil(KSR.pv.get("$xavp(caller_contract_prefs=>otherfoo)"))
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
    end

    function TestNGCPContractPrefs:test_tostring()
        local callee_xavp = NGCPContractPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPContractPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(tostring(self.d), 'caller_contract_prefs:{other={1},otherfoo={"foo"},dummy={"caller"}}\ncallee_contract_prefs:{dummy={"callee"},testid={1},foo={"foo"}}\n')
    end
-- class TestNGCPContractPrefs
--EOF
