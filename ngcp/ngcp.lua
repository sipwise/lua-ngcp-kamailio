#!/usr/bin/env lua5.1
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
                account_id = 0,
            }
        }
        setmetatable( t, NGCPConfig_MT )
        return t
    end

    function NGCPConfig:getDBConnection()
        local env = assert (luasql.mysql())
        sr.log("dbg","connecting to mysql")
        return assert (env:connect( self.db_database,
            self.db_username, self.db_pass, self.db_host, self.db_port))
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
            dom  = NGCPDomainPrefs:new(t.config),
            usr  = NGCPUserPrefs:new(t.config),
            peer = NGCPPeerPrefs:new(t.config),
            real = NGCPRealPrefs:new(),
        }
        t.vars = {
            caller_peer_load = {
                caller_peer_prefs = {
                    {"caller_force_outbound_calls_to_peer", "force_outbound_calls_to_peer"},
                    {"caller_ip_header","ip_header"}
                }
            },
            callee_peer_load = {
                callee_peer_prefs = {
                }
            },
            caller_usr_load = {
                caller_usr_prefs = {
                    {"caller_account_id", "account_id"},
                    {"caller_cc", "cc"},
                    {"caller_ac", "ac"},
                    {"caller_emergency_cli", "emergency_cli"},
                    {"caller_emergency_prefix", "emergency_prefix"},
                    {"caller_emergency_suffix", "emergency_suffix"},
                    {"caller_ext_subscriber_id", "ext_subscriber_id"},
                    {"caller_ext_contract_id", "ext_contract_id"},
                    {"caller_ring_group_dest", "ring_group_dest"},
                    {"caller_ring_group_policy", "ring_group_policy"}
                },
                caller_real_prefs = {
                    {"caller_ip_header", "ip_header"}
                }
            },
            callee_usr_load = {
                callee_usr_prefs = {
                    {"callee_account_id", "account_id"},
                    {"callee_cc", "cc"},
                    {"callee_ac", "ac"},
                    {"callee_cfu", "cfu"},
                    {"callee_cfna", "cfna"},
                    {"callee_cfb", "cfb"},
                    {"callee_cft", "cft"},
                    {"callee_ringtimeout", "ringtimeout"},
                    {"callee_ext_subscriber_id", "ext_subscriber_id"},
                    {"callee_ext_contract_id", "ext_contract_id"}
                },
                callee_real_prefs = {
                }
            }
        }
        return t
    end

    function NGCP:_set_vars(indx)
        local _,k,v, default, xvap, var
        for k,var in pairs(self.vars[indx]) do
            for _,v in pairs(var) do
                if not v[3] then
                    default = self.config.default[v[2]]
                else
                    default = v[3]
                end
                if v[2] then
                    xavp = k .. "=>" .. v[2]
                else
                    xavp = nil
                end
                NGCPPrefs.set_avp(v[1], xavp, default)
            end
        end
    end

    -- value 0 is like null?
    -- if 0 => use dom pref if not 0
    function NGCP._set_dom_priority(var, xavp, pref)
        local avp = NGCPAvp:new(var)
        local value

        if avp() == 0 then
            value = xavp(pref)
            if not value and value ~= 0 then
                avp:clean()
                avp(value)
            end
        end
    end

    function NGCP:caller_peer_load(peer)
        local _,v, default, xvap
        local keys = self.prefs.peer:caller_load(peer)
        local vars = self.vars.caller_peer_load

        self.prefs.real:caller_peer_load(keys)
        self:_set_vars("caller_peer_load")
        return keys
    end

    function NGCP:callee_peer_load(peer)
        local _,v, default, xvap
        local keys = self.prefs.peer:callee_load(peer)
        local vars = self.vars.callee_peer_load

        self.prefs.real:callee_peer_load(keys)
        self:_set_vars("callee_peer_load")
        return keys
    end

    function NGCP:caller_usr_load(uuid, domain)
        local _,v
        local keys = {
            domain = self.prefs.dom:caller_load(domain),
            user   = self.prefs.usr:caller_load(uuid)
        }
        local unique_keys = table.deepcopy(keys.domain)

        for _,v in pairs(keys.user) do
            table.add(unique_keys, v)
        end
        self.prefs.real:caller_usr_load(unique_keys)
        self:_set_vars("caller_usr_load")
        local xavp = NGCPXAvp:new('caller', 'dom')

        -- if 0 => use dom pref if not 0
        NGCP._set_dom_priority("caller_concurrent_max", xavp, "concurrent_max")
        NGCP._set_dom_priority("caller_concurrent_max_out", xavp, "concurrent_max_out")
        NGCP._set_dom_priority("caller_concurrent_max_per_account", xavp, "concurrent_max_per_account")
        NGCP._set_dom_priority("caller_concurrent_max_per_account_out", xavp, "concurrent_max_per_account_out")

        return unique_keys
    end

    function NGCP:callee_usr_load(uuid, domain)
        local _,v
        local keys = {
            domain = self.prefs.dom:callee_load(domain),
            user   = self.prefs.usr:callee_load(uuid)
        }
        local unique_keys = table.deepcopy(keys.domain)

        for _,v in pairs(keys.user) do
            table.add(unique_keys, v)
        end
        self.prefs.real:callee_usr_load(unique_keys)
        self:_set_vars("callee_usr_load")

        -- if 0 => use dom pref if not 0
        NGCP._set_dom_priority("callee_concurrent_max", xavp, "concurrent_max")
        NGCP._set_dom_priority("callee_concurrent_max_per_account", xavp, "concurrent_max_per_account")

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

    function NGCP:_str_var(vtype, group)
        local _, v, var, vars_index, avp
        local output = "{"
        vars_index = vtype .. "_" .. group .. "_load"
        if self.vars[vars_index] then
            for _,v in pairs(self.vars[vars_index]) do
                for _,var in pairs(v) do
                    avp = NGCPAvp:new(var[1])
                    output = output .. tostring(avp) .. ","
                end
            end
        end
        output = output .. "}\n"
        return output
    end

    function NGCP:log_var(level, vtype, group)
        local vtypes, groups
        local _,vt,gr

        if not level then
            level = "dbg"
        end
        if not vtype then
            vtypes = {"caller", "callee"}
        else
            vtypes = { vtype }
        end
        if not group then
            groups = { "peer", "usr"}
        else
            groups = { group }
        end

        for _,vt in pairs(vtypes) do
            for _,gr in pairs(groups) do
                sr.log(level, self:_str_var(vt, gr))
            end
        end
    end

    function NGCP:clean_vars(vtype, group)
        local _, v, var, vars_index, avp
        vars_index = vtype .. "_" .. group .. "_load"
        if self.vars[vars_index] then
            for _,v in pairs(self.vars[vars_index]) do
                for _,var in pairs(v) do
                    avp = NGCPAvp:new(var[1])
                    avp:clean()
                end
            end
        end
    end

    function NGCP:clean(vtype, group)
        local _,k,v
        if not group then
            for k,v in pairs(self.prefs) do
                v:clean(vtype)
                if not vtype then
                    self:clean_vars('caller', k)
                    self:clean_vars('callee', k)
                else
                    self:clean_vars(vtype, k)
                end
            end
        else
            if self.prefs[group] then
                self.prefs[group]:clean(vtype)
                if not vtype then
                    self:clean_vars('caller', group)
                    self:clean_vars('callee', group)
                else
                    self:clean_vars(vtype, group)
                end
            else
                error(string.format("unknown group:%s", group))
            end
        end
    end
-- class
--EOF