#!/usr/bin/env lua5.1
-- Kamailio Lua Config
require "kam_utils.lua"

-- ROUTE_CLEAR_PEER_IN_PREF
function clear_peer_in_pref()
    local list = {
        peer_peer_callee_auth_user,
        peer_peer_callee_auth_pass,
        peer_peer_callee_auth_realm,
        caller_use_rtpproxy,
        peer_caller_ipv46_for_rtpproxy,
        caller_force_outbound_calls_to_peer,
        peer_caller_find_subscriber_by_uuid,
        pstn_dp_caller_in_id,
        pstn_dp_callee_in_id,
        pstn_dp_caller_out_id,
        pstn_dp_callee_out_id,
        rewrite_caller_in_dpid,
        rewrite_caller_out_dpid,
        rewrite_callee_in_dpid,
        rewrite_callee_out_dpid,
        caller_peer_concurrent_max,
        peer_caller_sst_enable,
        peer_caller_sst_expires,
        peer_caller_sst_min_timer,
        peer_caller_sst_max_timer,
        peer_caller_sst_refresh_method,
        caller_inbound_upn,
        caller_inbound_npn,
        caller_inbound_uprn
    }

    clean_avps(list)
end

