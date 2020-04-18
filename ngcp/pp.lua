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
local utils = require 'ngcp.utils'
local NGCPPrefs = require 'ngcp.pref'

-- class NGCPPeerPrefs
local NGCPPeerPrefs = utils.inheritsFrom(NGCPPrefs)

NGCPPeerPrefs.__class__ = 'NGCPPeerPrefs'
NGCPPeerPrefs.group = "peer_prefs"
NGCPPeerPrefs.db_table = "peer_preferences"
NGCPPeerPrefs.query = "SELECT * FROM %s WHERE uuid = '%s'"
-- luacheck: globals KSR
function NGCPPeerPrefs:new(config)
    local instance = NGCPPeerPrefs:create()
    self.config = config
    -- creates xavp usr
    instance:init()
    return instance
end

-- class
return NGCPPeerPrefs
