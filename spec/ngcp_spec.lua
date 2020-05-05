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

describe("NGCP preferences", function()
    local NGCP, NGCPConfig
    local vars
    local utable
    local con
    local ngcp

    setup(function()
        local utils = require 'ngcp.utils'
        utable = utils.table
        local DPFetch = require 'tests_v.dp_vars'
        local PPFetch = require 'tests_v.pp_vars'
        local PProfFetch = require 'tests_v.pprof_vars'
        local UPFetch = require 'tests_v.up_vars'
        local FPFetch = require 'tests_v.fp_vars'
        local ksrMock = require 'mocks.ksr'
        _G.KSR = ksrMock.new()
        package.loaded.luasql = nil
        package.preload['luasql.mysql'] = function()
            return function () return con end
        end
        NGCPConfig = require 'ngcp.config'
        vars = {
            dp_vars = DPFetch:new(),
            pp_vars = PPFetch:new(),
            up_vars = UPFetch:new(),
            pprof_vars = PProfFetch:new(),
            fp_vars = FPFetch:new(),
        }
        NGCP = require 'ngcp.ngcp'
    end)

    before_each(function()
        ngcp = NGCP:new()
    end)

    after_each(function()
        _G.KSR.pv.vars = {}
        for _, v in pairs(vars) do
            v:reset()
        end
    end)

    it("config values", function()
        assert.not_nil(ngcp.config)
        assert.is_nil(ngcp.config.env)
        assert.is_nil(ngcp.config.con)
    end)

    it("config_get_defaults_all", function()
        local defaults = NGCPConfig.get_defaults(ngcp.config, 'peer')
        assert.equal_items(defaults, ngcp.config.default.peer)
    end)

    it("config_get_defaults_real", function()
        local defaults = NGCPConfig.get_defaults(ngcp.config, 'usr')
        local usr_defaults = utable.deepcopy(ngcp.config.default.usr)
        assert.equal_items(defaults, usr_defaults)
    end)

    it("config_get_defaults_dom", function()
        local defaults = NGCPConfig.get_defaults(ngcp.config, 'dom')
        assert.equal_items(defaults, ngcp.config.default.dom)
    end)
    local function check_init(t)
        assert.not_nil(ngcp.prefs[t])
        assert.same(
            _G.KSR.pv.get(
                string.format("$xavp(caller_%s_prefs=>dummy)", t)
            ),
            "caller"
        )
        assert.same(
            _G.KSR.pv.get(
                string.format("$xavp(callee_%s_prefs=>dummy)", t)
            ),
            "callee"
        )
    end

    it("init", function()
        local t = {'peer', 'usr', 'dom', 'real', 'prof', 'fax'}
        for _,v in ipairs(t) do
            check_init(v)
        end
    end)

    it("log_pref full empty should work", function()
        ngcp:log_pref()
    end)

    it("log_pref wrong level should fail", function()
        assert.has_errors(
            function() ngcp:log_pref("dbg", "foo_var") end
        )
    end)

    it("log_pref empty should work", function()
        ngcp:log_pref("info")
    end)

    it("log_pref", function()
        ngcp:log_pref("dbg", "peer")
    end)

    it("caller_usr_load empty", function()
        assert.same(ngcp:caller_usr_load(), {})
    end)

    local t_con = {
        connect = function(_, db, usr, pass, host, port)
            local c = ngcp.config
            assert.same(c.db_database, db)
            assert.same(c.db_username, usr)
            assert.same(c.db_pass, pass)
            assert.same(c.db_host, host)
            assert.same(c.db_port, port)
            return con
        end
    }

    local function fake_db_caller_usr_load_empty_dom()
        local curs = {}
        local count = 1
        local v
        local exec_val = {
            "SELECT 1",
            "SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN prof_preferences AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = 'ae736f72-21d1-4ea6-a3ea-4d7f56b3887c'",
            "SELECT * FROM usr_preferences WHERE uuid ='ae736f72-21d1-4ea6-a3ea-4d7f56b3887c' ORDER BY id DESC",
            "SELECT 1",
            "SELECT fp.* FROM provisioning.voip_fax_preferences fp, provisioning.voip_subscribers s WHERE s.uuid = 'ae736f72-21d1-4ea6-a3ea-4d7f56b3887c' AND fp.subscriber_id = s.id",
        }
        local val = {
            { count = 1, fetch = {{},}, numrows = {1,}, },
            { count = 1, fetch = {}, },
            { count = 1,
              fetch = {
                vars.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"),
                vars.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"),
                vars.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"),
                vars.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"),
                vars.up_vars:val("ae736f72_21d1_4ea6_a3ea_4d7f56b3887c"),
              },
            },
            { count = 1, fetch = {{},}, numrows = {1,}, },
            { count = 1,
              fetch = {vars.fp_vars:val("fp_1"),},
              getcolnames = {vars.fp_vars:val("fp_keys"),},
            },
        }
        local cur = {
            numrows = function() return v.numrows[v.count] end,
            fetch = function()
                local r = v.numrows[v.count]
                v.count = v.count + 1
                return r
            end,
            close = function() count = count + 1 end
        }
        t_con.execute = function(_, query)
            local c
            print(query)
            assert.same(exec_val[count], query)
            c = mock(cur)
            table.insert(curs, c)
            return c
        end

        v = val[count]
        con = mock(t_con)
        return curs
    end

    it("caller_usr_load_empty_dom", function()
        assert.not_nil(ngcp.config)
        local curs = fake_db_caller_usr_load_empty_dom()
        local keys = ngcp:caller_usr_load("ae736f72-21d1-4ea6-a3ea-4d7f56b3887c")
        for _, v in ipairs(curs) do
            assert.spy(v.close).was.called()
        end
        local lkeys = {
            "ext_subscriber_id",
            "ringtimeout",
            "account_id",
            "ext_contract_id",
            "cli",
            "cc",
            "ac",
            "no_nat_sipping"
        }

        assert.equal_items(keys, lkeys)
        assert.same(_G.KSR.pv.get("$xavp(caller_usr_prefs=>dummy)"), "caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>account_id)"), 2)
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>cli)"), "4311001")
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>cc)"), "43")
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>ac)"), "1")
        assert.same(_G.KSR.pv.get("$xavp(caller_real_prefs=>no_nat_sipping)"), "no")
    end)

    --[[
    Lua provides a pairs() function to create the explist information for us
    to iterate over a table. The pairs() function will allow iteration over
    key-value pairs. Note that the order that items are returned is not defined,
    not even for indexed tables.

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

--[[    it("tostring", function()
        local callee_xavp = NGCPUserPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPUserPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")

        -- can't check the whole string
        check_tostring(up:__tostring())
        check_tostring(tostring(up))
    end)--]]

end)
