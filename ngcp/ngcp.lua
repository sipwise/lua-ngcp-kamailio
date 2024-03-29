--
-- Copyright 2013-2023 SipWise Team <development@sipwise.com>
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

local NGCPXAvp = require 'ngcp.xavp'
local NGCPResellerPrefs = require 'ngcp.rep'
local NGCPContractPrefs = require 'ngcp.cp'
local NGCPProfilePrefs = require 'ngcp.pprof'
local NGCPPeerPrefs = require 'ngcp.pp'
local NGCPDomainPrefs = require 'ngcp.dp'
local NGCPUserPrefs = require 'ngcp.up'
local NGCPRealPrefs = require 'ngcp.rp'
local NGCPFaxPrefs = require 'ngcp.fp'
local NGCPConfig = require 'ngcp.config'
local utils = require 'ngcp.utils'
local utable = utils.table

-- class NGCP
local NGCP = utils.inheritsFrom()
-- luacheck: globals KSR
function NGCP:__tostring()
    local output = ''
    for _,v in pairs(self.prefs) do
        output = output .. tostring(v)
    end
    return output
end

function NGCP:new(config)
    local instance = NGCP:create()
    instance:init(config)
    return instance
end

function NGCP:init(config)
    self.config = NGCPConfig:new(config)
    self.prefs = {
        dom      = NGCPDomainPrefs:new(self.config),
        prof     = NGCPProfilePrefs:new(self.config),
        usr      = NGCPUserPrefs:new(self.config),
        peer     = NGCPPeerPrefs:new(self.config),
        real     = NGCPRealPrefs:new(self.config),
        contract = NGCPContractPrefs:new(self.config),
        reseller = NGCPResellerPrefs:new(self.config),
        fax      = NGCPFaxPrefs:new(self.config),
    }
end

function NGCP:caller_reseller_load(id)
    return self.prefs.reseller:caller_load(id)
end

function NGCP:callee_reseller_load(id)
    return self.prefs.reseller:callee_load(id)
end

function NGCP:caller_contract_load(contract, ip)
    local keys = self.prefs.contract:caller_load(contract, ip)

    self.prefs.real:caller_contract_load(keys)
    return keys
end

function NGCP:callee_contract_load(contract, ip)
    local keys = self.prefs.contract:callee_load(contract, ip)

    self.prefs.real:callee_contract_load(keys)
    return keys
end

function NGCP:caller_peer_load(peer)
    local keys = self.prefs.peer:caller_load(peer)

    self.prefs.real:caller_peer_load(keys)
    return keys
end

function NGCP:callee_peer_load(peer)
    local keys = self.prefs.peer:callee_load(peer)

    self.prefs.real:callee_peer_load(keys)
    return keys
end

function NGCP:caller_usr_load(uuid, domain)
    local keys = {
        domain = self.prefs.dom:caller_load(domain),
        prof   = self.prefs.prof:caller_load(uuid),
        user   = self.prefs.usr:caller_load(uuid),
        fax    = self.prefs.fax:caller_load(uuid)
    }
    local unique_keys = utable.deepcopy(keys.domain)
    utable.merge(unique_keys, keys.prof)
    utable.merge(unique_keys, keys.user)

    self.prefs.real:caller_usr_load(unique_keys)
    NGCPXAvp:new('caller', 'dom')

    return unique_keys
end

function NGCP:callee_usr_load(uuid, domain)
    local keys = {
        domain = self.prefs.dom:callee_load(domain),
        prof   = self.prefs.prof:callee_load(uuid),
        user   = self.prefs.usr:callee_load(uuid),
        fax    = self.prefs.fax:callee_load(uuid)
    }
    local unique_keys = utable.deepcopy(keys.domain)
    utable.merge(unique_keys, keys.prof)
    utable.merge(unique_keys, keys.user)

    self.prefs.real:callee_usr_load(unique_keys)

    return unique_keys
end

function NGCP:log_pref(level, vtype)
    local xavp,xavp_log
    local msg = "%s:%s\n"
    if not level then
        level = "dbg"
    end

    if not vtype then
        for _,pref in pairs(self.prefs) do
            xavp = pref:xavp("caller")
            xavp_log = tostring(xavp)
            KSR.log(level, msg:format(xavp.name, xavp_log))
            xavp = pref:xavp("callee")
            xavp_log = tostring(xavp)
            KSR.log(level, msg:format(xavp.name, xavp_log))
        end
    else
        if self.prefs[vtype] then
            xavp = self.prefs[vtype]:xavp("caller")
            xavp_log = tostring(xavp)
            KSR.log(level, msg:format(xavp.name, xavp_log))
            xavp = self.prefs[vtype]:xavp("callee")
            xavp_log = tostring(xavp)
            KSR.log(level, msg:format(xavp.name, xavp_log))
        else
            error(string.format("there is no prefs for %s", vtype))
        end
    end
end

function NGCP:clean(vtype, group)
    if not group then
        for _,v in pairs(self.prefs) do
            v:clean(vtype)
        end
    else
        if self.prefs[group] then
            self.prefs[group]:clean(vtype)
        else
            error(string.format("unknown group:%s", group))
        end
    end
end
-- class
return NGCP
