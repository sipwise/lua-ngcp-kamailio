#!/usr/bin/env lua5.1
require 'ngcp.xavp'

-- class NGCPUserPrefs
NGCPUserPrefs = {
     __class__ = 'NGCPUserPrefs'
}
NGCPUserPrefs_MT = { __index = NGCPUserPrefs }

    function NGCPUserPrefs:new(config)
        local t = {
            config = config,
            db_table = "usr_preferences"
        }
        return setmetatable( t, NGCPUserPrefs_MT )
    end

    function NGCPUserPrefs:caller_load(uuid)
        return NGCPUserPrefs._load(self,"caller",uuid)
    end

    function NGCPUserPrefs:callee_load(uuid)
        return NGCPUserPrefs._load(self,"callee",uuid)
    end

    function NGCPUserPrefs:_load(level, uuid)
        local con = assert (self.config:getDBConnection())
        local query = "SELECT * FROM " .. self.db_table .. " WHERE uuid ='" .. uuid .. "'"
        local cur = assert (con:execute(query))
        local keys = {}
        local result = {}
        local row = cur:fetch({}, "a")
        local xavp

        if row then
            while row do
                --sr.log("info", string.format("result:%s row:%s", table.tostring(result), table.tostring(row)))
                table.insert(result, row)
                table.insert(keys, row.attribute)
                row = cur:fetch({}, "a")
            end
        else
            sr.log("dbg", string.format("no results for query:%s", query))
        end
        xavp = NGCPXAvp:new(level,'user',result)
        cur:close()
        con:close()
        return keys
    end

    function NGCPUserPrefs:clean(vtype)
        local xavp
        if not vtype then
            sr.pv.unset("$xavp(user)")
        elseif vtype == 'callee' then
            xavp = NGCPXAvp:new('callee','user',{})
            xavp:clean()
        elseif vtype == 'caller' then
            xavp = NGCPXAvp:new('caller','user',{})
            xavp:clean()
        end
    end
-- class
--EOF