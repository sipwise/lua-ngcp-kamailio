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

describe("contract preferences", function()
    local NGCPContractPrefs
    local cp_vars
    local env, con
    local config
    local contract

    setup(function()
        local CPFetch = require 'tests_v.cp_vars'
        local ksrMock = require 'mocks.ksr'
        _G.KSR = ksrMock.new()
        package.loaded.luasql = nil
        package.preload['luasql.mysql'] = function () end
        cp_vars = CPFetch:new()
    end)

    before_each(function()
        env = mock()
        local NGCPConfig = require 'ngcp.config'
        NGCPContractPrefs = require 'ngcp.cp'

        config = NGCPConfig:new()
        config.env = env
        config.getDBConnection = function ()
            return con
        end

        contract = NGCPContractPrefs:new(config)
    end)

    after_each(function()
        _G.KSR.pv.vars = {}
        cp_vars:reset()
    end)

    it("caller_load empty", function()
        assert.not_nil(contract.config)
        assert.same(contract:caller_load(), {})
    end)

    it("callee_load empty", function()
        assert.not_nil(contract.config)
        assert.same(contract:callee_load(), {})
    end)

    it("init values", function()
        assert.same(contract.db_table, "contract_preferences")
    end)

    local function check_load(level, keys)
        local lkeys = {
            "sst_enable",
        }
        local skey = "$xavp(%s_contract_prefs=>%s)"

        assert.equal_items(lkeys, keys)
        assert.same(level, _G.KSR.pv.get(skey:format(level, "dummy")))
        if level == 'caller' then
            assert.same(_G.KSR.pv.get(skey:format(level, "sst_enable")), "no")
            assert.is_nil(_G.KSR.pv.get(skey:format(level, "location_id")))
        else
            assert.same(_G.KSR.pv.get(skey:format(level, "sst_enable")), "yes")
            assert.same(_G.KSR.pv.get(skey:format(level, "location_id")), 1)
        end
    end

    local function fake_db_caller()
        local count = 0
        local cur = {
            fetch = function()
                if count < 1 then
                    count = count + 1
                    return cp_vars:val('cp_1')
                end
            end,
            close = function() end
        }
        local t_con = {
            execute = function(_, query)
                local expected = "SELECT * FROM contract_preferences WHERE uuid ='1' AND location_id IS NULL"
                assert.same(expected, query)
                return mock(cur)
            end
        }
        con = mock(t_con)
        return cur
    end

    it("caller_load", function()
        local cur = fake_db_caller()
        assert.not_nil(contract.config)
        local keys = contract:caller_load('1')
        assert.spy(cur.close).was.called()
        check_load("caller", keys)
    end)

    local function fake_db_callee()
        local count = 0
        local vals = {
            {location_id = 1 },
            cp_vars:val('cp_2'),
        }
        local cur = {
            fetch = function()
                count = count + 1
                return vals[count]
            end,
            close = function() end
        }
        local t_con = {
            execute = function(_, query)
                if count < 1 then
                    assert.same(
                        NGCPContractPrefs.query_location_id:format("2", "ipv4", "172.16.15.1", "ipv4", "172.16.15.1"),
                        query
                    )
                else
                    assert.same(
                        query,
                        "SELECT * FROM contract_preferences WHERE uuid ='2' AND location_id = 1"
                    )
                end
                return mock(cur)
            end
        }
        con = mock(t_con)
        return cur
    end

    it("callee_load", function()
        local cur = fake_db_callee()
        assert.not_nil(contract.config)
        local keys = contract:callee_load('2', '172.16.15.1')
        assert.spy(cur.close).was.called()
        check_load("callee", keys)
    end)

    it("clean", function()
        local xavp = NGCPContractPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_contract_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_contract_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        contract:clean()
        assert.same(_G.KSR.pv.get("$xavp(caller_contract_prefs=>dummy)"), "caller")
        assert.same(_G.KSR.pv.get("$xavp(callee_contract_prefs=>dummy)"), "callee")
        assert.is_nil(_G.KSR.pv.get("$xavp(contract)"))
    end)

    it("callee_clean", function()
        local callee_xavp = NGCPContractPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPContractPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_contract_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_contract_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_contract_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_contract_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
        contract:clean('callee')
        assert.same(_G.KSR.pv.get("$xavp(caller_contract_prefs=>dummy)"),'caller')
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_contract_prefs=>testid)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_contract_prefs=>foo)"))
        assert.same(_G.KSR.pv.get("$xavp(caller_contract_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_contract_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
    end)

    it("caller_clean", function()
        local callee_xavp = NGCPContractPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPContractPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_contract_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_contract_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_contract_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_contract_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
        contract:clean('caller')
        assert.same(_G.KSR.pv.get("$xavp(caller_contract_prefs=>dummy)"),"caller")
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_contract_prefs=>other)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_contract_prefs=>otherfoo)"))
        assert.same(_G.KSR.pv.get("$xavp(callee_contract_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_contract_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_contract_prefs=>dummy)"),"callee")
    end)

    --[[
    Lua provides a pairs() function to create the explist information for us
    to iterate over a table. The pairs() function will allow iteration over
    key-value pairs. Note that the order that items are returned is not defined,
    not even for indexed tables.
    --]]
    local function check_tostring(str)
        local r = 'caller_contract_prefs:{(.+)}\ncallee_contract_prefs:{(.+)}\n'
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
        local callee_xavp = NGCPContractPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPContractPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")

        -- can't check the whole string
        check_tostring(tostring(contract))
    end)

end)
