--
-- Copyright 2014-2015 SipWise Team <development@sipwise.com>
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
local NGCPPrefs = require 'ngcp.pref'

-- class NGCPProfilePrefs
local NGCPProfilePrefs = {
     __class__ = 'NGCPProfilePrefs'
}
local NGCPProfilePrefs_MT = { __index = NGCPProfilePrefs }

NGCPProfilePrefs_MT.__tostring = function ()
        local xavp = NGCPXAvp:new('caller','prof_prefs')
        local output = string.format("caller_prof_prefs:%s\n", tostring(xavp))
        xavp = NGCPXAvp:new('callee','prof_prefs')
        output = output .. string.format("callee_prof_prefs:%s\n", tostring(xavp))
        return output
    end

    function NGCPProfilePrefs:new(config)
        local t = {
            config = config,
            db_table = "prof_preferences"
        }
        -- creates xavp prof
        NGCPPrefs.init("prof_prefs")
        return setmetatable( t, NGCPProfilePrefs_MT )
    end

    function NGCPProfilePrefs:caller_load(uuid)
        if uuid then
            return self:_load("caller",uuid)
        else
            return {}
        end
    end

    function NGCPProfilePrefs:callee_load(uuid)
        if uuid then
            return self:_load("callee",uuid)
        else
            return {}
        end
    end

    function NGCPProfilePrefs:_load(level, uuid)
        local con = assert (self.config:getDBConnection())
        local query = "SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN "..
         self.db_table .." AS prefs ON uKSR.profile_id = prefs.uuid WHERE uKSR.uuid = '".. uuid .. "'"
        local cur = assert (con:execute(query))
        local keys = {}
        local result = {}
        local row = cur:fetch({}, "a")

        if utable.size(row) > 0 then
            while utable.size(row) > 0 do
                --KSR.log("debug", string.format("result:%s row:%s", table.tostring(result), table.tostring(row)))
                table.insert(result, row)
                utable.add(keys, row.attribute)
                row = cur:fetch({}, "a")
            end
        else
            KSR.log("dbg", string.format("no results for query:%s", query))
        end
        cur:close()
        if utable.size(result) > 0 then
            self:xavp(level, result)
        end
        return keys
    end

    function NGCPProfilePrefs:xavp(level, l)
        if level ~= 'caller' and level ~= 'callee' then
            error(string.format("unknown level:%s. It has to be [caller|callee]", tostring(level)))
        end
        return NGCPXAvp:new(level,'prof_prefs', l)
    end

    function NGCPProfilePrefs:clean(vtype)
        if not vtype then
            NGCPProfilePrefs:xavp('callee'):clean()
            NGCPProfilePrefs:xavp('caller'):clean()
        else
            NGCPProfilePrefs:xavp(vtype):clean()
        end
    end
-- class
return NGCPProfilePrefs
