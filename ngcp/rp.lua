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

    function NGCPRealPrefs:caller_peer_load(keys)
        return NGCPRealPrefs:_peer_load("caller", keys)
    end

    function NGCPRealPrefs:callee_peer_load(keys)
        return NGCPRealPrefs:_peer_load("callee", keys)
    end

    function NGCPRealPrefs:caller_usr_load(keys)
        return NGCPRealPrefs:_usr_load("caller", keys)
    end

    function NGCPRealPrefs:callee_usr_load(keys)
        return NGCPRealPrefs:_usr_load("callee", keys)
    end

    function NGCPRealPrefs:_peer_load(level, keys)
        local _,v
        local xavp = {
            real = NGCPRealPrefs:xavp(level),
            peer  = NGCPPeerPrefs:xavp(level),
        }
        local real_keys = {}
        local value
        for _,v in pairs(keys) do
            value = xavp.peer(v)
            if value then
                table.add(real_keys, v)
                --sr.log("info", string.format("key:%s value:%s", v, value))
                xavp.real(v, value)
            else
                sr.log("err", string.format("key:%s not in user or domain", v))
            end
        end
        return real_keys
    end

    function NGCPRealPrefs:_usr_load(level, keys)
        local _,v
        local xavp = {
            real = NGCPRealPrefs:xavp(level),
            dom  = NGCPDomainPrefs:xavp(level),
            usr  = NGCPUserPrefs:xavp(level)
        }
        local real_keys = {}
        local value
        for _,v in pairs(keys) do
            value = xavp.usr(v)
            if not value then
                value = xavp.dom(v)
                --sr.log("info", string.format("key:%s value:%s from domain", v, value))
            end
            if value then
                table.add(real_keys, v)
                --sr.log("info", string.format("key:%s value:%s", v, value))
                xavp.real(v, value)
            else
                sr.log("err", string.format("key:%s not in user or domain", v))
            end
        end
        return real_keys
    end

    function NGCPRealPrefs:xavp(level, l)
        if level ~= 'caller' and level ~= 'callee' then
            error(string.format("unknown level:%s. It has to be [caller|callee]", tostring(level)))
        end
        return NGCPXAvp:new(level,'real_prefs', l)
    end

    function NGCPRealPrefs:clean(vtype)
        if not vtype then
            NGCPRealPrefs:xavp('callee'):clean()
            NGCPRealPrefs:xavp('caller'):clean()
        else
            NGCPRealPrefs:xavp(vtype):clean()
        end
    end
-- class
--EOF