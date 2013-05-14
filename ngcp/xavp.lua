#!/usr/bin/env lua5.1
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
        NGCPXAvp_MT.__call = function(t, key, value)
            if not key then
                error("key is empty")
            end
            local id = string.format("$xavp(%s[0]=>%s)", t.name, key)
            --print(string.format("id:%s", id))
            if not value then
                return sr.pv.get(id)
            elseif type(value) == "number" then
                table.add(t.keys, key)
                sr.log("info", string.format("seti: [%s]:%d", id, value))
                sr.pv.seti(id, value)
            elseif type(value) == "string" then
                table.add(t.keys, key)
                sr.log("info", string.format("sets: [%s]:%s", id, value))
                sr.pv.sets(id, value)
            else
                error("value is not a number or string")
            end
        end
        NGCPXAvp_MT.__tostring = function (t)
            local l,k,v
            local output

            l = sr.xavp.get(t.name, 0)
            if l then
                output = table.tostring(l)
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
        local check = nil
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
            sr.log("err",string.format("can't set value:%s of type:%d", value, vtype))
        end
        if value and id then
            check = sr.pv.get(id)
            if check then
                if type(check) == 'table' then
                    check = table.tostring(check)
                end
	        else
                --error(string.format("%s:nil", id))
                sr.log("err", string.format("%s:nil", id))
            end
        end
    end

    function NGCPXAvp:_create(l)
        local i
        local name = string.format("$xavp(%s=>dummy)", self.name)
        if not sr.pv.get(name) then
            NGCPXAvp._setvalue(name, 0, self.level)
            sr.log("dbg",string.format("%s created with dummy value:%s", name, self.level))
        end
        for i=1,#l do
            name = string.format("$xavp(%s[0]=>%s)", self.name, l[i].attribute)
            table.add(self.keys, l[i].attribute)
            NGCPXAvp._setvalue(name, l[i].type, l[i].value)
        end
    end

    function NGCPXAvp:clean()
        sr.pv.unset(string.format("$xavp(%s)", self.name))
        sr.pv.sets(string.format("$xavp(%s=>dummy)", self.name), self.level)
    end
-- class
--EOF