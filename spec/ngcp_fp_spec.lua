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

describe("fax preferences", function()
    local NGCPFaxPrefs
    local fp_vars
    local env, con
    local config
    local fax

    setup(function()
        local FPFetch = require 'tests_v.fp_vars'
        local ksrMock = require 'mocks.ksr'
        _G.KSR = ksrMock.new()
        package.loaded.luasql = nil
        package.preload['luasql.mysql'] = function () end
        fp_vars = FPFetch:new()
    end)

    before_each(function()
        env = mock()
        local NGCPConfig = require 'ngcp.config'
        NGCPFaxPrefs = require 'ngcp.fp'

        config = NGCPConfig:new()
        config.env = env
        config.getDBConnection = function ()
            return con
        end

        fax = NGCPFaxPrefs:new(config)
    end)

    after_each(function()
        _G.KSR.pv.vars = {}
        fp_vars:reset()
    end)

    it("caller_load empty", function()
        assert.not_nil(fax.config)
        assert.same(fax:caller_load(), {})
    end)

    it("callee_load empty", function()
        assert.not_nil(fax.config)
        assert.same(fax:callee_load(), {})
    end)

    it("init values", function()
        assert.same(fax.db_table, "provisioning.voip_fax_preferences")
    end)

    local function fake_db(level)
        local count = 0
        local val_key = {
            caller = 'fp_1',
            callee = 'fp_2'
        }
        local cur = {
            getcolnames = function() return fp_vars:val("fp_keys") end,
            fetch = function()
                if count < 1 then
                    count = count + 1
                    return fp_vars:val(val_key[level])
                end
            end,
            close = function() end
        }
        local t_con = {
            execute = function(_, query)
                local expected = "SELECT fp.* FROM provisioning.voip_fax_preferences fp, provisioning.voip_subscribers s WHERE s.uuid = 'ah736f72-21d1-4ea6-a3ea-4d7f56b3887c' AND fp.subscriber_id = s.id"
                assert.same(expected, query)
                return mock(cur)
            end
        }
        con = mock(t_con)
        return cur
    end

    it("caller_load", function()
        local cur = fake_db('caller')
        assert.not_nil(fax.config)
        local keys = fax:caller_load('ah736f72-21d1-4ea6-a3ea-4d7f56b3887c')
        assert.spy(cur.close).was.called()
        local skey = "$xavp(caller_fax_prefs=>%s)"

        for k,v in pairs(fp_vars:val("fp_keys")) do
            assert.same(v, keys[k])
        end
        assert.same('caller', _G.KSR.pv.get(skey:format("dummy")))
        assert.same(1, _G.KSR.pv.get(skey:format("active")))
        assert.same(1, _G.KSR.pv.get(skey:format("t38")))
        assert.same(1, _G.KSR.pv.get(skey:format("ecm")))
    end)

    it("callee_load", function()
        local cur = fake_db('callee')
        assert.not_nil(fax.config)
        local keys = fax:callee_load('ah736f72-21d1-4ea6-a3ea-4d7f56b3887c')
        assert.spy(cur.close).was.called()
        local skey = "$xavp(callee_fax_prefs=>%s)"

        for k,v in pairs(fp_vars:val("fp_keys")) do
            assert.same(v, keys[k])
        end
        assert.same('callee', _G.KSR.pv.get(skey:format("dummy")))
        assert.same(1, _G.KSR.pv.get(skey:format("active")))
        assert.same(0, _G.KSR.pv.get(skey:format("t38")))
        assert.same(0, _G.KSR.pv.get(skey:format("ecm")))
    end)

    it("clean", function()
        local xavp = NGCPFaxPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_fax_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_fax_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"),"caller")
        fax:clean()
        assert.same(_G.KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"), "caller")
        assert.same(_G.KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"), "callee")
        assert.is_nil(_G.KSR.pv.get("$xavp(fax)"))
    end)

    it("callee_clean", function()
        local callee_xavp = NGCPFaxPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPFaxPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_fax_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_fax_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_fax_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_fax_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"),"callee")
        fax:clean('callee')
        assert.same(_G.KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"),'caller')
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_fax_prefs=>testid)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_fax_prefs=>foo)"))
        assert.same(_G.KSR.pv.get("$xavp(caller_fax_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_fax_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"),"callee")
    end)

    it("caller_clean", function()
        local callee_xavp = NGCPFaxPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPFaxPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_fax_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_fax_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_fax_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_fax_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"),"callee")
        fax:clean('caller')
        assert.same(_G.KSR.pv.get("$xavp(caller_fax_prefs=>dummy)"),"caller")
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_fax_prefs=>other)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_fax_prefs=>otherfoo)"))
        assert.same(_G.KSR.pv.get("$xavp(callee_fax_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_fax_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_fax_prefs=>dummy)"),"callee")
    end)

    --[[
    Lua provides a pairs() function to create the explist information for us
    to iterate over a table. The pairs() function will allow iteration over
    key-value pairs. Note that the order that items are returned is not defined,
    not even for indexed tables.
    --]]
    local function check_tostring(str)
        local r = 'caller_fax_prefs:{(.+)}\ncallee_fax_prefs:{(.+)}\n'
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
        local callee_xavp = NGCPFaxPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPFaxPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")

        -- can't check the whole string
        check_tostring(tostring(fax))
    end)

end)
