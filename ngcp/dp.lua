#!/usr/bin/env lua5.1
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

    function NGCPDomainPrefs:_get_defaults(level)
        local defaults = self.config:get_defaults('dom')
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

    function NGCPDomainPrefs:_load(level, uuid)
        local con = self.config:getDBConnection()
        local query = "SELECT * FROM " .. self.db_table .. " WHERE domain ='" .. uuid .."'"
        local cur = con:execute(query)
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
        cur:close()
        con:close()
        self:xavp(level, result)

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