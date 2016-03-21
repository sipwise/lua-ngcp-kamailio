--
-- Copyright 2013-2016 SipWise Team <development@sipwise.com>
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
local cp_vars = {
    cp_1 = {
        {
          id = 1,
          uuid = "1",
          location_id = nil,
          username = "0",
          domain = nil,
          attribute = "sst_enable",
          type = 0,
          value = "no",
          last_modified = "0000-00-00 00:00:00"
        }
    },
    cp_2 = {
        {
          id = 8,
          uuid = "2",
          location_id = 1,
          username = "0",
          domain = nil,
          attribute = "sst_enable",
          type = 0,
          value = "yes",
          last_modified = "0000-00-00 00:00:00"
        }
    }
}

local CPFetch = {
    __class__ = 'CPFetch',
    _i = 1
}
    function CPFetch.new()
        local t = {}
        return setmetatable(t, { __index = CPFetch })
    end

    function CPFetch:val(uuid)
        self._i = self._i + 1
        return cp_vars[uuid][self._i-1]
    end

    function CPFetch:reset()
        self._i = 1
    end

return CPFetch
