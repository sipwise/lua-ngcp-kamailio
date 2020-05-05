--
-- Copyright 2020 SipWise Team <development@sipwise.com>
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

describe("real preferences", function()
    local NGCPDomainPrefs = require 'ngcp.dp'
    local NGCPUserPrefs = require 'ngcp.up'
    local NGCPPeerPrefs = require 'ngcp.pp'
    local NGCPRealPrefs = require 'ngcp.rp'
    local real

    setup(function()
        local ksrMock = require 'mocks.ksr'
        _G.KSR = ksrMock.new()
    end)

    before_each(function()
        real = NGCPRealPrefs:new()
    end)

    after_each(function()
        _G.KSR.pv.vars = {}
    end)

    it("caller_load empty", function()
        assert.has_error(function() real.caller_load(nil) end)
    end)

    it("callee_load empty", function()
        assert.has_error(function() real.callee_load(nil) end)
    end)

    it("caller_peer_load", function()
        local keys = {"uno"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("caller"),
            user    = NGCPUserPrefs:xavp("caller"),
            peer    = NGCPPeerPrefs:xavp("caller"),
            real    = NGCPRealPrefs:xavp("caller")
        }
        xavp.domain("uno",1)
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>uno)"),1)
        xavp.user("uno",2)
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>uno)"),2)
        xavp.peer("uno",3)
        local real_keys = real:caller_peer_load(keys)
        assert.same(real_keys, keys)
        assert.same(xavp.real("uno"),nil)
        assert.same(xavp.peer("uno"),3)
    end)

    it("caller_usr_load", function()
        local keys = {"uno"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("caller"),
            user    = NGCPUserPrefs:xavp("caller"),
            real    = NGCPRealPrefs:xavp("caller")
        }
        xavp.domain("uno",1)
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>uno)"),1)
        xavp.user("uno",2)
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>uno)"),2)
        local real_keys = real:caller_usr_load(keys)
        assert.same(real_keys, keys)
        assert.same(xavp.real("uno"),2)
    end)

    it("caller_usr_load1", function()
        local keys = {"uno", "dos"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("caller"),
            user    = NGCPUserPrefs:xavp("caller"),
            real    = NGCPRealPrefs:xavp("caller")
        }
        xavp.domain("uno",1)
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>uno)"),1)
        xavp.user("dos",2)
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>dos)"),2)
        local real_keys = real:caller_usr_load(keys)
        assert.equal_items(real_keys, keys)
        assert.same(xavp.real("uno"),1)
        assert.same(xavp.real("dos"),2)
    end)

    it("callee_usr_load", function()
        local keys = {"uno"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("callee"),
            user    = NGCPUserPrefs:xavp("callee"),
            real    = NGCPRealPrefs:xavp("callee")
        }
        xavp.domain("uno",1)
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>uno)"),1)
        xavp.user("uno",2)
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>uno)"),2)
        local real_keys = real:callee_usr_load(keys)
        assert.same(real_keys, keys)
        assert.same(xavp.real("uno"),2)
    end)

    it("callee_usr_load1", function()
        local keys = {"uno", "dos"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("callee"),
            user    = NGCPUserPrefs:xavp("callee"),
            real    = NGCPRealPrefs:xavp("callee")
        }
        xavp.domain("uno",1)
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>uno)"),1)
        xavp.user("dos",2)
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>dos)"),2)
        local real_keys = real:callee_usr_load(keys)
        assert.equal_items(real_keys, keys)
        assert.same(xavp.real("uno"),1)
        assert.same(xavp.real("dos"),2)
    end)

    it("set", function()
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>dummy)"), "caller")
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_real_prefs=>testid)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_real_prefs=>foo)"))

        local callee_xavp = NGCPRealPrefs:xavp("callee")
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),'callee')

        callee_xavp("testid", 1)
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>testid)"), 1)
        callee_xavp("foo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
    end)

    it("clean", function()
        local callee_xavp = NGCPRealPrefs:xavp("callee")
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),'callee')

        callee_xavp("testid",1)
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>testid)"),1)
        callee_xavp("foo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")

        real:clean()

        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
    end)

    it("callee_clean", function()
        local callee_xavp = NGCPRealPrefs:xavp("callee")
        local caller_xavp = NGCPRealPrefs:xavp("caller")

        callee_xavp("testid",1)
        callee_xavp("foo","foo")

        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")

        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")

        real:clean('callee')

        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),'caller')
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_real_prefs=>testid)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_real_prefs=>foo)"))
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
    end)

    it("caller_clean", function()
        local callee_xavp = NGCPRealPrefs:xavp("callee")
        local caller_xavp = NGCPRealPrefs:xavp("caller")

        callee_xavp("testid",1)
        callee_xavp("foo","foo")

        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")

        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")

        real:clean('caller')

        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_real_prefs=>other)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_real_prefs=>otherfoo)"))
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
    end)

    --[[
    Lua provides a pairs() function to create the explist information for us
    to iterate over a table. The pairs() function will allow iteration over
    key-value pairs. Note that the order that items are returned is not defined,
    not even for indexed tables.
    --]]
    local function check_tostring(str)
        local r = 'caller_real_prefs:{(.+)}\ncallee_real_prefs:{(.+)}\n'
        local caller, callee = str:match(r)
        assert.not_nil(caller)
        assert.same('"caller"', caller:match('dummy={([^}]+)}'))
        assert.same('1', caller:match('other={([^}]+)}'))
        assert.same('"foo"', caller:match('otherfoo={([^}]+)}'))
        assert.not_nil(callee)
        assert.same('"callee"', callee:match('dummy={([^}]+)}'))
        assert.same('1', callee:match('testid={([^}]+)}'))
        assert.same('"foo"', callee:match('foo={([^}]+)}'))
    end

    it("tostring", function()
        local callee_xavp = NGCPRealPrefs:xavp("callee")
        local caller_xavp = NGCPRealPrefs:xavp("caller")
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")

        -- can't check the whole string
        check_tostring(tostring(real))
    end)

end)
