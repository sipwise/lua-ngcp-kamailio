#!/usr/bin/env lua5.1

-- class NGCPPreference
NGCPPreference = {
     __class__ = 'NGCPPreference'
}
NGCPPreference_MT = { __index = NGCPPreference }

    function NGCPPreference:new(name)
        local t = {}
        t.name = name
        setmetatable( t, NGCPPreference_MT )
        return t
    end
-- class

-- class NGCPConfig
NGCPConfig = {
     __class__ = 'NGCPConfig'
}
NGCPConfig_MT = { __index = NGCPConfig }

    function NGCPConfig:new()
        local t = {}
        setmetatable( t, NGCPConfig_MT )
        return t
    end
-- class

-- class NGCP
NGCP = {
     __class__ = 'NGCP'
}
NGCP_MT = { __index = NGCP }

    function NGCP:new()
        local t = {}
        t.config = NGCPConfig:new()
        t.preference = {
            domain = NGCPPreference:new('domain'),
            peer   = NGCPPreference:new('peer'),
        }
        setmetatable( t, NGCP_MT )
        return t
    end
-- class
--EOF