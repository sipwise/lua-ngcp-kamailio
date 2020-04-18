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
local utable = utils.table
local NGCPPrefs = require 'ngcp.pref'

-- class NGCPFaxPrefs
local NGCPFaxPrefs = utils.inheritsFrom(NGCPPrefs)

NGCPFaxPrefs.__class__ = 'NGCPFaxPrefs'
NGCPFaxPrefs.group = "fax_prefs"
NGCPFaxPrefs.db_table = "provisioning.voip_fax_preferences"
NGCPFaxPrefs.query = "SELECT fp.* FROM %s fp, provisioning.voip_subscribers s WHERE s.uuid = '%s' AND fp.subscriber_id = s.id"
-- luacheck: globals KSR
function NGCPFaxPrefs:new(config)
    local instance = NGCPFaxPrefs:create()
    self.config = config
    -- creates xavp usr
    instance:init()
    return instance
end

function NGCPFaxPrefs:_set_xavp(level, cur, query)
    local result = {}
    local colnames = cur:getcolnames()
    local row = cur:fetch({}, "a")
    local keys = {}

    if utable.len(row) > 0 then
        for _,v in pairs(colnames) do
            if row[v] ~= nil then
                utable.add(keys, v)
                result[v] = row[v]
            end
        end
    else
        KSR.dbg(string.format("no results for query:%s\n", query))
    end
    cur:close()

    local xavp = self:xavp(level, result)
    for k,v in pairs(result) do
        xavp(k, v)
    end
    return keys
end

-- class
return NGCPFaxPrefs
