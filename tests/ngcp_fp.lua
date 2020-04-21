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
local FPFetch = require 'tests_v.fp_vars'

local ksrMock = require 'mocks.ksr'
KSR = ksrMock.new()

local mc,env,con
local fp_vars = FPFetch:new()

package.loaded.luasql = nil
package.preload['luasql.mysql'] = function ()
    local luasql = {}
    luasql.mysql = function ()
        return env
    end
end
local NGCPConfig = require 'ngcp.config'
local NGCPFaxPrefs = require 'ngcp.fp'
-- luacheck: ignore TestNGCPFaxPrefs
TestNGCPFaxPrefs = {} --class

    function TestNGCPFaxPrefs:setUp()
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

        self.d = NGCPFaxPrefs:new(self.config)
    end

    function TestNGCPFaxPrefs:tearDown()
        KSR.pv.vars = {}
    end

    function TestNGCPFaxPrefs:test_init()
        --print("TestNGCPFaxPrefs:test_init")
        lu.assertEquals(self.d.db_table, "provisioning.voip_fax_preferences")
    end

    function TestNGCPFaxPrefs:test_caller_load_empty()
        lu.assertNotNil(self.d.config)
        lu.assertEquals(self.d:caller_load(), {})
    end

    function TestNGCPFaxPrefs:test_callee_load_empty()
        lu.assertNotNil(self.d.config)
        lu.assertEquals(self.d:callee_load(), {})
    end

    function TestNGCPFaxPrefs:test_caller_load()
        lu.assertNotNil(self.d.config)
        con:execute("SELECT fp.* FROM provisioning.voip_fax_preferences fp, provisioning.voip_subscribers s WHERE s.uuid = 'ah736f72-21d1-4ea6-a3ea-4d7f56b3887c' AND fp.subscriber_id = s.id")  ;mc :returns(self.cur)
        self.cur:getcolnames()        ;mc :returns(fp_vars:val("fp_keys"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(fp_vars:val("fp_1"))
        self.cur:close()

        mc:replay()
        local keys = self.d:caller_load("ah736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        mc:verify()

        for k,v in pairs(fp_vars:val("fp_keys")) do
            lu.assertEquals(keys[k], v)
        end

        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"), "caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>active)"), 1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>t38)"), 1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>ecm)"), 1)
    end

    function TestNGCPFaxPrefs:test_callee_load()
        lu.assertNotNil(self.d.config)
        con:execute("SELECT fp.* FROM provisioning.voip_fax_preferences fp, provisioning.voip_subscribers s WHERE s.uuid = 'ah736f72-21d1-4ea6-a3ea-4d7f56b3887c' AND fp.subscriber_id = s.id") ;mc :returns(self.cur)
        self.cur:getcolnames()        ;mc :returns(fp_vars:val("fp_keys"))
        self.cur:fetch(mc.ANYARGS)    ;mc :returns(fp_vars:val("fp_2"))
        self.cur:close()

        mc:replay()
        local keys = self.d:callee_load("ah736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        mc:verify()

        for k,v in pairs(fp_vars:val("fp_keys")) do
            lu.assertEquals(keys[k], v)
        end

        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"), "callee")
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>active)"), 1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>t38)"), 0)
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>ecm)"), 0)
    end

    function TestNGCPFaxPrefs:test_clean()
        local xavp = NGCPFaxPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"),"callee")
        self.d:clean()
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"),"callee")
        lu.assertNil(KSR.pv.get("$xavp(fax)"))
    end

    function TestNGCPFaxPrefs:test_callee_clean()
        local callee_xavp = NGCPFaxPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPFaxPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"),"callee")
        self.d:clean('callee')
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"),'caller')
        lu.assertNil(KSR.pv.get("$xavp(callee_fax_prefs=>testid)"))
        lu.assertNil(KSR.pv.get("$xavp(callee_fax_prefs=>foo)"))
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"),"callee")
    end

    function TestNGCPFaxPrefs:test_caller_clean()
        local callee_xavp = NGCPFaxPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPFaxPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"),"callee")
        self.d:clean('caller')
        lu.assertEquals(KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"),"caller")
        lu.assertNil(KSR.pv.get("$xavp(caller_fax_prefs=>other)"))
        lu.assertNil(KSR.pv.get("$xavp(caller_fax_prefs=>otherfoo)"))
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"),"callee")
    end

    function TestNGCPFaxPrefs:test_tostring()
        local callee_xavp = NGCPFaxPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPFaxPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(tostring(self.d), 'caller_fax_prefs:{other={1},otherfoo={"foo"},dummy={"caller"}}\ncallee_fax_prefs:{dummy={"callee"},testid={1},foo={"foo"}}\n')
    end
-- class TestNGCPFaxPrefs
--EOF
