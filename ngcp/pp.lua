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

    function NGCPPeerPrefs:_get_defaults(level)
        local defaults = self.config:get_defaults('peer')
        local keys = {}
        local k,_

        if defaults then
            self:xavp(level, defaults)
            for k,_ in pairs(defaults) do
                table.insert(keys, k)
            end
        end
        return keys
    end

    function NGCPPeerPrefs:_load(level, uuid)
        local con = assert (self.config:getDBConnection())
        local query = "SELECT * FROM " .. self.db_table .. " WHERE uuid = '" .. uuid .. "'"
        local cur = assert (con:execute(query))
        local keys = self:_get_defaults(level)
        local result = {}
        local row = cur:fetch({}, "a")

        if row then
            while row do
                --sr.log("info", string.format("result:%s row:%s", table.tostring(result), table.tostring(row)))
                table.insert(result, row)
                table.add(keys, row.attribute)
                row = cur:fetch({}, "a")
            end
        else
            sr.log("dbg", string.format("no results for query:%s", query))
        end
        self:xavp(level, result)
        cur:close()
        con:close()
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