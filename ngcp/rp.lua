#!/usr/bin/env lua5.1
require 'ngcp.utils'
require 'ngcp.xavp'

-- class NGCPRealPrefs
NGCPRealPrefs = {
     __class__ = 'NGCPRealPrefs'
 }
NGCPRealPrefs_MT = { __index = NGCPRealPrefs }

    function NGCPRealPrefs:new()
        local t = {}
        return setmetatable( t, NGCPRealPrefs_MT )
    end

    function NGCPRealPrefs:caller_load(keys)
        return NGCPRealPrefs:_load("caller", keys)
    end

    function NGCPRealPrefs:callee_load(keys)
        return NGCPRealPrefs:_load("callee", keys)
    end

    function NGCPRealPrefs:_load(level, keys)
        local _,v
        local xavp = {
            real   = NGCPXAvp:new(level,'real', {}),
            domain = NGCPXAvp:new(level,'domain', {}),
            user   = NGCPXAvp:new(level,'user', {}),
        }
        local real_keys = {}
        local value
        for _,v in pairs(keys) do
            value = xavp.user(v)
            if not value then
                value = xavp.domain(v)
            end
            if value then
                table.add(real_keys, v)
                xavp.real(v, value)
            else
                sr.log("err", string.format("key:%s not in user or domain", v))
            end
        end
        return real_keys
    end

    function NGCPRealPrefs:clean()
        local xavp
        if not vtype then
            sr.pv.unset("$xavp(real)")
        elseif vtype == 'callee' then
            xavp = NGCPXAvp:new('callee','real',{})
            xavp:clean()
        elseif vtype == 'caller' then
            xavp = NGCPXAvp:new('caller','real',{})
            xavp:clean()
        end
    end
-- class
--EOF