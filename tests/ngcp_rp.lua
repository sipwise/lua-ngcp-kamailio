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
local NGCPDomainPrefs = require 'ngcp.dp'
local NGCPUserPrefs = require 'ngcp.up'
local NGCPPeerPrefs = require 'ngcp.pp'
local NGCPRealPrefs = require 'ngcp.rp'

local ksrMock = require 'mocks.ksr'
KSR = ksrMock.new()

-- luacheck: ignore TestNGCPRealPrefs
TestNGCPRealPrefs = {} --class

    function TestNGCPRealPrefs:setUp()
        self.real = NGCPRealPrefs:new()
    end

    function TestNGCPRealPrefs:tearDown()
       KSR.pv.vars = {}
    end

    function TestNGCPRealPrefs:test_caller_load_empty()
        lu.assertError(self.real.caller_load, nil)
    end

    function TestNGCPRealPrefs:test_callee_load_empty()
        lu.assertError(self.real.callee_load, nil)
    end

    function TestNGCPRealPrefs:test_caller_mix_load()
        local keys = {"uno"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("caller"),
            user    = NGCPUserPrefs:xavp("caller"),
            peer    = NGCPPeerPrefs:xavp("caller"),
            real    = NGCPRealPrefs:xavp("caller")
        }
        xavp.user("uno",1)
        local real_keys = self.real:caller_usr_load(keys)
        lu.assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>uno)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_prefs=>uno)"),1)

        xavp.peer("uno",3)
        real_keys = self.real:caller_peer_load(keys)
        lu.assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>uno)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_peer_prefs=>uno)"),3)
        lu.assertEquals(KSR.pv.get("$xavp(caller_prefs=>uno)"),3)
    end

    function TestNGCPRealPrefs:test_caller_peer_load()
        local keys = {"uno"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("caller"),
            user    = NGCPUserPrefs:xavp("caller"),
            peer    = NGCPPeerPrefs:xavp("caller"),
            real    = NGCPRealPrefs:xavp("caller")
        }
        xavp.domain("uno",1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>uno)"),1)
        xavp.user("uno",2)
        lu.assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>uno)"),2)
        xavp.peer("uno",3)

        lu.assertIsNil(KSR.pv.get("$xavp(caller_prefs=>dummy)"))

        local real_keys = self.real:caller_peer_load(keys)
        lu.assertEquals(real_keys, keys)
        lu.assertEquals(xavp.real("uno"),nil)
        lu.assertEquals(xavp.peer("uno"),3)

        lu.assertEquals(KSR.pv.get("$xavp(caller_prefs=>uno)"),3)
    end

    function TestNGCPRealPrefs:test_caller_usr_load()
        local keys = {"uno"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("caller"),
            user    = NGCPUserPrefs:xavp("caller"),
            real    = NGCPRealPrefs:xavp("caller")
        }
        xavp.domain("uno",1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>uno)"),1)
        xavp.user("uno",2)
        lu.assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>uno)"),2)

        lu.assertIsNil(KSR.pv.get("$xavp(caller_prefs=>dummy)"))

        local real_keys = self.real:caller_usr_load(keys)
        lu.assertEquals(real_keys, keys)
        lu.assertEquals(xavp.real("uno"),2)
        lu.assertEquals(KSR.pv.get("$xavp(caller_prefs=>uno)"),2)
    end

    function TestNGCPRealPrefs:test_caller_usr_load1()
        local keys = {"uno", "dos"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("caller"),
            user    = NGCPUserPrefs:xavp("caller"),
            real    = NGCPRealPrefs:xavp("caller")
        }
        xavp.domain("uno",1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_dom_prefs=>uno)"),1)
        xavp.user("dos",2)
        lu.assertEquals(KSR.pv.get("$xavp(caller_usr_prefs=>dos)"),2)

        lu.assertIsNil(KSR.pv.get("$xavp(caller_prefs=>dummy)"))

        local real_keys = self.real:caller_usr_load(keys)
        lu.assertItemsEquals(real_keys, keys)
        lu.assertEquals(xavp.real("uno"),1)
        lu.assertEquals(xavp.real("dos"),2)
        lu.assertEquals(KSR.pv.get("$xavp(caller_prefs=>uno)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_prefs=>dos)"),2)
    end

    function TestNGCPRealPrefs:test_callee_usr_load()
        local keys = {"uno"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("callee"),
            user    = NGCPUserPrefs:xavp("callee"),
            real    = NGCPRealPrefs:xavp("callee")
        }
        xavp.domain("uno",1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>uno)"),1)
        xavp.user("uno",2)
        lu.assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>uno)"),2)

        lu.assertIsNil(KSR.pv.get("$xavp(callee_prefs=>dummy)"))

        local real_keys = self.real:callee_usr_load(keys)
        lu.assertEquals(real_keys, keys)
        lu.assertEquals(xavp.real("uno"),2)
        lu.assertEquals(KSR.pv.get("$xavp(callee_prefs=>uno)"),2)
    end

    function TestNGCPRealPrefs:test_callee_usr_load1()
        local keys = {"uno", "dos"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("callee"),
            user    = NGCPUserPrefs:xavp("callee"),
            real    = NGCPRealPrefs:xavp("callee")
        }
        xavp.domain("uno",1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_dom_prefs=>uno)"),1)
        xavp.user("dos",2)
        lu.assertEquals(KSR.pv.get("$xavp(callee_usr_prefs=>dos)"),2)

        lu.assertIsNil(KSR.pv.get("$xavp(callee_prefs=>dummy)"))

        local real_keys = self.real:callee_usr_load(keys)
        lu.assertItemsEquals(real_keys, keys)
        lu.assertEquals(xavp.real("uno"),1)
        lu.assertEquals(xavp.real("dos"),2)
        lu.assertEquals(KSR.pv.get("$xavp(callee_prefs=>uno)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_prefs=>dos)"),2)
    end

    function TestNGCPRealPrefs:test_set()
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>dummy)"), "caller")
        lu.assertNil(KSR.pv.get("$xavp(callee_real_prefs=>testid)"))
        lu.assertNil(KSR.pv.get("$xavp(callee_real_prefs=>foo)"))

        local callee_xavp = NGCPRealPrefs:xavp("callee")
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),'callee')

        callee_xavp("testid", 1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>testid)"), 1)
        callee_xavp("foo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
    end

    function TestNGCPRealPrefs:test_clean()
        local callee_xavp = NGCPRealPrefs:xavp("callee")
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),'callee')

        callee_xavp("testid",1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>testid)"),1)
        callee_xavp("foo","foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")

        self.real:clean()

        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
    end

    function TestNGCPRealPrefs:test_callee_clean()
        local callee_xavp = NGCPRealPrefs:xavp("callee")
        local caller_xavp = NGCPRealPrefs:xavp("caller")

        callee_xavp("testid",1)
        callee_xavp("foo","foo")

        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")

        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")

        self.real:clean('callee')

        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),'caller')
        lu.assertNil(KSR.pv.get("$xavp(callee_real_prefs=>testid)"))
        lu.assertNil(KSR.pv.get("$xavp(callee_real_prefs=>foo)"))
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
    end

    function TestNGCPRealPrefs:test_caller_clean()
        local callee_xavp = NGCPRealPrefs:xavp("callee")
        local caller_xavp = NGCPRealPrefs:xavp("caller")

        callee_xavp("testid",1)
        callee_xavp("foo","foo")

        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")

        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>other)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>otherfoo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")

        self.real:clean('caller')

        lu.assertEquals(KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        lu.assertNil(KSR.pv.get("$xavp(caller_real_prefs=>other)"))
        lu.assertNil(KSR.pv.get("$xavp(caller_real_prefs=>otherfoo)"))
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>testid)"),1)
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
        lu.assertEquals(KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
    end

    function TestNGCPRealPrefs:test_tostring()
        local callee_xavp = NGCPRealPrefs:xavp("callee")
        local caller_xavp = NGCPRealPrefs:xavp("caller")
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        lu.assertEquals(tostring(self.real),'caller_real_prefs:{other={1},otherfoo={"foo"},dummy={"caller"}}\ncallee_real_prefs:{dummy={"callee"},testid={1},foo={"foo"}}\n')
    end
-- class TestNGCPRealPrefs
--EOF
