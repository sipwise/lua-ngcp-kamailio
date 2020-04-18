--
-- Copyright 2013-2020 SipWise Team <development@sipwise.com>
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

-- class NGCPUserPrefs
local NGCPUserPrefs = utils.inheritsFrom(NGCPPrefs)

NGCPUserPrefs.__class__ = 'NGCPUserPrefs'
NGCPUserPrefs.group = "usr_prefs"
NGCPUserPrefs.db_table = "usr_preferences"
NGCPUserPrefs.query = "SELECT * FROM %s WHERE uuid ='%s' ORDER BY id DESC"
-- luacheck: globals KSR
function NGCPUserPrefs:new(config)
    local instance = NGCPUserPrefs:create()
    self.config = config
    -- creates xavp usr
    instance:init()
    return instance
end

-- class
return NGCPUserPrefs
