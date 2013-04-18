#!/usr/bin/env lua5.1
require 'ngcp.pp'
require 'ngcp.dp'
require 'ngcp.up'
require 'ngcp.rp'
-- load drivers
require "luasql.mysql"

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
                    {"peer_peer_caller_auth_user", "peer_auth_user"},
                    {"peer_peer_caller_auth_pass", "peer_auth_pass"},
                    {"peer_peer_caller_auth_realm", "peer_auth_realm"},
                    {"callee_use_rtpproxy", "use_rtpproxy"},
                    {"peer_callee_ipv46_for_rtpproxy", "ipv46_for_rtpproxy"},
                    {"peer_callee_concurrent_max", "concurrent_max"},
                    {"peer_callee_concurrent_max_out", "concurrent_max_out"},
                    {"peer_callee_outbound_socket", "outbound_socket"},
                    {"peer_callee_sst_enable", "sst_enable" },
                    {"peer_callee_sst_expires", "sst_expires"},
                    {"peer_callee_sst_min_timer", "sst_min_timer"},
                    {"peer_callee_sst_max_timer", "sst_max_timer"},
                    {"peer_callee_sst_refresh_refresh_method", "sst_refresh_method"},
                    {"callee_outbound_from_user", "outbound_from_user"},
                    {"callee_outbound_from_display", "outbound_from_display"},
                    {"callee_outbound_pai_user", "outbound_pai_user"},
                    {"callee_outbound_ppi_user", "outbound_ppi_user"},
                    {"callee_outbound_diversion", "outbound_diversion"},
                    {"pstn_dp_caller_out_id", "rewrite_caller_out_dpid"},
                    {"pstn_dp_callee_out_id", "rewrite_callee_out_dpid"},
                    {"rewrite_caller_in_dpid"},
                    {"rewrite_callee_in_dpid"}
                }
            },
            callee_peer_load = {
                callee_peer_prefs = {
                    {"peer_peer_callee_auth_user", "peer_auth_user"},
                    {"peer_peer_callee_auth_pass", "peer_auth_pass"},
                    {"peer_peer_callee_auth_realm", "peer_auth_realm"},
                    {"caller_use_rtpproxy", "use_rtpproxy"},
                    {"caller_force_outbound_calls_to_peer", "force_outbound_calls_to_peer"},
                    {"peer_caller_find_subscriber_by_uuid", "find_subscriber_by_uuid"},
                    {"caller_inbound_upn", "inbound_upn"},
                    {"caller_inbound_npn", "inbound_npn"},
                    {"caller_inbound_uprn", "inbound_uprn"},
                    {"pstn_dp_caller_in_id", "rewrite_caller_in_dpid"},
                    {"pstn_dp_callee_in_id", "rewrite_callee_in_dpid"},
                    {"rewrite_caller_out_dpid"},
                    {"rewrite_callee_out_dpid"},
                    {"peer_caller_ipv46_for_rtpproxy","ipv46_for_rtpproxy"},
                    {"caller_ip_header","ip_header"},
                    {"caller_peer_concurrent_max", "concurrent_max"},
                    {"peer_caller_sst_enable", "sst_enable"},
                    {"peer_caller_sst_expires", "sst_expires"},
                    {"peer_caller_sst_min_timer", "sst_min_timer"},
                    {"peer_caller_sst_max_timer", "sst_max_timer"},
                    {"peer_caller_sst_refresh_method", "sst_refresh_method"}
                }
            }
        }
        return t
    end

    function NGCP:caller_peer_load(peer)
        local _,v, default, xvap
        local keys = self.prefs.peer:caller_load(peer)
        local vars = self.vars.caller_peer_load

        self.prefs.real:caller_peer_load(keys)
        for _,v in pairs(vars.caller_peer_prefs) do
            default = self.config.default[v[2]]
            if v[2] then
                xavp = "caller_peer_prefs=>" .. v[2]
            else
                xavp = nil
            end
            NGCPPrefs.set_avp(v[1], xavp, default)
        end
        return keys
    end

    function NGCP:callee_peer_load(peer)
        local _,v, default, xvap
        local keys = self.prefs.peer:callee_load(peer)
        local vars = self.vars.callee_peer_load

        self.prefs.real:callee_peer_load(keys)
        for _,v in pairs(vars.callee_peer_prefs) do
            default = self.config.default[v[2]]
            if v[2] then
                xavp = "callee_peer_prefs=>" .. v[2]
            else
                xavp = nil
            end
            NGCPPrefs.set_avp(v[1], xavp, default)
        end

        return keys
    end

    function NGCP:caller_usr_load(uuid, domain)
        local keys = {
            domain = self.prefs.dom:caller_load(domain),
            user   = self.prefs.usr:caller_load(uuid)
        }
        local unique_keys = table.deepcopy(keys.domain)
        local _,v
        for _,v in pairs(keys.user) do
            table.add(unique_keys, v)
        end
        self.prefs.real:caller_usr_load(unique_keys)
        return unique_keys
    end

    function NGCP:callee_usr_load(uuid, domain)
        local keys = {
            domain = self.prefs.dom:callee_load(domain),
            user   = self.prefs.usr:callee_load(uuid)
        }
        local unique_keys = table.deepcopy(keys.domain)
        local _,v
        for _,v in pairs(keys.user) do
            table.add(unique_keys, v)
        end
        self.prefs.real:callee_usr_load(unique_keys)
        return unique_keys
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