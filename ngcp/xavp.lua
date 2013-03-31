#!/usr/bin/env lua5.1

-- class NGCPXAvp
NGCPXAvp = {
     __class__ = 'NGCPXAvp'
}
NGCPXAvp_MT = {
    __index = NGCPXAvp
}
    function NGCPXAvp:new(level,group,l)
        if level ~= 'caller' and level ~= 'callee' then
            error("unknown level. It has to be [caller|callee]")
        end
        if not l or #l == 0 then
            error("list empty")
        end

        local t = {
            group = group,
            keys = {}
        }
        if level == 'callee' then
            t.level = 1
        else
            t.level = 0
        end
        NGCPXAvp._create(t, t.level,group,l)
        NGCPXAvp_MT.__call = function(t, key, value)
            if not key then
                error("key is empty")
            end
            local id = string.format("$xavp(%s[%d]=>%s)", t.group, t.level, key)
            --print(string.format("id:%s", id))
            if not value then
                return sr.pv.get(id)
            elseif type(value) == "number" then
                table.add(t.keys, key)
                sr.pv.seti(id, value)
            elseif type(value) == "string" then
                table.add(t.keys, key)
                sr.pv.sets(id, value)
            else
                error("value is not a number or string")
            end
        end
        setmetatable( t, NGCPXAvp_MT )
        return t
    end

    function NGCPXAvp._setvalue(id, vtype, value)
        local check = nil
    	-- sr.log("info", string.format("vtype:[%s]:%d", type(vtype), vtype))
    	if type(vtype) == "string" then
    		vtype = tonumber(vtype)
    	end
        if vtype == 0 then
            sr.log("info",string.format("sr.pv.sets->%s:%s", id, value))
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
                sr.log("info", string.format("%s:%s", id, check))
	        else
                sr.log("err", string.format("%s:nil", id))
            end
        end
    end

    function NGCPXAvp:_create(level, group, l)
        local i, name
        -- create dummy vars
        name = string.format("$xavp(%s=>dummy)", group)
        NGCPXAvp._setvalue(name, 0, "callee") -- callee -> [1]
        name = string.format("$xavp(%s=>dummy)", group)
        NGCPXAvp._setvalue(name, 0, "caller") -- caller -> [0]
        for i=1,#l do
            name = string.format("$xavp(%s[%d]=>%s)", group, level, l[i].attribute)
            table.add(self.keys, l[i].attribute)
            NGCPXAvp._setvalue(name, l[i].type, l[i].value)
        end
    end

    function NGCPXAvp:clean()
        --print("NGCPXAvp:clean")
        --print(table.tostring(getmetatable(self)))
        --print(table.tostring(self))
        sr.pv.unset(string.format("$xavp(%s)", self.group))
    end
-- class
--EOF