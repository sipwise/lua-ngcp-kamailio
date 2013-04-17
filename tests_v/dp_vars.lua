dp_vars = {
    voip_sipwise_local = {
      {
        id = 1,
        uuid = "",
        username = "0",
        domain = "voip.sipwise.local",
        attribute = "sst_enable",
        type = 0,
        value = "no",
        last_modified = "1900-01-01 00:00:01"
      },
      {
        id = 2,
        uuid = "",
        username = "0",
        domain = "voip.sipwise.local",
        attribute = "sst_refresh_method",
        type = 0,
        value = "UPDATE_FALLBACK_INVITE",
        last_modified = "1900-01-01 00:00:01"
      },
      {
        id = 3,
        uuid = "",
        username = "0",
        domain = "voip.sipwise.local",
        attribute = "use_rtpproxy",
        type = 0,
        value = "ice_strip_candidates",
        last_modified = "1900-01-01 00:00:01"
      }
    },
    d_192_168_51_56 = {
      {
        id = 4,
        uuid = "",
        username = "0",
        domain = "192.168.51.56",
        attribute = "sst_enable",
        type = 0,
        value = "no",
        last_modified = "1900-01-01 00:00:01"
      },
      {
        id = 5,
        uuid = "",
        username = "0",
        domain = "192.168.51.56",
        attribute = "sst_refresh_method",
        type = 0,
        value = "UPDATE_FALLBACK_INVITE",
        last_modified = "1900-01-01 00:00:01"
      },
      {
        id = 6,
        uuid = "",
        username = "0",
        domain = "192.168.51.56",
        attribute = "outbound_from_user",
        type = 0,
        value = "upn",
        last_modified = "1900-01-01 00:00:01"
      },
      {
        id = 7,
        uuid = "",
        username = "0",
        domain = "192.168.51.56",
        attribute = "outbound_pai_user",
        type = 0,
        value = "npn",
        last_modified = "1900-01-01 00:00:01"
      },
      {
        id = 8,
        uuid = "",
        username = "0",
        domain = "192.168.51.56",
        attribute = "use_rtpproxy",
        type = 0,
        value = "ice_strip_candidates",
        last_modified = "1900-01-01 00:00:01"
      },
      {
        id = 9,
        uuid = "",
        username = "0",
        domain = "192.168.51.56",
        attribute = "ncos_id",
        type = 1,
        value = "1",
        last_modified = "1900-01-01 00:00:01"
      },
      {
        id = 10,
        uuid = "",
        username = "0",
        domain = "192.168.51.56",
        attribute = "rewrite_caller_in_dpid",
        type = 1,
        value = "1",
        last_modified = "1900-01-01 00:00:01"
      },
      {
        id = 11,
        uuid = "",
        username = "0",
        domain = "192.168.51.56",
        attribute = "rewrite_callee_in_dpid",
        type = 1,
        value = "2",
        last_modified = "1900-01-01 00:00:01"
      },
      {
        id = 12,
        uuid = "",
        username = "0",
        domain = "192.168.51.56",
        attribute = "rewrite_caller_out_dpid",
        type = 1,
        value = "3",
        last_modified = "1900-01-01 00:00:01"
      },
      {
        id = 13,
        uuid = "",
        username = "0",
        domain = "192.168.51.56",
        attribute = "rewrite_callee_out_dpid",
        type = 1,
        value = "4",
        last_modified = "1900-01-01 00:00:01"
      }
    }
}

DPFetch = {
    __class__ = 'DPFetch',
    _i = 1
}
    function DPFetch:new()
        t = {}
        return setmetatable(t, { __index = DPFetch })
    end

    function DPFetch:val(uuid)
        self._i = self._i + 1
        return dp_vars[uuid][self._i-1]
    end

    function DPFetch:reset()
        self._i = 1
    end
--EOF