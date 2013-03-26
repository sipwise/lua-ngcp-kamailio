#!/usr/bin/env lua5.1
require 'ngcp.xavp'

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
        return setmetatable( t, NGCPDomainPrefs_MT )
    end

    function NGCPDomainPrefs:caller_load(uuid)
        NGCPDomainPrefs._load(self,0,uuid)
    end

    function NGCPDomainPrefs:callee_load(uuid)
        NGCPDomainPrefs._load(self,1,uuid)
    end

    function NGCPDomainPrefs:_load(level, uuid)
        local con = assert (self.config:getDBConnection())
        local query = "SELECT * FROM " .. self.db_table .. " WHERE domain ='" .. uuid .."'"
        local cur = assert (con:execute(query))
        local row = cur:fetch({}, "a")
        if row then
            sr.log("dbg",string.format("adding xavp %s[%d]", 'domain', level))
            self.xavp = NGCPXAvp:new(level,'domain',row)
        else
            sr.log("dbg", string.format("no results for query:%s", query))
        end
        cur:close()
        con:close()
    end

    function NGCPDomainPrefs:clean(...)
        if self.xavp then
            self.xavp:clean()
        end
    end
-- class
--EOF