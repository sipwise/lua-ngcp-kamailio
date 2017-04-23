--
-- Copyright 2013-2015 SipWise Team <development@sipwise.com>
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
local fp_vars = {
    fp_keys = {
            "active",
            "send_status",
            "send_copy",
            "t38",
            "ecm" },
    fp_1 = {
          id = 1,
          subscriber_id = "1",
          password = nil,
          name = nil,
          active = 1,
          send_status = 1,
          send_copy = 1,
          t38 = 1,
          ecm = 1
    },
    fp_2 = {
          id = 2,
          subscriber_id = "2",
          password = nil,
          name = nil,
          active = 1,
          send_status = 1,
          send_copy = 1,
          t38 = 0,
          ecm = 0
    }
}

local FPFetch = {
    __class__ = 'FPFetch',
}
    function FPFetch.new()
        local t = {}
        return setmetatable(t, { __index = FPFetch })
    end

    function FPFetch:val(uuid)
        return fp_vars[uuid]
    end
    function FPFetch:reset()
        return
    end

return FPFetch
