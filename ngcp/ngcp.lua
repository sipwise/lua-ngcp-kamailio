--
-- Copyright 2013 SipWise Team <development@sipwise.com>
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
require 'ngcp.cp'
require 'ngcp.pprof'
require 'ngcp.pp'
require 'ngcp.dp'
require 'ngcp.up'
require 'ngcp.rp'
require 'ngcp.config'

-- class NGCP
NGCP = {
     __class__ = 'NGCP'
}
NGCP_MT = { __index = NGCP }

NGCP_MT.__tostring = function (t)
    local k,v
    output = ''
    for k,v in pairs(t.prefs) do
        output = output .. tostring(v)
    end
    return output
end

    function NGCP:new()
        local t = NGCP.init()
        setmetatable( t, NGCP_MT )
        return t
    end

    function NGCP.init()
        local t = {
            config = NGCPConfig:new()
        }
        t.prefs = {
            dom      = NGCPDomainPrefs:new(t.config),
            prof     = NGCPProfilePrefs:new(t.config),
            usr      = NGCPUserPrefs:new(t.config),
            peer     = NGCPPeerPrefs:new(t.config),
            real     = NGCPRealPrefs:new(t.config),
            contract = NGCPContractPrefs:new(t.config),
        }
        return t
    end

    function NGCP:caller_contract_load(contract)
        local _,v, xvap
        local keys = self.prefs.contract:caller_load(contract)

        self.prefs.real:caller_contract_load(keys)
        return keys
    end

    function NGCP:callee_contract_load(contract)
        local _,v, xvap
        local keys = self.prefs.contract:callee_load(contract)

        self.prefs.real:callee_contract_load(keys)
        return keys
    end

    function NGCP:caller_peer_load(peer)
        local _,v, xvap
        local keys = self.prefs.peer:caller_load(peer)

        self.prefs.real:caller_peer_load(keys)
        return keys
    end

    function NGCP:callee_peer_load(peer)
        local _,v, xvap
        local keys = self.prefs.peer:callee_load(peer)

        self.prefs.real:callee_peer_load(keys)
        return keys
    end

    function NGCP:caller_usr_load(uuid, domain)
        local _,v
        local keys = {
            domain = self.prefs.dom:caller_load(domain),
            prof   = self.prefs.prof:caller_load(uuid),
            user   = self.prefs.usr:caller_load(uuid)
        }
        local unique_keys = table.deepcopy(keys.domain)
        table.merge(unique_keys, keys.prof)
        table.merge(unique_keys, keys.user)

        self.prefs.real:caller_usr_load(unique_keys)
        local xavp = NGCPXAvp:new('caller', 'dom')

        return unique_keys
    end

    function NGCP:callee_usr_load(uuid, domain)
        local _,v
        local keys = {
            domain = self.prefs.dom:callee_load(domain),
            prof   = self.prefs.prof:callee_load(uuid),
            user   = self.prefs.usr:callee_load(uuid)
        }
        local unique_keys = table.deepcopy(keys.domain)
        table.merge(unique_keys, keys.prof)
        table.merge(unique_keys, keys.user)

        self.prefs.real:callee_usr_load(unique_keys)

        return unique_keys
    end

    function NGCP:log_pref(level, vtype)
        local _,pref,xavp,xavp_log

        if not level then
            level = "dbg"
        end

        if not vtype then
            for _,pref in pairs(self.prefs) do
                xavp = pref:xavp("caller")
                xavp_log = tostring(xavp)
                sr.log(level, string.format("%s:%s\n", xavp.name, xavp_log))
                xavp = pref:xavp("callee")
                xavp_log = tostring(xavp)
                sr.log(level, string.format("%s:%s\n", xavp.name, xavp_log))
            end
        else
            if self.prefs[vtype] then
                xavp = self.prefs[vtype]:xavp("caller")
                xavp_log = tostring(xavp)
                sr.log(level, string.format("%s:%s\n", xavp.name, xavp_log))
                xavp = self.prefs[vtype]:xavp("callee")
                xavp_log = tostring(xavp)
                sr.log(level, string.format("%s:%s\n", xavp.name, xavp_log))
            else
                error(string.format("there is no prefs for %s", vtype))
            end
        end
    end

    function NGCP:clean(vtype, group)
        local _,k,v
        if not group then
            for k,v in pairs(self.prefs) do
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
--EOF