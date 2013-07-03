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
up_vars = {
    ae736f72_21d1_4ea6_a3ea_4d7f56b3887c = {
        {
          id = 1,
          uuid = "ae736f72-21d1-4ea6-a3ea-4d7f56b3887c",
          username = "testuser1",
          domain = "192.168.51.56",
          attribute = "account_id",
          type = 1,
          value = 2,
          last_modified = "1900-01-01 00:00:01"
        },
        {
          id = 7,
          uuid = "ae736f72-21d1-4ea6-a3ea-4d7f56b3887c",
          username = "testuser1",
          domain = "192.168.51.56",
          attribute = "cli",
          type = 0,
          value = "4311001",
          last_modified = "1900-01-01 00:00:01"
        },
        {
          id = 8,
          uuid = "ae736f72-21d1-4ea6-a3ea-4d7f56b3887c",
          username = "testuser1",
          domain = "192.168.51.56",
          attribute = "cc",
          type = 0,
          value = "43",
          last_modified = "1900-01-01 00:00:01"
        },
        {
          id = 9,
          uuid = "ae736f72-21d1-4ea6-a3ea-4d7f56b3887c",
          username = "testuser1",
          domain = "192.168.51.56",
          attribute = "ac",
          type = 0,
          value = "1",
          last_modified = "1900-01-01 00:00:01"
        },
        {
          id = 10,
          uuid = "ae736f72-21d1-4ea6-a3ea-4d7f56b3887c",
          username = "testuser1",
          domain = "192.168.51.56",
          attribute = "no_nat_sipping",
          type = 0,
          value = "no",
          last_modified = "1900-01-01 00:00:01"
        },
        {
          id = 11,
          uuid = "ae736f72-21d1-4ea6-a3ea-4d7f56b3887c",
          username = "testuser1",
          domain = "192.168.51.56",
          attribute = "force_outbound_calls_to_peer",
          type = 1,
          value = 1,
          last_modified = "1900-01-01 00:00:01"
        }
    },
    _94023caf_dfba_4f33_8bdb_b613ce627613 = {
        {
          id = 2,
          uuid = "94023caf-dfba-4f33-8bdb-b613ce627613",
          username = "testuser2",
          domain = "192.168.51.56",
          attribute = "account_id",
          type = 1,
          value = 2,
          last_modified = "1900-01-01 00:00:01"
        },
        {
          id = 4,
          uuid = "94023caf-dfba-4f33-8bdb-b613ce627613",
          username = "testuser2",
          domain = "192.168.51.56",
          attribute = "cc",
          type = 0,
          value = 43,
          last_modified = "1900-01-01 00:00:01"
        },
        {
          id = 5,
          uuid = "94023caf-dfba-4f33-8bdb-b613ce627613",
          username = "testuser2",
          domain = "192.168.51.56",
          attribute = "ac",
          type = 0,
          value = 1,
          last_modified = "1900-01-01 00:00:01",
        },
        {
          id = 6,
          uuid = "94023caf-dfba-4f33-8bdb-b613ce627613",
          username = "testuser2",
          domain = "192.168.51.56",
          attribute = "cli",
          type = 0,
          value = "4311002",
          last_modified = "1900-01-01 00:00:01"
        }
    }
}

UPFetch = {
    __class__ = 'UPFetch',
    _i = 1
}
    function UPFetch:new()
        t = {}
        return setmetatable(t, { __index = UPFetch })
    end

    function UPFetch:val(uuid)
        self._i = self._i + 1
        return up_vars[uuid][self._i-1]
    end

    function UPFetch:reset()
        self._i = 1
    end
--EOF