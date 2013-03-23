#!/usr/bin/env lua5.1
require 'ngcp.pref'

-- class NGCPPeerPrefs
NGCPPeerPrefs = {
     __class__ = 'NGCPPeerPrefs'
}
NGCPPeerPrefs_MT = { __index =  NGCPPeerPrefs, __newindex = NGCPPrefs }

    function NGCPPeerPrefs:new()
        local t = NGCPPeerPrefs.init()
        setmetatable( t, NGCPPeerPrefs_MT )
        return t
    end

    function NGCPPeerPrefs.init()
        local t = NGCPPrefs.init()
        t.inbound = {
            peer_peer_callee_auth_user = "",
            peer_peer_callee_auth_pass = "",
            peer_peer_callee_auth_realm = "",
            caller_use_rtpproxy = "",
            peer_caller_ipv46_for_rtpproxy = "",
            caller_force_outbound_calls_to_peer = "",
            peer_caller_find_subscriber_by_uuid = "",
            pstn_dp_caller_in_id = "",
            pstn_dp_callee_in_id = "",
            pstn_dp_caller_out_id = "",
            pstn_dp_callee_out_id = "",
            rewrite_caller_in_dpid = "",
            rewrite_caller_out_dpid = "",
            rewrite_callee_in_dpid = "",
            rewrite_callee_out_dpid = "",
            caller_peer_concurrent_max = "",
            peer_caller_sst_enable = "",
            peer_caller_sst_expires = "",
            peer_caller_sst_min_timer = "",
            peer_caller_sst_max_timer = "",
            peer_caller_sst_refresh_method = "",
            caller_inbound_upn = "",
            caller_inbound_npn = "",
            caller_inbound_uprn = ""
        }
        t.outbound = {
            peer_peer_caller_auth_user = "",
            peer_peer_caller_auth_pass = "",
            peer_peer_caller_auth_realm = "",
            callee_use_rtpproxy = "",
            peer_callee_ipv46_for_rtpproxy = "",
            peer_callee_concurrent_max = "",
            peer_callee_concurrent_max_ou = "",
            peer_callee_outbound_socke = "",
            pstn_dp_caller_in_i = "",
            pstn_dp_callee_in_i = "",
            pstn_dp_caller_out_i = "",
            pstn_dp_callee_out_i = "",
            rewrite_caller_in_dpi = "",
            rewrite_caller_out_dpi = "",
            rewrite_caller_out_dpi = "",
            rewrite_callee_in_dpi = "",
            rewrite_callee_out_dpi = "",
            peer_callee_sst_enabl = "",
            peer_callee_sst_expire = "",
            peer_callee_sst_min_time = "",
            peer_callee_sst_max_time = "",
            peer_callee_sst_refresh_metho = "",
            callee_outbound_from_displa = "",
            callee_outbound_from_use = "",
            callee_outbound_pai_use = "",
            callee_outbound_ppi_use = "",
            callee_outbound_diversio = "",
            concurrent_ma = "",
            concurrent_max_ou = "",
            concurrent_max_per_accoun = "",
            concurrent_max_out_per_account = ""
        }
        --print("NGCPPeerPrefs:init" .. "\n" .. table.tostring(t))
        return t
    end

    function NGCPPeerPrefs:clean(...)
        --print("NGCPPeerPrefs:clean")
        --print(table.tostring(getmetatable(self)))
        --print(table.tostring(self))
        NGCPPrefs.clean(self, ...)
    end
-- class
--EOF