--
-- Copyright 2014-2020 SipWise Team <development@sipwise.com>
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
local NGCPPrefs = require 'ngcp.pref'
local utils = require 'ngcp.utils'

-- class NGCPProfilePrefs
local NGCPProfilePrefs = utils.inheritsFrom(NGCPPrefs)
NGCPProfilePrefs.__class__ = 'NGCPProfilePrefs'
NGCPProfilePrefs.group = "prof_prefs"
NGCPProfilePrefs.db_table = "prof_preferences"
NGCPProfilePrefs.query = "SELECT prefs.* FROM provisioning.voip_subscribers "..
    "as usr LEFT JOIN %s AS prefs ON usr.profile_id = prefs.uuid "..
    "WHERE usr.uuid = '%s'"
NGCPProfilePrefs.group_query = [[
SELECT prefs.*
  FROM provisioning.voip_subscribers AS usr
  LEFT JOIN %s AS prefs
    ON usr.profile_id = prefs.uuid
  JOIN provisioning.voip_preferences AS vp
    ON vp.attribute = prefs.attribute
  JOIN provisioning.voip_preference_groups AS vpg
    ON vpg.id = vp.voip_preference_groups_id
  WHERE usr.uuid = '%s' AND vpg.id = %s
]]
-- luacheck: globals KSR
function NGCPProfilePrefs:new(config)
    local instance = NGCPProfilePrefs:create()
    -- creates xavp usr
    instance:init(config)
    return instance
end

-- class
return NGCPProfilePrefs
