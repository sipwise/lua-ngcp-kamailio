#!/usr/bin/env lua5.1
require 'ngcp.pp'
require 'ngcp.dp'

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
        local t = NGCP.init()
        setmetatable( t, NGCP_MT )
        return t
    end

    function NGCP.init()
        local t = {
            config = NGCPConfig:new(),
            prefs = {
                domain = NGCPDomainPrefs:new(),
                peer   = NGCPPeerPrefs:new()
            }
        }
        return t
    end
-- class
--EOF