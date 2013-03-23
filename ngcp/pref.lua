#!/usr/bin/env lua5.1
require 'kam_utils'

-- class NGCPPrefs
NGCPPrefs = {
     __class__ = 'NGCPPrefs'
}
NGCPPrefs_MT = { __index = NGCPPrefs }

    function NGCPPrefs:new()
        local t = NGCPPrefs.init()
        setmetatable( t, NGCPPrefs_MT )
        return t
    end

    function NGCPPrefs.init()
        local t = {
            inbound = {},
            outbound = {},
            common = {},
            groups = {'inbound', 'outbound', 'common'}
        }
        --print("NGCPPrefs:init" .. "\n" .. table.tostring(t))
        return t
    end

    function NGCPPrefs:clean(group)
        --print("NGCPPrefs:clean")
        --print(table.tostring(getmetatable(self)))
        --print(table.tostring(self))
        if group then
            if self[group] then
                clean_avps(self[group])
            end
        else
            for k,v in ipairs(self.groups) do
                clean_avps(self[v])
            end
        end
    end
-- class
--EOF