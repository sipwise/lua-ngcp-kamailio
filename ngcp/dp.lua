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

    function NGCPDomainPrefs:_defaults(level)
        local defaults = self.config:get_defaults('dom')
        local keys = {}
        local k,_

        if defaults then
            for k,_ in pairs(defaults) do
                table.insert(keys, k)
            end
        end
        return keys, defaults
    end

    function NGCPDomainPrefs:_load(level, uuid)
        local con = self.config:getDBConnection()
        local query = "SELECT * FROM " .. self.db_table .. " WHERE domain ='" .. uuid .."'"
        local cur = con:execute(query)
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