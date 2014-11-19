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
-- load drivers
local driver = require "luasql.mysql"
if not luasql then
    luasql = driver
end
-- class NGCPConfig
NGCPConfig = {
     __class__ = 'NGCPConfig'
}
NGCPConfig_MT = { __index = NGCPConfig }

    function NGCPConfig:new()
        local t = {
            db_host = "127.0.0.1",
            db_port = 3306,
            db_username = "kamailio",
            db_pass = "somepasswd",
            db_database = "kamailio",
            default = {
                contract = {
                },
                peer = {
                    sst_enable = "yes",
                    sst_expires = 300,
                    sst_min_timer = 90,
                    sst_max_timer = 7200,
                    sst_refresh_method = "UPDATE_FALLBACK_INVITE",
                    outbound_from_user = "npn",
                    inbound_upn = "from_user",
                    inbound_npn = "from_user",
                    inbound_uprn = "from_user",
                    ip_header = "P-NGCP-Src-Ip",
                },
                dom = {
                    sst_enable = "yes",
                    sst_expires = 300,
                    sst_min_timer = 90,
                    sst_max_timer = 7200,
                    sst_refresh_method = "UPDATE_FALLBACK_INVITE",
                    outbound_from_user = "npn",
                    inbound_upn = "from_user",
                    inbound_uprn = "from_user",
                    ip_header = "P-NGCP-Src-Ip",
                },
                -- just for prefs that are only on usr level
                usr = {
                    account_id = 0,
                    ext_subscriber_id = "",
                    ext_contract_id = "",
                    ringtimeout = 180,
                }
            }
        }
        setmetatable( t, NGCPConfig_MT )
        return t
    end

    local function check_connection(c)
        local cur = c:execute("SELECT 1")
        local row = cur:fetch()
        local result = false
        if cur:numrows() == 1 then
            result = true
        end
        cur:close()
        return result
    end

    function NGCPConfig:getDBConnection()
        if not self.env then
            self.env = assert (luasql.mysql())
        end
        if self.con then
            local ok,err = pcall(check_connection, self.con)
            if not ok then
                self.con = nil
                sr.log("dbg", "lost database connection. Reconnecting")
            end
        end
        if not self.con then
            sr.log("dbg","connecting to mysql")
            self.con = self.env:connect( self.db_database,
                self.db_username, self.db_pass, self.db_host, self.db_port)
        end
        return self.con
    end

    function NGCPConfig:get_defaults(vtype)
        local k,v
        local defs = {}

        if self.default[vtype] then
            for k,v in pairs(self.default[vtype]) do
                defs[k] = v
            end
        end
        return defs
    end
-- class

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
