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

describe("profile preferences", function()
    local NGCPProfilePrefs
    local pprof_vars
    local env, con
    local config
    local prof

    setup(function()
        local PProfFetch = require 'tests_v.pprof_vars'
        local ksrMock = require 'mocks.ksr'
        _G.KSR = ksrMock.new()
        package.loaded.luasql = nil
        package.preload['luasql.mysql'] = function () end
        pprof_vars = PProfFetch:new()
    end)

    before_each(function()
        env = mock()
        local NGCPConfig = require 'ngcp.config'
        NGCPProfilePrefs = require 'ngcp.pprof'

        config = NGCPConfig:new()
        config.env = env
        config.getDBConnection = function ()
            return con
        end

        prof = NGCPProfilePrefs:new(config)
    end)

    after_each(function()
        _G.KSR.pv.vars = {}
        pprof_vars:reset()
    end)

    it("caller_load empty", function()
        assert.not_nil(prof.config)
        assert.same(prof:caller_load(), {})
    end)

    it("callee_load empty", function()
        assert.not_nil(prof.config)
        assert.same(prof:callee_load(), {})
    end)

    it("init values", function()
        assert.same(prof.db_table, "prof_preferences")
    end)

    local function fake_db()
        local count = 0
        local cur = {
            fetch = function()
                if count < 3 then
                    count = count + 1
                    return pprof_vars:val("prof_2")
                end
            end,
            close = function() end
        }
        local t_con = {
            execute = function(_, query)
                local expected = "SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN prof_preferences AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = 'ah736f72-21d1-4ea6-a3ea-4d7f56b3887c'"
                assert.same(expected, query)
                return mock(cur)
            end
        }
        con = mock(t_con)
        return cur
    end

    local function check_load(level, keys)
        local lkeys = {
            "sst_enable",
            "sst_refresh_method",
            "outbound_from_user"
        }
        local skey = "$xavp(%s_prof_prefs=>%s)"

        assert.equal_items(lkeys, keys)
        assert.same(level, _G.KSR.pv.get(skey:format(level, "dummy")))
        assert.same(_G.KSR.pv.get(skey:format(level, "sst_enable")), "yes")
        assert.same(
            _G.KSR.pv.get(skey:format(level, "sst_refresh_method")),
            "UPDATE_FALLBACK_INVITE"
        )
        assert.same(
            _G.KSR.pv.get(skey:format(level, "outbound_from_user")),
            "upn"
        )
    end

    it("caller_load", function()
        local cur = fake_db()
        assert.not_nil(prof.config)
        local keys = prof:caller_load('ah736f72-21d1-4ea6-a3ea-4d7f56b3887c')
        assert.spy(cur.close).was.called()
        check_load("caller", keys)
    end)

    it("callee_load", function()
        local cur = fake_db()
        assert.not_nil(prof.config)
        local keys = prof:callee_load('ah736f72-21d1-4ea6-a3ea-4d7f56b3887c')
        assert.spy(cur.close).was.called()
        check_load("callee", keys)
    end)

    it("clean", function()
        local xavp = NGCPProfilePrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_prof_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_prof_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_prof_prefs=>dummy)"),"caller")
        prof:clean()
        assert.same(_G.KSR.pv.get("$xavp(caller_prof_prefs=>dummy)"), "caller")
        assert.same(_G.KSR.pv.get("$xavp(callee_prof_prefs=>dummy)"), "callee")
        assert.is_nil(_G.KSR.pv.get("$xavp(prof)"))
    end)

    it("callee_clean", function()
        local callee_xavp = NGCPProfilePrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPProfilePrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_prof_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_prof_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_prof_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_prof_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_prof_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_prof_prefs=>dummy)"),"callee")
        prof:clean('callee')
        assert.same(_G.KSR.pv.get("$xavp(caller_prof_prefs=>dummy)"),'caller')
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_prof_prefs=>testid)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_prof_prefs=>foo)"))
        assert.same(_G.KSR.pv.get("$xavp(caller_prof_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_prof_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_prof_prefs=>dummy)"),"callee")
    end)

    it("caller_clean", function()
        local callee_xavp = NGCPProfilePrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPProfilePrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_prof_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_prof_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_prof_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_prof_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_prof_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_prof_prefs=>dummy)"),"callee")
        prof:clean('caller')
        assert.same(_G.KSR.pv.get("$xavp(caller_prof_prefs=>dummy)"),"caller")
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_prof_prefs=>other)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_prof_prefs=>otherfoo)"))
        assert.same(_G.KSR.pv.get("$xavp(callee_prof_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_prof_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_prof_prefs=>dummy)"),"callee")
    end)

    --[[
    Lua provides a pairs() function to create the explist information for us
    to iterate over a table. The pairs() function will allow iteration over
    key-value pairs. Note that the order that items are returned is not defined,
    not even for indexed tables.
    --]]
    local function check_tostring(str)
        local r = 'caller_prof_prefs:{(.+)}\ncallee_prof_prefs:{(.+)}\n'
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
        local callee_xavp = NGCPProfilePrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPProfilePrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")

        -- can't check the whole string
        check_tostring(tostring(prof))
    end)

end)
