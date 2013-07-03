--
-- Copyright 2013 SipWise Team <development@sipwise.com>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This package is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
-- .
-- On Debian systems, the complete text of the GNU General
-- Public License version 3 can be found in "/usr/share/common-licenses/GPL-3".
--
require 'ngcp.utils'
require 'ngcp.pref'

-- class NGCPRealPrefs
NGCPRealPrefs = {
     __class__ = 'NGCPRealPrefs'
 }
NGCPRealPrefs_MT = { __index = NGCPRealPrefs }

NGCPRealPrefs_MT.__tostring = function ()
        local output = ''
        local xavp = NGCPXAvp:new('caller','real_prefs')
        output = string.format("caller_real_prefs:%s\n", tostring(xavp))
        xavp = NGCPXAvp:new('callee','real_prefs')
        output = output .. string.format("callee_real_prefs:%s\n", tostring(xavp))
        return output
    end

    function NGCPRealPrefs:new()
        local t = {}
        -- creates xavp real
        NGCPPrefs.init("real_prefs")
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
            peer  = NGCPPeerPrefs:xavp(level),
        }
        local real_keys = {}
        local value
        for _,v in pairs(keys) do
            value = xavp.peer(v)
            if value then
                table.add(real_keys, v)
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