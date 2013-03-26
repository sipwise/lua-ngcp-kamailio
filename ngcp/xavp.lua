#!/usr/bin/env lua5.1

-- class NGCPXAvp
NGCPXAvp = {
     __class__ = 'NGCPXAvp'
}
NGCPXAvp_MT = {
    __index = NGCPXAvp,
}
    function NGCPXAvp:new(level,group,l)
        local t = { 
            level = level,
            group = group,
        }
        NGCPXAvp._create(level,group,l)
        NGCPXAvp_MT.__call = function(t, key, value)
            if not key then
                error("key is empty")
            end
            local id = string.format("$xavp(%s[%d]=>%s)", t.group, t.level, key)
            if not value then
                return sr.pv.get(id)
            elseif type(value) == "number" then
                sr.pv.seti(id, value)
            elseif type(value) == "string" then
                sr.pv.sets(id, value)
            else
                error("value is not a number or string")
            end
        end
        setmetatable( t, NGCPXAvp_MT )
        return t
    end

    function NGCPXAvp._setvalue(id, vtype, value)
        if vtype == 0 then
            sr.pv.sets(id, value)
        elseif vtype == 1 then
            if type(value) == "string" then
                value = tonumber(value)
            end 
           sr.pv.seti(id, value)
        end
    end

    function NGCPXAvp._create(level, group, l)
        local i, name
        -- create dummy vars
        name = string.format("$xavp(%s=>%s)[*]", group, 'dummy')
        sr.pv.sets(name, "")
        for i=1,#l do
            name = string.format("$xavp(%s[%d]=>%s)", group, level, l[i].attribute)
            NGCPXAvp._setvalue(name, l[i].type, l[i].value)
        end
    end

    function NGCPXAvp:clean()
        --print("NGCPXAvp:clean")
        --print(table.tostring(getmetatable(self)))
        --print(table.tostring(self))
        sr.pv.unset(string.format("$xavp(%s[%d])", self.group, self.level))
    end
-- class
--EOF