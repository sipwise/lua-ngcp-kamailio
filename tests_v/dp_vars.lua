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

local dp_vars = {
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

local DPFetch = {
    __class__ = 'DPFetch',
    _i = 1
}
    function DPFetch:new()
        local t = {}
        return setmetatable(t, { __index = DPFetch })
    end

    function DPFetch:val(uuid)
        self._i = self._i + 1
        return dp_vars[uuid][self._i-1]
    end

    function DPFetch:reset()
        self._i = 1
    end
return DPFetch
