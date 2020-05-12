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
local utils = require 'ngcp.utils'
local utable = utils.table
local NGCPPrefs = require 'ngcp.pref'
local NGCPDomainPrefs = require 'ngcp.dp'
local NGCPPeerPrefs = require 'ngcp.pp'
local NGCPUserPrefs = require 'ngcp.up'
local NGCPProfilePrefs = require 'ngcp.pprof'
local NGCPContractPrefs = require 'ngcp.cp'

-- class NGCPRealPrefs
local NGCPRealPrefs = utils.inheritsFrom(NGCPPrefs)
NGCPRealPrefs.__class__ = 'NGCPRealPrefs'
NGCPRealPrefs.group = "real_prefs"
-- luacheck: globals KSR
function NGCPRealPrefs:new(config)
    local instance = NGCPRealPrefs:create()
    self.config = config
    -- creates xavp usr
    instance:init()
    return instance
end

function NGCPRealPrefs:caller_load(uuid)
    error("Not implemented")
end

function NGCPRealPrefs:callee_load(uuid)
    error("Not implemented")
end

function NGCPRealPrefs:caller_contract_load(keys)
    return self:_contract_load("caller", keys)
end

function NGCPRealPrefs:callee_contract_load(keys)
    return self:_contract_load("callee", keys)
end

function NGCPRealPrefs:caller_peer_load(keys)
    return self:_peer_load("caller", keys)
end

function NGCPRealPrefs:callee_peer_load(keys)
    return self:_peer_load("callee", keys)
end

function NGCPRealPrefs:caller_usr_load(keys)
    return self:_usr_load("caller", keys)
end

function NGCPRealPrefs:callee_usr_load(keys)
    return self:_usr_load("callee", keys)
end

function NGCPRealPrefs:_contract_load(level, keys)
    local xavp = {
        contract  = NGCPContractPrefs:xavp(level),
    }
    local contract_keys = {}
    local values = KSR.pvx.xavp_getd_p1(xavp.contract.name, 0)
    for _,v in pairs(keys) do
        local value = values[v]
        if value then
            utable.add(contract_keys, v)
        end
    end
    return contract_keys
end

function NGCPRealPrefs:_peer_load(level, keys)
    local xavp = {
        real = NGCPRealPrefs:xavp(level),
        peer  = NGCPPeerPrefs:xavp(level),
    }
    local peer_keys = {}
    local values = KSR.pvx.xavp_getd_p1(xavp.peer.name, 0)
    for _,v in pairs(keys) do
        local value = values[v]
        if value then
            utable.add(peer_keys, v)
            xavp.real(v, value)
        end
    end
    return peer_keys
end

function NGCPRealPrefs:_usr_load(level, keys)
    local xavp = {
        real = NGCPRealPrefs:xavp(level),
        dom  = NGCPDomainPrefs:xavp(level),
        prof = NGCPProfilePrefs:xavp(level),
        usr  = NGCPUserPrefs:xavp(level)
    }
    local real_values = {}
    local dom_values = KSR.pvx.xavp_getd_p1(xavp.dom.name, 0)
    local prof_values = KSR.pvx.xavp_getd_p1(xavp.prof.name, 0)
    local usr_values = KSR.pvx.xavp_getd_p1(xavp.usr.name, 0)
    for _,v in pairs(keys) do
        local value = usr_values[v]
        if not value then
            value = prof_values[v]
            if not value then
                value = dom_values[v]
            end
        end
        if value then
            real_values[v] = value
        else
            KSR.err(string.format("key:%s not in user, profile or domain\n", v))
        end
    end
    local real_keys = {}
    for k,v in pairs(real_values) do
        table.insert(real_keys, k)
        xavp.real(k, v)
    end
    return real_keys
end

-- class
return NGCPRealPrefs
