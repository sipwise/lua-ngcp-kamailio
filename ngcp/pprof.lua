--
-- Copyright 2014 SipWise Team <development@sipwise.com>
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
require 'ngcp.utils'
require 'ngcp.xavp'

-- class NGCPProfilePrefs
NGCPProfilePrefs = {
     __class__ = 'NGCPProfilePrefs'
}
NGCPProfilePrefs_MT = { __index = NGCPProfilePrefs }

NGCPProfilePrefs_MT.__tostring = function ()
        local output = ''
        local xavp = NGCPXAvp:new('caller','prof_prefs')
        output = string.format("caller_prof_prefs:%s\n", tostring(xavp))
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

    function NGCPProfilePrefs:_defaults(level)
        local defaults = self.config:get_defaults('prof')
        local keys = {}
        local k,_

        if defaults then
            for k,v in pairs(defaults) do
                table.insert(keys, k)
            end
        end
        return keys, defaults
    end

    function NGCPProfilePrefs:_load(level, uuid)
        local con = assert (self.config:getDBConnection())
        local query = "SELECT prefs.* FROM provisioning.voip_subscribers as usr LEFT JOIN "..
         self.db_table .." AS prefs ON usr.profile_id = prefs.uuid WHERE usr.uuid = '".. uuid .. "'"
        local cur = assert (con:execute(query))
        local defaults
        local keys
        local result = {}
        local row = cur:fetch({}, "a")
        local k,v
        local xavp

        keys, defaults = self:_defaults(level)

        if row then
            while row do
                --sr.log("info", string.format("result:%s row:%s", table.tostring(result), table.tostring(row)))
                table.insert(result, row)
                table.add(keys, row.attribute)
                defaults[row.attribute] = nil
                row = cur:fetch({}, "a")
            end
        else
            sr.log("dbg", string.format("no results for query:%s", query))
        end
        cur:close()

        xavp = self:xavp(level, result)
        for k,v in pairs(defaults) do
            sr.log("dbg", string.format("setting default[%s]:%s", k, tostring(v)))
            xavp(k, v)
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
--EOF