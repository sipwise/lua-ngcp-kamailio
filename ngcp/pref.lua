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
require 'ngcp.avp'
require 'ngcp.xavp'

-- class NGCPPrefs
NGCPPrefs = {
     __class__ = 'NGCPPrefs'
}
NGCPPrefs_MT = { __index = NGCPPrefs }

    function NGCPPrefs.init(group)
        local levels = {"caller", "callee"}
        for _,v in pairs(levels) do
            NGCPXAvp.init(v,group)
        end
    end
-- class
--EOF