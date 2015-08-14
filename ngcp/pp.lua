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
require 'ngcp.xavp'

-- class NGCPPeerPrefs
NGCPPeerPrefs = {
     __class__ = 'NGCPPeerPrefs'
}
NGCPPeerPrefs_MT = { __index = NGCPPeerPrefs }

NGCPPeerPrefs_MT.__tostring = function ()
        local xavp = NGCPXAvp:new('caller','peer_prefs')
        local output = string.format("caller_peer_prefs:%s\n", tostring(xavp))
        xavp = NGCPXAvp:new('callee','peer_prefs')
        output = output .. string.format("callee_peer_prefs:%s\n", tostring(xavp))
        return output
    end

    function NGCPPeerPrefs:new(config)
        local t = {
            config = config,
            db_table = "peer_preferences"
        }
        -- creates xavp peer
        NGCPPrefs.init("peer_prefs")
        return setmetatable( t, NGCPPeerPrefs_MT )
    end

    function NGCPPeerPrefs:caller_load(uuid)
        if uuid then
            return self:_load("caller",uuid)
        else
            return {}
        end
    end

    function NGCPPeerPrefs:callee_load(uuid)
        if uuid then
            return self:_load("callee",uuid)
        else
            return {}
        end
    end

    function NGCPPeerPrefs:_defaults(level)
        local defaults = self.config:get_defaults('peer')
        local keys = {}

        if defaults then
            for k,_ in pairs(defaults) do
                table.insert(keys, k)
            end
        end
        return keys, defaults
    end

    function NGCPPeerPrefs:_load(level, uuid)
        local con = assert (self.config:getDBConnection())
        local query = "SELECT * FROM " .. self.db_table .. " WHERE uuid = '" .. uuid .. "'"
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

    function NGCPPeerPrefs:xavp(level, l)
        if level ~= 'caller' and level ~= 'callee' then
            error(string.format("unknown level:%s. It has to be [caller|callee]", tostring(level)))
        end
        return NGCPXAvp:new(level,'peer_prefs', l)
    end

    function NGCPPeerPrefs:clean(vtype)
        if not vtype then
            NGCPPeerPrefs:xavp('callee'):clean()
            NGCPPeerPrefs:xavp('caller'):clean()
        else
            NGCPPeerPrefs:xavp(vtype):clean()
        end
    end
-- class
--EOF