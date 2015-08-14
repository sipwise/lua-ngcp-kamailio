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
require 'ngcp.utils'
require 'ngcp.pref'

-- class NGCPUserPrefs
NGCPUserPrefs = {
     __class__ = 'NGCPUserPrefs'
}
NGCPUserPrefs_MT = { __index = NGCPUserPrefs }

NGCPUserPrefs_MT.__tostring = function ()
        local xavp = NGCPXAvp:new('caller','usr_prefs')
        local output = string.format("caller_usr_prefs:%s\n", tostring(xavp))
        xavp = NGCPXAvp:new('callee','usr_prefs')
        output = output .. string.format("callee_usr_prefs:%s\n", tostring(xavp))
        return output
    end

    function NGCPUserPrefs:new(config)
        local t = {
            config = config,
            db_table = "usr_preferences"
        }
        -- creates xavp usr
        NGCPPrefs.init("usr_prefs")
        return setmetatable( t, NGCPUserPrefs_MT )
    end

    function NGCPUserPrefs:caller_load(uuid)
        if not uuid then
            return {}
        end
        return NGCPUserPrefs._load(self,"caller",uuid)
    end

    function NGCPUserPrefs:callee_load(uuid)
        if not uuid then
            return {}
        end
        return NGCPUserPrefs._load(self,"callee",uuid)
    end

    function NGCPUserPrefs:_defaults(level)
        local defaults = self.config:get_defaults('usr')
        local keys = {}

        if defaults then
            for k,_ in pairs(defaults) do
                table.insert(keys, k)
            end
        end
        return keys, defaults
    end

    function NGCPUserPrefs:_load(level, uuid)
        local con = assert (self.config:getDBConnection())
        local query = "SELECT * FROM " .. self.db_table .. " WHERE uuid ='" ..
            uuid .. "' ORDER BY id"
        local cur = assert (con:execute(query))
        local defaults
        local keys
        local result = {}
        local row = cur:fetch({}, "a")
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

    function NGCPUserPrefs:xavp(level, l)
        if level ~= 'caller' and level ~= 'callee' then
            error(string.format("unknown level:%s. It has to be [caller|callee]", tostring(level)))
        end
        return NGCPXAvp:new(level,'usr_prefs', l)
    end

    function NGCPUserPrefs:clean(vtype)
        if not vtype then
            NGCPUserPrefs:xavp('callee'):clean()
            NGCPUserPrefs:xavp('caller'):clean()
        else
            NGCPUserPrefs:xavp(vtype):clean()
        end
    end
-- class
--EOF