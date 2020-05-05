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

describe("domain preferences", function()
    local NGCPDomainPrefs
    local dp_vars, utable
    local env, con
    local config
    local dom

    setup(function()
        local utils = require 'ngcp.utils'
        utable = utils.table
        local DPFetch = require 'tests_v.dp_vars'
        local ksrMock = require 'mocks.ksr'
        _G.KSR = ksrMock.new()
        package.loaded.luasql = nil
        package.preload['luasql.mysql'] = function () end
        dp_vars = DPFetch:new()
    end)

    before_each(function()
        env = mock()
        local NGCPConfig = require 'ngcp.config'
        NGCPDomainPrefs = require 'ngcp.dp'

        config = NGCPConfig:new()
        config.env = env
        config.getDBConnection = function ()
            return con
        end

        dom = NGCPDomainPrefs:new(config)
    end)

    after_each(function()
        _G.KSR.pv.vars = {}
        dp_vars:reset()
    end)

    it("caller_load empty", function()
        assert.not_nil(dom.config)
        assert.same(dom:caller_load(), {})
    end)

    it("callee_load empty", function()
        assert.not_nil(dom.config)
        assert.same(dom:callee_load(), {})
    end)

    it("init values", function()
        assert.same(dom.db_table, "dom_preferences")
    end)

    local function get_defaults()
        local keys_expected = {"sst_enable", "sst_refresh_method"}
        local defaults = dom.config:get_defaults('dom')

        for k,_ in pairs(defaults) do
            utable.add(keys_expected, k)
        end
        return keys_expected
    end

    local function fake_db()
        local count = 0
        local cur = {
            fetch = function()
                if count < 2 then
                    count = count + 1
                    return dp_vars:val("d_192_168_51_56")
                end
            end,
            close = function() end
        }
        local t_con = {
            execute = function(_, query)
                local expected = "SELECT * FROM dom_preferences WHERE domain ='192.168.51.56'"
                assert.same(expected, query)
                return mock(cur)
            end
        }
        con = mock(t_con)
        return cur
    end

    local function check_load(level, keys)
        local skey = "$xavp(%s_dom_prefs=>%s)"

        assert.same(level, _G.KSR.pv.get(skey:format(level, "dummy")))
        assert.same(_G.KSR.pv.get(skey:format(level, "sst_enable")), "no")
        assert.same(
            _G.KSR.pv.get(skey:format(level, "sst_refresh_method")),
            "UPDATE_FALLBACK_INVITE"
        )
        assert.equal_items(get_defaults(), keys)
    end

    it("caller_load", function()
        local cur = fake_db()
        assert.not_nil(dom.config)
        local keys = dom:caller_load('192.168.51.56')
        assert.spy(cur.close).was.called()
        check_load("caller", keys)
    end)

    it("callee_load", function()
        local cur = fake_db()
        assert.not_nil(dom.config)
        local keys = dom:callee_load('192.168.51.56')
        assert.spy(cur.close).was.called()
        check_load("callee", keys)
    end)

    it("clean", function()
        local xavp = NGCPDomainPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>dummy)"),"caller")
        dom:clean()
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>dummy)"), "caller")
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>dummy)"), "callee")
        assert.is_nil(_G.KSR.pv.get("$xavp(dom)"))
    end)

    it("callee_clean", function()
        local callee_xavp = NGCPDomainPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPDomainPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        dom:clean('callee')
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>dummy)"),'caller')
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_dom_prefs=>testid)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_dom_prefs=>foo)"))
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
    end)

    it("caller_clean", function()
        local callee_xavp = NGCPDomainPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPDomainPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
        dom:clean('caller')
        assert.same(_G.KSR.pv.get("$xavp(caller_dom_prefs=>dummy)"),"caller")
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_dom_prefs=>other)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_dom_prefs=>otherfoo)"))
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_dom_prefs=>dummy)"),"callee")
    end)

    --[[
    Lua provides a pairs() function to create the explist information for us
    to iterate over a table. The pairs() function will allow iteration over
    key-value pairs. Note that the order that items are returned is not defined,
    not even for indexed tables.
    --]]
    local function check_tostring(str)
        local r = 'caller_dom_prefs:{(.+)}\ncallee_dom_prefs:{(.+)}\n'
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
        local callee_xavp = NGCPDomainPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPDomainPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")

        -- can't check the whole string
        check_tostring(tostring(dom))
    end)

end)
