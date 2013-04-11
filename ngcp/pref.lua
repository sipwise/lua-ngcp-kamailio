#!/usr/bin/env lua5.1
require 'ngcp.xavp'

-- class NGCPPrefs
NGCPPrefs = {
     __class__ = 'NGCPPrefs'
}
NGCPPrefs_MT = { __index = NGCPPrefs }

    function NGCPPrefs.init(group)
        local _,v, xavp
        local levels = {"caller", "callee"}
        for _,v in pairs(levels) do
            xavp = NGCPXAvp.init(v,group)
        end
    end

-- class
--EOF