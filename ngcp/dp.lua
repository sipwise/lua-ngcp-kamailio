#!/usr/bin/env lua5.1
require 'ngcp.utils'
require 'ngcp.pref'

-- class NGCPDomainPrefs
NGCPDomainPrefs = {
     __class__ = 'NGCPDomainPrefs'
}
NGCPDomainPrefs_MT = { __index = NGCPDomainPrefs }

    function NGCPDomainPrefs:new(config)
        local t = {
            config = config,
            db_table = "dom_preferences"
        }
        -- creates xavp dom
        NGCPPrefs.init("dom_prefs")
        return setmetatable( t, NGCPDomainPrefs_MT )
    end

    function NGCPDomainPrefs:caller_load(uuid)
        if not uuid then
            return {}
        end
        return NGCPDomainPrefs._load(self,"caller",uuid)
    end

    function NGCPDomainPrefs:callee_load(uuid)
        if not uuid then
            return {}
        end
        return NGCPDomainPrefs._load(self,"callee",uuid)
    end

    function NGCPDomainPrefs:_load(level, uuid)
        local con = assert (self.config:getDBConnection())
        local query = "SELECT * FROM " .. self.db_table .. " WHERE domain ='" .. uuid .."'"
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
        NGCPDomainPrefs:xavp(level, result)
        cur:close()
        con:close()
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