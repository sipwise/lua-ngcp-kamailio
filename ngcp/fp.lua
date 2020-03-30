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
local utable = utils.table
local NGCPXAvp = require 'ngcp.xavp'
local NGCPPrefs = require 'ngcp.pref'

-- class NGCPFaxPrefs
local NGCPFaxPrefs = {
     __class__ = 'NGCPFaxPrefs'
}
local NGCPFaxPrefs_MT = { __index = NGCPFaxPrefs }

NGCPFaxPrefs_MT.__tostring = function ()
        local xavp = NGCPXAvp:new('caller','fax_prefs')
        local output = string.format("caller_fax_prefs:%s\n", tostring(xavp))
        xavp = NGCPXAvp:new('callee','fax_prefs')
        output = output .. string.format("callee_fax_prefs:%s\n", tostring(xavp))
        return output
    end

    function NGCPFaxPrefs:new(config)
        local t = {
            config = config,
            db_table = "provisioning.voip_fax_preferences"
        }
        -- creates xavp fax
        NGCPPrefs.init("fax_prefs")
        return setmetatable( t, NGCPFaxPrefs_MT )
    end

    function NGCPFaxPrefs:caller_load(uuid)
        if uuid then
            return self:_load("caller",uuid)
        else
            return {}
        end
    end

    function NGCPFaxPrefs:callee_load(uuid)
        if uuid then
            return self:_load("callee",uuid)
        else
            return {}
        end
    end

    function NGCPFaxPrefs:_defaults(level)
        local defaults = self.config:get_defaults('fax')
        local keys = {}

        if defaults then
            for k,_ in pairs(defaults) do
                table.insert(keys, k)
            end
        end
        return keys, defaults
    end

    function NGCPFaxPrefs:_load(level, uuid)
        local con = assert (self.config:getDBConnection())
        local query = "SELECT fp.* FROM provisioning.voip_fax_preferences fp, " ..
            "provisioning.voip_subscribers s WHERE s.uuid = '" .. uuid .. "' AND fp.subscriber_id = s.id"
        local cur = assert (con:execute(query))
        local colnames = cur:getcolnames()
        local keys = {}
        local result = {}
        local row = cur:fetch({}, "a")
        local xavp

        if row then
            for _,v in pairs(colnames) do
                if row[v] ~= nil then
                    utable.add(keys, v)
                    result[v] = row[v]
                end
            end
        else
            KSR.log("dbg", string.format("no results for query:%s", query))
        end
        cur:close()

        xavp = self:xavp(level, result)
        for k,v in pairs(result) do
            xavp(k, v)
        end
        return keys
    end

    function NGCPFaxPrefs:xavp(level, l)
        if level ~= 'caller' and level ~= 'callee' then
            error(string.format("unknown level:%s. It has to be [caller|callee]", tostring(level)))
        end
        return NGCPXAvp:new(level,'fax_prefs', l)
    end

    function NGCPFaxPrefs:clean(vtype)
        if not vtype then
            NGCPFaxPrefs:xavp('callee'):clean()
            NGCPFaxPrefs:xavp('caller'):clean()
        else
            NGCPFaxPrefs:xavp(vtype):clean()
        end
    end
-- class
return NGCPFaxPrefs
