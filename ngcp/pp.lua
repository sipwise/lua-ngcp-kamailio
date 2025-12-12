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
local NGCPXAvp = require 'ngcp.xavp'

-- class NGCPPeerPrefs
local NGCPPeerPrefs = utils.inheritsFrom(NGCPPrefs)

NGCPPeerPrefs.__class__ = 'NGCPPeerPrefs'
NGCPPeerPrefs.group = "peer_prefs"
NGCPPeerPrefs.db_table = "peer_preferences"
NGCPPeerPrefs.query = "SELECT * FROM %s WHERE uuid = '%s'"
-- joins three tables:
-- *kamailio.peer_preferences
-- *provisioning.voip_preferences
-- *provisioning.voip_preference_groups
-- links peers attributes to the preferences list,
-- to the preferences group id
NGCPPeerPrefs.group_query = [[
SELECT kp.*
  FROM kamailio.peer_preferences AS kp
  JOIN provisioning.voip_preferences AS vp
    ON vp.attribute = kp.attribute
  JOIN provisioning.voip_preference_groups AS vpg
    ON vpg.id = vp.voip_preference_groups_id
  WHERE kp.uuid = '%s' AND vpg.id = %s
]]
NGCPPeerPrefs.select_id_query = "SELECT id FROM provisioning.voip_preference_groups WHERE name = '%s'"

-- luacheck: globals KSR
function NGCPPeerPrefs:new(config)
    local instance = NGCPPeerPrefs:create()
    -- creates xavp usr
    instance:init(config)
    return instance
end

function NGCPPeerPrefs:clean(vtype)
    NGCPPrefs.clean(self, vtype)
    if not vtype then
        NGCPXAvp:new('callee', 'prefs'):clean()
        NGCPXAvp:new('caller', 'prefs'):clean()
    else
        NGCPXAvp:new(vtype, 'prefs'):clean()
    end
end

function NGCPPeerPrefs:get_pref_group_id(name)
    local con = assert(self.config:getDBConnection())
    local query = self.select_id_query:format(name)
    local cur = assert(con:execute(query))
    local row = cur:fetch({}, "a")
    cur:close()

    if row and row.id then
        return tonumber(row.id)
    end

    KSR.err(string.format("[NGCP] preference group '%s' not found\n", name))
    return nil
end

function NGCPPeerPrefs:load_group(level, uuid, group_id)
    local con = assert(self.config:getDBConnection())
    local query = self.group_query:format(uuid, group_id)
    local cur = assert(con:execute(query))

    return self:_set_xavp(level, cur, query)
end

function NGCPPeerPrefs:caller_load_group(uuid, name)
    local group_id = self:get_pref_group_id(name)
    if not group_id then
        KSR.err("[NGCP] Cannot load group '%s', skipping\n", name)
        return {}
    end

    if not uuid or uuid == '' then return {} end
    return self:load_group("caller", uuid, group_id)
end

function NGCPPeerPrefs:callee_load_group(uuid, name)
    local group_id = self:get_pref_group_id(name)
    if not group_id then
        KSR.err("[NGCP] Cannot load group '%s', skipping\n", name)
        return {}
    end

    if not uuid or uuid == '' then return {} end
    return self:load_group("callee", uuid, group_id)
end

-- class
return NGCPPeerPrefs
