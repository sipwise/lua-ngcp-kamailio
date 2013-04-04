#!/usr/bin/env lua5.1
require 'ngcp.utils'
require 'ngcp.xavp'

-- class NGCPPeerPrefs
NGCPPeerPrefs = {
     __class__ = 'NGCPPeerPrefs'
}
NGCPPeerPrefs_MT = { __index = NGCPPeerPrefs }

    function NGCPPeerPrefs:new(config)
        local t = {
            config = config,
            db_table = "peer_preferences"
        }
        return setmetatable( t, NGCPPeerPrefs_MT )
    end

    function NGCPPeerPrefs:caller_load(uuid)
        return self:_load("caller",uuid)
    end

    function NGCPPeerPrefs:callee_load(uuid)
        return self:_load("callee",uuid)
    end

    function NGCPPeerPrefs:_load(level, uuid)
        local con = assert (self.config:getDBConnection())
        local query = "SELECT * FROM " .. self.db_table .. " WHERE uuid = '" .. uuid .. "'"
        local cur = assert (con:execute(query))
        local keys = {}
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