--
-- Copyright 2013-2016 SipWise Team <development@sipwise.com>
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
local CPFetch = require 'tests_v.cp_vars'

local srMock = require 'mocks.sr'
sr = srMock:new()

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
        sr.pv.unset("$xavp(caller_dom_prefs)")
        sr.pv.unset("$xavp(callee_dom_prefs)")
        sr.pv.unset("$xavp(caller_contract_prefs)")
        sr.pv.unset("$xavp(callee_contract_prefs)")
        sr.pv.unset("$xavp(caller_prof_prefs)")
        sr.pv.unset("$xavp(callee_prof_prefs)")
        sr.pv.unset("$xavp(caller_prof_prefs)")
        sr.pv.unset("$xavp(callee_prof_prefs)")
        sr.pv.unset("$xavp(caller_usr_prefs)")
        sr.pv.unset("$xavp(callee_usr_prefs)")
        sr.pv.unset("$xavp(caller_real_prefs)")
        sr.pv.unset("$xavp(callee_real_prefs)")
        sr.log("info", "---TestNGCPContractPrefs::cleaned---")
    end

    function TestNGCPContractPrefs:test_init()
        --print("TestNGCPContractPrefs:test_init")
        assertEquals(self.d.db_table, "contract_preferences")
    end

    function TestNGCPContractPrefs:test_caller_load_empty()
        assertEvalToTrue(self.d.config)
        assertEquals(self.d:caller_load(), {})
    end

    function TestNGCPContractPrefs:test_callee_load_empty()
        assertEvalToTrue(self.d.config)
        assertEquals(self.d:callee_load(), {})
    end

    function TestNGCPContractPrefs:test_caller_load()
        assertEvalToTrue(self.d.config)
        con:execute("SELECT * FROM contract_preferences WHERE uuid ='1' AND location_id IS NULL")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(cp_vars:val("cp_1"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:caller_load("1")
        mc:verify()

        assertItemsEquals(keys, {"sst_enable"})
        assertEquals(sr.pv.get("$xavp(caller_contract_prefs=>sst_enable)"),"no")
        assertNil(sr.pv.get("$xavp(callee_contract_prefs=>location_id)"))
    end

    function TestNGCPContractPrefs:test_callee_load()
        assertEvalToTrue(self.d.config)
        con:execute("SELECT location_id FROM provisioning.voip_contract_locations cl JOIN provisioning.voip_contract_location_blocks cb ON cb.location_id = cl.id WHERE cl.contract_id = 2 AND _ipv4_net_from <= UNHEX(HEX(INET_ATON('172.16.15.1'))) AND _ipv4_net_to >= UNHEX(HEX(INET_ATON('172.16.15.1'))) ORDER BY cb.ip DESC, cb.mask DESC LIMIT 1")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns({location_id = 1 })
        self.cur:close()
        con:execute("SELECT * FROM contract_preferences WHERE uuid ='2' AND location_id = 1")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(cp_vars:val("cp_2"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:callee_load("2", '172.16.15.1')
        mc:verify()

        assertItemsEquals(keys, {"sst_enable"})
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>sst_enable)"),"yes")
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>location_id)"),1)
    end

    function TestNGCPContractPrefs:test_clean()
        local xavp = NGCPContractPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
        self.d:clean()
        assertEquals(sr.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
        assertNil(sr.pv.get("$xavp(prof)"))
    end

    function TestNGCPContractPrefs:test_callee_clean()
        local callee_xavp = NGCPContractPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPContractPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_contract_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_contract_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
        self.d:clean('callee')
        assertEquals(sr.pv.get("$xavp(caller_contract_prefs=>dummy)"),'caller')
        assertNil(sr.pv.get("$xavp(callee_contract_prefs=>testid)"))
        assertNil(sr.pv.get("$xavp(callee_contract_prefs=>foo)"))
        assertEquals(sr.pv.get("$xavp(caller_contract_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_contract_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
    end

    function TestNGCPContractPrefs:test_caller_clean()
        local callee_xavp = NGCPContractPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPContractPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_contract_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_contract_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
        self.d:clean('caller')
        assertEquals(sr.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        assertNil(sr.pv.get("$xavp(caller_contract_prefs=>other)"))
        assertNil(sr.pv.get("$xavp(caller_contract_prefs=>otherfoo)"))
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
    end

    function TestNGCPContractPrefs:test_tostring()
        local callee_xavp = NGCPContractPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPContractPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(tostring(self.d), 'caller_contract_prefs:{other={1},otherfoo={"foo"},dummy={"caller"}}\ncallee_contract_prefs:{dummy={"callee"},testid={1},foo={"foo"}}\n')
    end
-- class TestNGCPContractPrefs
--EOF
