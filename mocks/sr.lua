#!/usr/bin/env lua5.1
require ('logging.file')
require 'lemock'
require 'ngcp.utils'

pvMock = {
    __class__ = 'pvMock',
    vars = {},
    _logger = logging.file("reports/sr_pv_%s.log", "%Y-%m-%d"),
    _logger_levels = {
        dbg  = logging.DEBUG,
        info = logging.INFO,
        warn = logging.WARN,
        err  = logging.ERROR,
        crit = logging.FATAL
    }
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
            if string.ends(id,"[*]") then
                -- clean var
                id = string.sub(id,1,-4)
                t.log("dbg",string.format("sr.pv erase [%s]", id))
                t.vars[id] = nil
            end
            if not t.vars[id] then
                t.vars[id] = value
                t.log("dbg", string.format("sr.pv added [%s]:%s", id, value))
            elseif type(t.vars[id]) == 'table' then
                t.vars[id]:push(value)
                t.log("dbg", string.format("sr.pv push [%s]:%s", id, value))
            else
                local old = t.vars[id]
                t.vars[id] = Stack:new()
                t.vars[id]:push(old, value)
                t.log("dbg", string.format("sr.pv push [%s]:%s", id, value))
            end
            t.log("dbg", string.format("sr.pv [%s]:%s", id, tostring(t.vars[id])))
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

        function t.log(level, message)
                if not t._logger_levels[level] then
                    error(string.format("level %s unknown", level))
                end
                t._logger:log(t._logger_levels[level], message)
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
    _logger = logging.file("reports/sr_%s.log", "%Y-%m-%d"),
    _logger_levels = {
        dbg  = logging.DEBUG,
        info = logging.INFO,
        warn = logging.WARN,
        err  = logging.ERROR,
        crit = logging.FATAL
    }
}
srMock_MT = { __index = srMock, __newindex = lemock.controller():mock() }
    function srMock:new()
        --print("srMock:new")
        local t = {}
            function t.log(level, message)
                if not t._logger_levels[level] then
                    error(string.format("level %s unknown", level))
                end
                t._logger:log(t._logger_levels[level], message)
            end
        setmetatable(t, srMock_MT)
        return t
    end
-- end class
--EOF