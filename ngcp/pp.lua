#!/usr/bin/env lua5.1
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
        NGCPPeerPrefs._load(self,"caller",uuid)
    end

    function NGCPPeerPrefs:callee_load(uuid)
        NGCPPeerPrefs._load(self,"callee",uuid)
    end

    function NGCPPeerPrefs:_load(level, uuid)
        local con = self.config:getDBConnection()
        local query = "SELECT * FROM " .. self.db_table .. " WHERE uuid = '" .. uuid .. "'"
        local cur = assert (con:execute(query))
        local result = {}
        local row = cur:fetch(result, "a")
        if row then
            while row do
                sr.log("info", string.format("result:%s row:%s", table.tostring(result), table.tostring(row)))
                table.insert(result, row)
                row = cur:fetch({}, "a")
            end
            self.xavp = NGCPXAvp:new(level,'peer',result)
        else
            sr.log("dbg", string.format("no results for query:%s", query))
        end
        cur:close()
        con:close()
    end

    function NGCPPeerPrefs:clean(vtype)
        local xavp
        if not vtype then
            sr.pv.unset("$xavp(peer)")
        elseif vtype == 'callee' then
            xavp = NGCPXAvp:new('callee','peer',{})
            xavp:clean()
        elseif vtype == 'caller' then
            xavp = NGCPXAvp:new('caller','peer',{})
            xavp:clean()
        end
    end
-- class
--EOF