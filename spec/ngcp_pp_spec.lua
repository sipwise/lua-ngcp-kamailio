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

describe("peer preferences", function()
    local NGCPPeerPrefs
    local pp_vars, utable
    local env, con
    local config
    local peer

    setup(function()
        local utils = require 'ngcp.utils'
        utable = utils.table
        local PPFetch = require 'tests_v.pp_vars'
        local ksrMock = require 'mocks.ksr'
        _G.KSR = ksrMock.new()
        package.loaded.luasql = nil
        package.preload['luasql.mysql'] = function ()
            local luasql = {}
            luasql.mysql = function ()
                return env
            end
        end
        pp_vars = PPFetch:new()
    end)

    before_each(function()
        env = mock()
        local NGCPConfig = require 'ngcp.config'
        NGCPPeerPrefs = require 'ngcp.pp'

        config = NGCPConfig:new()
        config.env = env
        config.getDBConnection = function ()
            return con
        end

        peer = NGCPPeerPrefs:new(config)
    end)

    after_each(function()
        _G.KSR.pv.vars = {}
        pp_vars:reset()
    end)

    it("caller_load empty", function()
        assert.not_nil(peer.config)
        assert.same(peer:caller_load(), {})
    end)

    it("callee_load empty", function()
        assert.not_nil(peer.config)
        assert.same(peer:callee_load(), {})
    end)

    it("init values", function()
        assert.same(peer.db_table, "peer_preferences")
    end)

    local function get_defaults(level, set)
        local keys_expected = {}
        local defaults = peer.config:get_defaults('peer')

        if set then
            keys_expected = utable.deepcopy(set)
            for _,v in pairs(keys_expected) do
                _G.KSR.log("dbg", string.format("removed key:%s is been loaded.", v))
                defaults[v] = nil
            end
        end

        for k,v in pairs(defaults) do
            utable.add(keys_expected, k)
            assert.same(_G.KSR.pv.get("$xavp("..level.."_peer_prefs=>"..k..")"), v)
        end
        return keys_expected
    end

    local function fake_db()
        local count = 0
        local cur = {
            fetch = function()
                if count < 2 then
                    count = count + 1
                    return pp_vars:val("p_2")
                end
            end,
            close = function() end
        }
        local t_con = {
            execute = function(_, query)
                local expected = "SELECT * FROM peer_preferences WHERE uuid = '2'"
                assert.same(expected, query)
                return mock(cur)
            end
        }
        con = mock(t_con)
        return cur
    end

    local function check_load(level, keys)
        local lkeys = {
            "ip_header",
            "sst_enable",
            "outbound_from_user",
            "inbound_upn",
            "sst_expires",
            "sst_max_timer",
            "inbound_npn",
            "sst_min_timer",
            "sst_refresh_method",
            "inbound_uprn"
        }
        local skey = "$xavp(%s_peer_prefs=>%s)"

        assert.equal_items(lkeys, keys)
        assert.same(level, _G.KSR.pv.get(skey:format(level, "dummy")))
        assert.same(_G.KSR.pv.get(skey:format(level, "sst_enable")), "no")
        assert.same(
            _G.KSR.pv.get(skey:format(level, "sst_refresh_method")),
            "UPDATE_FALLBACK_INVITE"
        )
        assert.same(_G.KSR.pv.get(skey:format(level, "sst_min_timer")), 90)
        local expected = get_defaults(level, {"sst_enable", "sst_refresh_method"})
        assert.equal_items(expected, keys)
    end

    it("caller_load", function()
        local cur = fake_db()
        assert.not_nil(peer.config)
        local keys = peer:caller_load('2')
        assert.spy(cur.close).was.called()
        check_load("caller", keys)
    end)

    it("callee_load", function()
        local cur = fake_db()
        assert.not_nil(peer.config)
        local keys = peer:callee_load('2')
        assert.spy(cur.close).was.called()
        check_load("callee", keys)
    end)

    it("clean", function()
        local xavp = NGCPPeerPrefs:xavp('callee')
        xavp("testid",1)
        xavp("foo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        peer:clean()
        assert.same(_G.KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"), "caller")
        assert.same(_G.KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"), "callee")
        assert.is_nil(_G.KSR.pv.get("$xavp(peer)"))
    end)

    it("callee_clean", function()
        local callee_xavp = NGCPPeerPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPPeerPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_peer_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_peer_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        peer:clean('callee')
        assert.same(_G.KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),'caller')
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_peer_prefs=>testid)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(callee_peer_prefs=>foo)"))
        assert.same(_G.KSR.pv.get("$xavp(caller_peer_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_peer_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
    end)

    it("caller_clean", function()
        local callee_xavp = NGCPPeerPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPPeerPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assert.same(_G.KSR.pv.get("$xavp(caller_peer_prefs=>other)"),1)
        assert.same(_G.KSR.pv.get("$xavp(caller_peer_prefs=>otherfoo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
        peer:clean('caller')
        assert.same(_G.KSR.pv.get("$xavp(caller_peer_prefs=>dummy)"),"caller")
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_peer_prefs=>other)"))
        assert.is_nil(_G.KSR.pv.get("$xavp(caller_peer_prefs=>otherfoo)"))
        assert.same(_G.KSR.pv.get("$xavp(callee_peer_prefs=>testid)"),1)
        assert.same(_G.KSR.pv.get("$xavp(callee_peer_prefs=>foo)"),"foo")
        assert.same(_G.KSR.pv.get("$xavp(callee_peer_prefs=>dummy)"),"callee")
    end)

    --[[
    Lua provides a pairs() function to create the explist information for us
    to iterate over a table. The pairs() function will allow iteration over
    key-value pairs. Note that the order that items are returned is not defined,
    not even for indexed tables.
    --]]
    local function check_tostring(str)
        local r = 'caller_peer_prefs:{(.+)}\ncallee_peer_prefs:{(.+)}\n'
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
        local callee_xavp = NGCPPeerPrefs:xavp('callee')
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPPeerPrefs:xavp('caller')
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")

        -- can't check the whole string
        check_tostring(tostring(peer))
    end)

end)
