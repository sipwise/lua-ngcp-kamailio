#!/usr/bin/env lua5.1
require 'lemock'
require 'ngcp.utils'

mc = lemock.controller()

pvMock = {
    __class__ = 'pvMock',
    vars = {}
}
    function pvMock:new()
        local t = {}

        t.__class__ = 'pvMock'
        t.vars = {}

        function t.get(id)
            if type(t.vars[id]) == 'table' then
                return t.vars[id]:list()
            else
                return t.vars[id]
            end
        end

        function t._addvalue(id, value)
            if string.starts(id, "$xavp(") then
                local l = explode("=>", id)
                -- $xavp(key=>key2) -> $xavp(key[0]=>key2)
                if not string.ends(l[1],"]") then
                    id = l[1] .. "[0]=>" .. l[2]
                end
            end
            if not t.vars[id] then
                t.vars[id] = value
            elseif type(t.vars[id]) == 'table' then
                t.vars[id]:push(value)
            else
                local old = t.vars[id]
                t.vars[id] = Stack:new()
                t.vars[id]:push(old, value)
            end
        end

        function t.seti(id, value)
            if type(value) ~= 'number' then
                error("value is not a number")
            end
            t._addvalue(id, value)
        end

        function t.sets(id, value)
            if type(value) ~= 'string' then
                error("value is not a string")
            end
            t._addvalue(id, value)
        end

        function t.unset(id)
            if string.starts(id, "$xavp(") then
                local l = explode("=>", id)
                local s = l[1]
                if #l == 1 then
                    -- remove the last ')' char
                    s = string.sub(l[1],1,string.len(l[1])-1)
                end
                for k,_ in pairs(t.vars) do
                    if string.starts(k,s) then
                        --print("clean: " .. k)
                        t.vars[k] = nil
                    end
                end
            else
                --print("clean: " .. id)
                t.vars[id] = nil
            end
        end

        function t.is_null(id)
            if not t.vars[id] then
                return true
            end
            return false
        end
        pvMock_MT = { __index = pvMock }
        setmetatable(t, pvMock_MT)
        return t
    end
-- end class

-- class srMock
srMock = {
    __class__ = 'srMock',
    pv = pvMock:new(),
    log = mc:mock()
}
srMock_MT = { __index = srMock, __newindex = mc:mock() }
    function srMock:new()
        --print("srMock:new")
        local t = {}
        setmetatable(t, srMock_MT)
        return t
    end
-- end class
--EOF