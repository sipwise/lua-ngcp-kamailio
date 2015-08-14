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

-- class NGCPXAvp
NGCPXAvp = {
     __class__ = 'NGCPXAvp'
}
NGCPXAvp_MT = {
    __index = NGCPXAvp
}
    function NGCPXAvp:new(level,group,l)
        local t = NGCPXAvp.init(level,group,l)
        NGCPXAvp_MT.__call = function(s, key, value)
            if not key then
                error("key is empty")
            end
            local id = string.format("$xavp(%s[0]=>%s)", s.name, key)
            --print(string.format("id:%s", id))
            if not value then
                return sr.pv.get(id)
            elseif type(value) == "number" then
                table.add(s.keys, key)
                --sr.log("dbg", string.format("seti: [%s]:%d", id, value))
                sr.pv.seti(id, value)
            elseif type(value) == "string" then
                table.add(s.keys, key)
                --sr.log("dbg", string.format("sets: [%s]:%s", id, value))
                sr.pv.sets(id, value)
            elseif type(value) == "table" then
                table.add(s.keys, key)
                for i = #value, 1, -1 do
                    local v = value[i]
                    if type(v) == "number" then
                        sr.pv.seti(id, v)
                    elseif type(v) == "string" then
                        sr.pv.sets(id, v)
                    else
                        error("unknown type: %s", type(v))
                    end
                end
            else
                error("value is not a number or string")
            end
        end
        NGCPXAvp_MT.__tostring = function (s)
            local output

            local ll = sr.xavp.get(s.name, 0)
            if ll then
                output = table.tostring(ll)
            end
            sr.log("dbg", string.format("output:%s", output))
            return output
        end
        setmetatable( t, NGCPXAvp_MT )
        return t
    end

    function NGCPXAvp.init(level,group,l)
        if level ~= 'caller' and level ~= 'callee' then
            error("unknown level. It has to be [caller|callee]")
        end
        if not l then
            l = {}
        end

        local t = {
            group = group,
            level = level,
            name = level .. '_' .. group,
            keys = {}
        }
        NGCPXAvp._create(t, l)
        return t
    end

    function NGCPXAvp._setvalue(id, vtype, value)
        local check
    	-- sr.log("info", string.format("vtype:[%s]:%d", type(vtype), vtype))
    	if type(vtype) == "string" then
    		vtype = tonumber(vtype)
    	end
        if vtype == 0 then
            sr.log("dbg",string.format("sr.pv.sets->%s:%s", id, value))
            if type(value) == 'number' then
                value = tostring(value)
            end
            sr.pv.sets(id, value)
        elseif vtype == 1 then
            if type(value) == "string" then
                value = tonumber(value)
            end
            sr.pv.seti(id, value)
        else
            sr.log("err",string.format("can't set value:%s of type:%s",
                tostring(value), tostring(vtype)))
        end
        if value and id then
            check = sr.pv.get(id)
            if check then
                if type(check) == 'table' then
                    table.tostring(check)
                end
	        else
                --error(string.format("%s:nil", id))
                sr.log("err", string.format("%s:nil", id))
            end
        end
    end

    function NGCPXAvp:_create(l)
        local name = string.format("$xavp(%s=>dummy)", self.name)
        if not sr.pv.get(name) then
            NGCPXAvp._setvalue(name, 0, self.level)
            sr.log("dbg",string.format("%s created with dummy value:%s", name, self.level))
        end
        for i=1,#l do
            name = string.format("$xavp(%s[0]=>%s)", tostring(self.name), tostring(l[i].attribute))
            table.add(self.keys, l[i].attribute)
            NGCPXAvp._setvalue(name, l[i].type, l[i].value)
        end
    end

    function NGCPXAvp:all(key)
        if key then
            local t = sr.xavp.get(self.name, 0, 0)
            if t then
                return t[key];
            end
        end
    end

    function NGCPXAvp:clean(key)
        if key then
            local id = string.format("$xavp(%s[0]=>%s[*])", self.name, key)
            sr.pv.unset(id)
        else
            sr.pv.unset(string.format("$xavp(%s)", self.name))
            sr.pv.sets(string.format("$xavp(%s=>dummy)", self.name), self.level)
        end
    end
-- class
--EOF