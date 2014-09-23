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

-- class NGCPDomainPrefs
NGCPDomainPrefs = {
     __class__ = 'NGCPDomainPrefs'
}
NGCPDomainPrefs_MT = { __index = NGCPDomainPrefs }

NGCPDomainPrefs_MT.__tostring = function ()
        local output = ''
        local xavp = NGCPXAvp:new('caller','dom_prefs')
        output = string.format("caller_dom_prefs:%s\n", tostring(xavp))
        xavp = NGCPXAvp:new('callee','dom_prefs')
        output = output .. string.format("callee_dom_prefs:%s\n", tostring(xavp))
        return output
    end

    function NGCPDomainPrefs:new(config)
        local t = {
            config = config,
            db_table = "dom_preferences"
        }
        -- creates xavp dom
        NGCPPrefs.init("dom_prefs")
        return setmetatable( t, NGCPDomainPrefs_MT )
    end

    function NGCPDomainPrefs:caller_load(domain)
        if not domain then
            return {}
        end
        return NGCPDomainPrefs._load(self,"caller",domain)
    end

    function NGCPDomainPrefs:callee_load(domain)
        if not domain then
            return {}
        end
        return NGCPDomainPrefs._load(self,"callee",domain)
    end

    function NGCPDomainPrefs:_defaults(level)
        local defaults = self.config:get_defaults('dom')
        local keys = {}
        local k,_

        if defaults then
            for k,_ in pairs(defaults) do
                table.insert(keys, k)
            end
        end
        return keys, defaults
    end

    function NGCPDomainPrefs:_load(level, domain)
        local con = self.config:getDBConnection()
        local query = "SELECT * FROM " .. self.db_table .. " WHERE domain ='" .. domain .."'"
        local cur = con:execute(query)
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
            xavp(k, v)
        end

        return keys
    end

    function NGCPDomainPrefs:xavp(level, l)
        if level ~= 'caller' and level ~= 'callee' then
            error(string.format("unknown level:%s. It has to be [caller|callee]", tostring(level)))
        end
        return NGCPXAvp:new(level,'dom_prefs', l)
    end

    function NGCPDomainPrefs:clean(vtype)
        if not vtype then
            NGCPDomainPrefs:xavp('callee'):clean()
            NGCPDomainPrefs:xavp('caller'):clean()
        else
            NGCPDomainPrefs:xavp(vtype):clean()
        end
    end
-- class
--EOF