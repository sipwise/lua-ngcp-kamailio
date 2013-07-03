#!/usr/bin/env lua5.1
require 'ngcp.utils'
require 'ngcp.xavp'

-- class NGCPPeerPrefs
NGCPPeerPrefs = {
     __class__ = 'NGCPPeerPrefs'
}
NGCPPeerPrefs_MT = { __index = NGCPPeerPrefs }

NGCPPeerPrefs_MT.__tostring = function ()
        local output = ''
        local xavp = NGCPXAvp:new('caller','peer_prefs')
        output = string.format("caller_peer_prefs:%s\n", tostring(xavp))
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
        local k,_

        if defaults then
            for k,v in pairs(defaults) do
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
        con:close()

        xavp = self:xavp(level, result)
        for k,v in pairs(defaults) do
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