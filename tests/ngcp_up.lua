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
local utils = require 'ngcp.utils'
local utable = utils.table
local UPFetch = require 'tests_v.up_vars'

local ksrMock = require 'mocks.ksr'
KSR = ksrMock.new()

local mc,env,con
local up_vars = UPFetch:new()

package.loaded.luasql = nil
package.preload['luasql.mysql'] = function ()
    local luasql = {}
    luasql.mysql = function ()
        return env
    end
end

local NGCPConfig = require 'ngcp.config'
local NGCPUserPrefs = require 'ngcp.up'
-- luacheck: ignore TestNGCPUserPrefs
TestNGCPUserPrefs = {} --class

    function TestNGCPUserPrefs:setUp()
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

        self.d = NGCPUserPrefs:new(self.config)
        up_vars:reset()
    end

    function TestNGCPUserPrefs:tearDown()
        KSR.pv.vars = {}
    end

    function TestNGCPUserPrefs:test_caller_load_empty()
        assertEvalToTrue(self.d.config)
        assertEquals(self.d:caller_load(), {})
    end

    function TestNGCPUserPrefs:test_callee_load_empty()
        assertEvalToTrue(self.d.config)
        assertEquals(self.d:callee_load(), {})
    end

    function TestNGCPUserPrefs:test_init()
        --print("TestNGCPUserPrefs:test_init")
        assertEquals(self.d.db_table, "usr_preferences")
    end

    function TestNGCPUserPrefs:get_defaults(level, set)
        local keys_expected = {}
        local defaults = self.d.config:get_defaults('usr')

        if set then
            keys_expected = utable.deepcopy(set)
            for _,v in pairs(keys_expected) do
                KSR.log("dbg", string.format("removed key:%s is been loaded.", v))
                defaults[v] = nil
            end
        end

        for k,v in pairs(defaults) do
            utable.add(keys_expected, k)
            assertEquals(KSR.pv.get("$xavp("..level.."_usr_prefs=>"..k..")"), v)
        end
        return keys_expected
    end

    function TestNGCPUserPrefs:test_caller_load()
        assertEvalToTrue(self.d.config)
        con:execute("SELECT * FROM usr_preferences WHERE uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c' ORDER BY id DESC")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:caller_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        mc:verify()

        local lkeys = {
            "ext_subscriber_id",
            "ringtimeout",
            "account_id",
            "ext_contract_id",
            "cli",
            "cc",
            "ac"
        }

        assertItemsEquals(keys, lkeys)
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>account_id)"),2)
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>cli)"),"4311001")
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>cc)"),"43")
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>ac)"),"1")
        --assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>ringtimeout)"), self.d.config.default.usr.ringtimeout)
        assertItemsEquals(keys, TestNGCPUserPrefs:get_defaults("caller", {"account_id", "cli", "cc", "ac", "ringtimeout"}))
    end

    function TestNGCPUserPrefs:test_callee_load()
        assertEvalToTrue(self.d.config)
        con:execute("SELECT * FROM usr_preferences WHERE uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c' ORDER BY id DESC")  ;mc :returns(self.cur)
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(nil)
        self.cur:close()

        mc:replay()
        local keys = self.d:callee_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        mc:verify()

        local lkeys = {
            "ext_subscriber_id",
            "ringtimeout",
            "account_id",
            "ext_contract_id",
            "cli",
            "cc",
            "ac"
        }

        assertItemsEquals(keys, lkeys)
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>account_id)"),2)
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>cli)"),"4311001")
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>cc)"),"43")
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>ac)"),"1")
        --assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>ringtimeout)"), self.d.config.default.usr.ringtimeout)
        assertItemsEquals(keys, TestNGCPUserPrefs:get_defaults("callee", {"account_id", "cli", "cc", "ac", "ringtimeout"}))
    end

    function TestNGCPUserPrefs:test_clean()
        local xavp = NGCPUserPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        self.d:clean()
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"), "callee")
    end

    function TestNGCPUserPrefs:test_callee_clean()
        local callee_xavp = NGCPUserPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPUserPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>other)"),1)
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>otherfoo)"),"foo")
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
        self.d:clean('callee')
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),'caller')
        assertNil(KSR.pv.get("$xavp(callee_usr_prefs=>testid)"))
        assertNil(KSR.pv.get("$xavp(callee_usr_prefs=>foo)"))
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>other)"),1)
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>otherfoo)"),"foo")
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
    end

    function TestNGCPUserPrefs:test_caller_clean()
        local callee_xavp = NGCPUserPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPUserPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>other)"),1)
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>otherfoo)"),"foo")
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
        self.d:clean('caller')
        assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assertNil(KSR.pv.get("$xavp(caller_usr_prefs=>other)"))
        assertNil(KSR.pv.get("$xavp(caller_usr_prefs=>otherfoo)"))
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
    end

    function TestNGCPUserPrefs:test_tostring()
        local callee_xavp = NGCPUserPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPUserPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(tostring(self.d), 'caller_usr_prefs:{other={1},otherfoo={"foo"},dummy={"caller"}}\ncallee_usr_prefs:{dummy={"callee"},testid={1},foo={"foo"}}\n')
    end
-- class TestNGCPUserPrefs
