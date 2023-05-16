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
local rep_vars = {
    r_1 = {
        {
          id = 1,
          uuid = "1",
          username = "0",
          domain = nil,
          attribute = "concurrent_max_out",
          type = 1,
          value = "5",
          last_modified = "0000-00-00 00:00:00"
        },
        {
          id = 2,
          uuid = "1",
          username = "0",
          domain = nil,
          attribute = "concurrent_max_in",
          type = 1,
          value = "10",
          last_modified = "0000-00-00 00:00:00"
        },
    },
    r_2 = {
      {
        id = 3,
        uuid = "2",
        username = "0",
        domain = nil,
        attribute = "concurrent_max_out",
        type = 1,
        value = "2",
        last_modified = "0000-00-00 00:00:00"
      },
      {
        id = 4,
        uuid = "2",
        username = "0",
        domain = nil,
        attribute = "concurrent_max_in",
        type = 1,
        value = "5",
        last_modified = "0000-00-00 00:00:00"
      },
      {
        id = 5,
        uuid = "2",
        username = "0",
        domain = nil,
        attribute = "concurrent_max",
        type = 1,
        value = "5",
        last_modified = "0000-00-00 00:00:00"
      },
    }
}

local REPFetch = {
    __class__ = 'REPFetch',
    _i = 1
}
    function REPFetch:new()
        local t = {}
        return setmetatable(t, { __index = REPFetch })
    end

    function REPFetch:val(uuid)
        self._i = self._i + 1
        return rep_vars[uuid][self._i-1]
    end

    function REPFetch:reset()
        self._i = 1
    end

return REPFetch
