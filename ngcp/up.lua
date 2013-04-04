#!/usr/bin/env lua5.1
require 'ngcp.utils'
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
        if not uuid then
            error("uuid is empty")
        end
        return NGCPUserPrefs._load(self,"caller",uuid)
    end

    function NGCPUserPrefs:callee_load(uuid)
        if not uuid then
            error("uuid is empty")
        end
        return NGCPUserPrefs._load(self,"callee",uuid)
    end

    function NGCPUserPrefs:_load(level, uuid)
        local con = assert (self.config:getDBConnection())
        local query = "SELECT * FROM " .. self.db_table .. " WHERE uuid ='" .. uuid .. "'"
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
        NGCPUserPrefs:xavp(level,result)
        cur:close()
        con:close()
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