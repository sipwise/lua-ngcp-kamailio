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
pp_vars = {
    p_1 = {
        {
          id = 1,
          uuid = "1",
          username = "0",
          domain = nil,
          attribute = "sst_enable",
          type = 0,
          value = "no",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = 2,
          uuid = "1",
          username = "0",
          domain = nil,
          attribute = "sst_refresh_method",
          type = 0,
          value = "UPDATE_FALLBACK_INVITE",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = 3,
          uuid = "1",
          username = "0",
          domain = nil,
          attribute = "outbound_from_user",
          type = 0,
          value = "upn",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = "4",
          uuid = "1",
          username = "0",
          domain = nil,
          attribute = "outbound_pai_user",
          type = 0,
          value = "npn",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = 5,
          uuid = "1",
          username = "0",
          domain = nil,
          attribute = "use_rtpproxy",
          type = 0,
          value = "ice_strip_candidates",
          last_modified = "0000-00-00 00:00:00"
        }
    },
    p_2 = {
        {
          id = 8,
          uuid = "2",
          username = "0",
          domain = nil,
          attribute = "sst_enable",
          type = 0,
          value = "no",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = 9,
          uuid = "2",
          username = "0",
          domain = nil,
          attribute = "sst_refresh_method",
          type = 0,
          value = "UPDATE_FALLBACK_INVITE",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = 10,
          uuid = "2",
          username = "0",
          domain = nil,
          attribute = "outbound_from_user",
          type = 0,
          value = "upn",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = 11,
          uuid = "2",
          username = "0",
          domain = nil,
          attribute = "outbound_pai_user",
          type = 0,
          value = "npn",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = 12,
          uuid = "2",
          username = "0",
          domain = nil,
          attribute = "use_rtpproxy",
          type = 0,
          value = "ice_strip_candidates",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = 15,
          uuid = "2",
          username = "0",
          domain = nil,
          attribute = "rewrite_caller_in_dpid",
          type = 1,
          value = "1",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = 16,
          uuid = "2",
          username = "0",
          domain = nil,
          attribute = "rewrite_callee_in_dpid",
          type = 1,
          value = "2",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = 17,
          uuid = "2",
          username = "0",
          domain = nil,
          attribute = "rewrite_caller_out_dpid",
          type = 1,
          value = "3",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = 18,
          uuid = "2",
          username = "0",
          domain = nil,
          attribute = "rewrite_callee_out_dpid",
          type = 1,
          value = "4",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = 19,
          uuid = "2",
          username = "0",
          domain = nil,
          attribute = "inbound_uprn",
          type = 0,
          value = "none",
          last_modified = "0000-00-00 00:00:00"
        }
    }
}

PPFetch = {
    __class__ = 'PPFetch',
    _i = 1
}
    function PPFetch:new()
        t = {}
        return setmetatable(t, { __index = PPFetch })
    end

    function PPFetch:val(uuid)
        self._i = self._i + 1
        return pp_vars[uuid][self._i-1]
    end

    function PPFetch:reset()
        self._i = 1
    end
--EOF