#!/usr/bin/env lua5.1
require 'ngcp.pref'

-- class NGCPDomainPrefs
NGCPDomainPrefs = {
     __class__ = 'NGCPDomainPrefs'
}
NGCPDomainPrefs_MT = { __index = NGCPDomainPrefs, __newindex = NGCPPrefs }

    function NGCPDomainPrefs:new()
        local t = NGCPDomainPrefs.init()
        setmetatable( t, NGCPDomainPrefs_MT )
        return t
    end

    function NGCPDomainPrefs.init()
        local t = NGCPPrefs.init()
        return t
    end

    function NGCPDomainPrefs:clean(...)
        --print("NGCPDomainPrefs:clean")
        --print(table.tostring(getmetatable(self)))
        --print(table.tostring(self))
        NGCPPrefs.clean(self, ...)
    end
-- class
--EOF