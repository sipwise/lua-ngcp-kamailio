-- class NGCPAvp
NGCPAvp = {
     __class__ = 'NGCPAvp'
}
NGCPAvp_MT = {
    __index = NGCPAvp,
}

    function NGCPAvp:new(id)
        local t = { id = "$avp(s:" .. id .. ")" }
        NGCPAvp_MT.__call = function(t, value)
            if not value then
                --print(table.tostring(sr.pv.vars))
                --print(t.id)
                return sr.pv.get(t.id)
            elseif type(value) == "number" then
                sr.pv.seti(t.id, value)
            elseif type(value) == "string" then
                sr.pv.sets(t.id, value)
            else
                error("value is not a number or string")
            end
        end
        function t.all()
            return sr.pv.get("$(avp(" .. id .. ")[*])")
        end
        NGCPAvp_MT.__tostring = function(t)
            local value = sr.pv.get(t.id)
            return string.format("%s:%s", t.id, tostring(value))
        end
        return setmetatable( t, NGCPAvp_MT )
    end

    function NGCPAvp:log(level)
        if not level then
            level = "dbg"
        end
        sr.log(level, tostring(self))
    end

    function NGCPAvp:clean()
        --print("NGCPAvp:clean")
        --print(table.tostring(getmetatable(self)))
        --print(table.tostring(self))
        sr.pv.unset(self.id)
    end
-- class
--EOF