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

describe("user preferences", function()
    local NGCPUserPrefs
    local up_vars, utable
    local env, con
    local config
    local up

    setup(function()
        local utils = require 'ngcp.utils'
        utable = utils.table
        local UPFetch = require 'tests_v.up_vars'
        local ksrMock = require 'mocks.ksr'
        _G.KSR = ksrMock.new()
        package.loaded.luasql = nil
        package.preload['luasql.mysql'] = function ()
            local luasql = {}
            luasql.mysql = function ()
                return env
            end
        end
        up_vars = UPFetch:new()
    end)

    before_each(function()
        env = mock()
        local NGCPConfig = require 'ngcp.config'
        NGCPUserPrefs = require 'ngcp.up'

        config = NGCPConfig:new()
        config.env = env
        config.getDBConnection = function ()
            return con
        end

        up = NGCPUserPrefs:new(config)
    end)

    after_each(function()
        _G.KSR.pv.vars = {}
        up_vars:reset()
    end)

    it("caller_load empty", function()
        assert.not_nil(up.config)
        assert.same(up:caller_load(), {})
    end)

    it("callee_load empty", function()
        assert.not_nil(up.config)
        assert.same(up:callee_load(), {})
    end)

    it("init values", function()
        assert.same('usr_prefs', up.group)
        assert.not_nil(up.query)
        assert.not_nil(up.config)
        assert.same('NGCPUserPrefs', up.__class__)
        assert.same("usr_preferences", up.db_table)
    end)

    it("query format", function()
        local query = up.query:format(up.db_table, "uuid")
        assert.same( query,
            "SELECT * FROM usr_preferences WHERE uuid ='uuid' ORDER BY id DESC"
        )
    end)

    local function get_defaults(level, set)
        local keys_expected = {}
        local defaults = up.config:get_defaults('usr')

        if set then
            keys_expected = utable.deepcopy(set)
            for _,v in pairs(keys_expected) do
                _G.KSR.log("dbg", string.format("removed key:%s is been loaded.", v))
                defaults[v] = nil
            end
        end

        for k,v in pairs(defaults) do
            utable.add(keys_expected, k)
            assert.same(_G.KSR.pv.get("$xavp("..level.."_usr_prefs=>"..k..")"), v)
        end
        return keys_expected
    end

    local function fake_db()
        local count = 0
        local cur = {
            fetch = function()
                if count < 4 then
                    count = count + 1
                    return up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c")
                end
            end,
            close = function() end
        }
        local t_con = {
            execute = function(_, query)
                local expected = "SELECT * FROM usr_preferences WHERE " ..
                    "uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c' ORDER BY id DESC"
                assert.same(expected, query)
                return mock(cur)
            end
        }
        con = mock(t_con)
        return cur
    end

    local function check_load(level, keys)
        local lkeys = {
            "ext_subscriber_id",
            "ringtimeout",
            "account_id",
            "ext_contract_id",
            "cli",
            "cc",
            "ac"
        }
        local skey = "$xavp(%s_usr_prefs=>%s)"

        assert.equal_items(lkeys, keys)
        assert.same(_G.KSR.pv.get(skey:format(level, "account_id")), 2)
        assert.same(_G.KSR.pv.get(skey:format(level, "cli")), "4311001")
        assert.same(_G.KSR.pv.get(skey:format(level, "cc")), "43")
        assert.same(_G.KSR.pv.get(skey:format(level, "ac")), "1")
        local expected = get_defaults(level, {"account_id", "cli", "cc", "ac", "ringtimeout"})
        assert.equal_items(expected, keys)
    end

    it("caller_load", function()
        local cur = fake_db()
        assert.not_nil(up.config)
        local keys = up:caller_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        assert.spy(cur.close).was.called()
        check_load("caller", keys)
    end)

    it("callee_load", function()
        local cur = fake_db()
        assert.not_nil(up.config)
        local keys = up:callee_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        assert.spy(cur.close).was.called()
        check_load("callee", keys)
    end)

    it("clean", function()
        local xavp = NGCPUserPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        up:clean()
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"), "callee")
    end)

    it("callee_clean", function()
        local callee_xavp = NGCPUserPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPUserPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
        up:clean('callee')
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),'caller')
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_usr_prefs=>testid)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_usr_prefs=>foo)"))
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
    end)

    it("caller_clean", function()
        local callee_xavp = NGCPUserPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPUserPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
        up:clean('caller')
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"),"caller")
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_usr_prefs=>other)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_usr_prefs=>otherfoo)"))
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_usr_prefs=>dummy)"),"callee")
    end)

    --[[
    Lua provides a pairs() function to create the explist information for us
    to iterate over a table. The pairs() function will allow iteration over
    key-value pairs. Note that the order that items are returned is not defined,
    not even for indexed tables.
    --]]
    local function check_tostring(str)
        local r = 'caller_usr_prefs:{(.+)}\ncallee_usr_prefs:{(.+)}\n'
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
        local callee_xavp = NGCPUserPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPUserPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")

        -- can't check the whole string
        check_tostring(up:__tostring())
        check_tostring(tostring(up))
    end)

end)
