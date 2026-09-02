--
-- Copyright 2013-2021 SipWise Team <development@sipwise.com>
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
local utable = utils.table
local NGCPXAvp = require 'ngcp.xavp'

-- class NGCPPrefs
local NGCPPrefs = utils.inheritsFrom()
NGCPPrefs.__class__ = 'NGCPPrefs'
NGCPPrefs.levels = {"caller", "callee"}
NGCPPrefs.query_blob = "SELECT * FROM provisioning.voip_%s_blob WHERE id = %s"
NGCPPrefs.select_id_query =
    "SELECT id FROM provisioning.voip_preference_groups WHERE name = '%s'"
NGCPPrefs.group_query = [[
SELECT prefs.*
  FROM %s AS prefs
  JOIN provisioning.voip_preferences AS vp
    ON vp.attribute = prefs.attribute
  JOIN provisioning.voip_preference_groups AS vpg
    ON vpg.id = vp.voip_preference_groups_id
  WHERE prefs.uuid = '%s' AND vpg.id = %s
  ORDER BY prefs.id DESC
]]

function NGCPPrefs.__tostring(self)
    local output, msg = '', "%s_%s:%s\n"
    for _,level in pairs(self.levels) do
        local xavp = NGCPXAvp:new(level, self.group)
        output = output .. msg:format(level, self.group, tostring(xavp))
    end
    return output
end
-- luacheck: globals KSR
function NGCPPrefs:init(config)
    self.config = config
    for _,v in pairs(self.levels) do
        NGCPXAvp.init(v, self.group)
    end
end

function NGCPPrefs:check_level(level)
    return utils.table.contains(self.levels, level)
end

function NGCPPrefs:_defaults()
    local group = self.group:gsub('_prefs','')
    local defaults = self.config:get_defaults(group)
    local keys = {}
    local msg = "defaults[%s]:%s\n"
    KSR.dbg(msg:format(group, utable.tostring(defaults)))

    for k,_ in pairs(defaults) do
        table.insert(keys, k)
    end
    return keys, defaults
end

function NGCPPrefs:pref_is_blob(attribute, value_type)
    local vtype = value_type

    if type(value_type) == "string" then
        vtype = tonumber(value_type)
    end
    if vtype == 2 then
        if self.config.blob_prefs[attribute] then return true end
        KSR.dbg(string.format("skip load of blob value of attribute:%s\n",
            attribute))
    end
    return false
end

function  NGCPPrefs:_get_blob(blob_id)
    local result
    local con = assert (self.config:getDBConnection())
    local query = self.query_blob:format(self.db_table, blob_id)
    local cur = assert (con:execute(query))
    local row = cur:fetch({}, "a")

    if utable.size(row) > 0 then
        KSR.dbg(string.format("row content_type:%s\n", row.content_type))
        result = row.value
    else
        KSR.dbg(string.format("no results for query:%s\n", query))
    end
    cur:close()
    return result
end

function NGCPPrefs:_set_xavp(level, cur, query)
    local result = {}
    local row = cur:fetch({}, "a")

    local keys, defaults = self:_defaults()

    if utable.size(row) > 0 then
        while utable.size(row) > 0 do
            if self:pref_is_blob(row.attribute, row.type) then
                row.value = self:_get_blob(row.value)
                row.type = 0
            end
            KSR.dbg(string.format("row attribute:%s\n",
                tostring(row.attribute)))
            table.insert(result, row)
            utable.add(keys, row.attribute)
            defaults[row.attribute] = nil
            row = cur:fetch({}, "a")
        end
    else
        KSR.dbg(string.format("no results for query:%s\n", query))
    end
    cur:close()

    local xavp = self:xavp(level, result)
    for k,v in pairs(defaults) do
        KSR.dbg(string.format("setting default[%s]:%s\n", k, tostring(v)))
        xavp(k, v)
    end
    return keys
end

function NGCPPrefs:_load(level, uuid)
    local con = assert (self.config:getDBConnection())
    local query = self.query:format(self.db_table, uuid)
    local cur = assert (con:execute(query))

    return self:_set_xavp(level, cur, query)
end

function NGCPPrefs:get_pref_group_id(name)
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

function NGCPPrefs:load_group(level, uuid, group_id)
    if not uuid or uuid == '' then
        return {}
    end
    if not self.group_query then
        error(string.format("no group query for prefs:%s", self.group))
    end

    local con = assert(self.config:getDBConnection())
    local query = self.group_query:format(self.db_table, uuid, group_id)
    local cur = assert(con:execute(query))

    return self:_set_xavp(level, cur, query)
end

function NGCPPrefs:caller_load_group(uuid, name)
    local group_id = self:get_pref_group_id(name)
    if not group_id then
        KSR.err(string.format("[NGCP] Cannot load group '%s', skipping\n",
            name))
        return {}
    end

    return self:load_group("caller", uuid, group_id)
end

function NGCPPrefs:callee_load_group(uuid, name)
    local group_id = self:get_pref_group_id(name)
    if not group_id then
        KSR.err(string.format("[NGCP] Cannot load group '%s', skipping\n",
            name))
        return {}
    end

    return self:load_group("callee", uuid, group_id)
end

function NGCPPrefs:caller_load(uuid)
    if not uuid or uuid == '' then
        return {}
    end
    return self:_load("caller", uuid)
end

function NGCPPrefs:callee_load(uuid)
    if not uuid or uuid == '' then
        return {}
    end
    return self:_load("callee", uuid)
end

function NGCPPrefs:xavp(level, l)
    if not self:check_level(level) then
        local msg = "unknown level:%s. It has to be %s"
        error(msg:format(tostring(level), tostring(self.levels)))
    end
    return NGCPXAvp:new(level, self.group, l)
end

function NGCPPrefs:clean(vtype)
    if not vtype then
        self:xavp('callee'):clean()
        self:xavp('caller'):clean()
    else
        self:xavp(vtype):clean()
    end
end

-- class
return NGCPPrefs
