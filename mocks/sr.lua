#!/usr/bin/env lua5.1
require ('logging.file')
require 'lemock'
require 'ngcp.utils'

pvMock = {
    __class__ = 'pvMock',
    vars = {},
    _logger = logging.file('reports/sr_pv_%s.log', '%Y-%m-%d'),
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

        function t._is_xavp(id)
            local _id, indx, key
            local patterns = {
                '%$xavp%(([%w_]+)%)$',
                '%$xavp%(([%w_^%[]+)%[(%d+)%]%)$',
                '%$xavp%(([%w_]+)=>([%w_]+)%)$',
                '%$xavp%(([%w_^%[]+)%[(%d+)%]=>([%w_]+)%)$'
            }
            for _,v in pairs(patterns) do
                for _id, indx, key in string.gmatch(id, v) do
                    if not key and tonumber(indx) == nil then
                        key = indx
                        indx = nil
                    else
                        indx = tonumber(indx)
                    end
                    return { id=_id, key=key, indx=indx, type='xavp' }
                end
            end
        end

        function t._clean_id(id)
            local k
            k = string.gsub(id, 's:', '')
            k = string.gsub(k, 'i:', '')
            return k
        end

        function t._is_avp(id)
            local i, _id
            local patterns = {
                '%$avp%(([%w_]+)%)$',
                '%$%(avp%(([%w_]+)%)%)$',
                '%$%(avp%(([%w_]+)%)%[%*%]%)$'
            }
            _id = t._clean_id(id)
            for _,v in pairs(patterns) do
                for i in string.gmatch(_id, v) do
                    return { id=i, clean=(v==patterns[3]), type='avp' }
                end
            end
        end

        function t._is_var(id)
            local key, _, v
            local patterns = {
                '%$var%(([%w_]+)%)$',
                '%$%(var%(([%w_]+)%)%)$',
            }
            for _,v in pairs(patterns) do
                for key in string.gmatch(id, v) do
                    return { id=key, clean=false, type='var' }
                end
            end
        end

        function t._is(id)
            if not id then
                error("id empty")
            end
            local result = t._is_xavp(id)

            if not result then
                result = t._is_avp(id)
            end
            if not result then
                result = t._is_var(id)
            end
            if not result then
                error(string.format("not implemented or wrong id:%s", id))
            end
            result.private_id = result.type .. ':' .. result.id
            return result
        end

        function t.get(id)
            local result = t._is(id)
            if not result then
                return
            end
            
            if result.type == 'var' then
                return t.vars[result.private_id]
            elseif result.type == 'xavp' then
                if not result.indx then
                    result.indx = 0
                end
                if not t.vars[result.private_id] then
                    return
                end
                if not result.key then
                    return t.vars[result.private_id]
                end
                result.real_indx = #t.vars[result.private_id]._et - result.indx
                if t.vars[result.private_id]._et[result.real_indx] then
                    --print(string.format("t.vars[%s]._et[%d]:%s", result.private_id, result.real_indx, table.tostring(t.vars[result.private_id]._et[result.indx+1])))
                    return t.vars[result.private_id]._et[result.real_indx][result.key]
                end
            elseif result.type == 'avp' then
                if t.vars[result.private_id] then
                    local l = t.vars[result.private_id]:list()
                    if result.clean then
                        return l
                    else
                        return l[1]
                    end
                end
            end
        end

        function t._addvalue_new(result, value)
            local temp
            if result.type == 'var' then
                t.vars[result.private_id] = value
            elseif result.type == 'xavp' then
                if not result.indx then
                    result.indx = 0
                end
                if result.indx ~= 0 then
                    error(string.format("xavp(%s) has not been initilizated", result.id))
                end
                t.vars[result.private_id] = Stack:new()
                temp = {}
                temp[result.key] = value
                t.vars[result.private_id]:push(temp)
            elseif result.type == 'avp' then
                t.vars[result.private_id] = Stack:new()
                t.vars[result.private_id]:push(value)
            end
        end

        function t._addvalue_with_value(result, value)
            local temp
            if result.type == 'var' then
                t.vars[result.private_id] = value
            elseif result.type == 'xavp' then
                if not result.indx then
                    temp = {}
                    temp[result.key] = value
                    t.vars[result.private_id]:push(temp)
                else
                    result.real_indx = #t.vars[result.private_id]._et - result.indx
                    if t.vars[result.private_id]._et[result.real_indx] == nil then
                        error(string.format("xavp(%s[%d]) does not exist", result.id, result.indx))
                    elseif t.vars[result.private_id]._et[result.real_indx] == false then
                        t.vars[result.private_id]._et[result.real_indx] = {}
                    end
                    t.vars[result.private_id]._et[result.real_indx][result.key] = value
                end
            elseif result.type == 'avp' then
                t.vars[result.private_id]:push(value)
            end
        end

        function t._addvalue(id, value)
            local result = t._is(id)
            if result.clean then
                -- clean var
                t.log("dbg",string.format("sr.pv erase avp[%s]", result.id))
                t.vars[result.private_id] = nil
            end
            if not t.vars[result.private_id] then
                t._addvalue_new(result, value)
            else
                t._addvalue_with_value(result, value)
            end
            t.log("dbg", string.format("sr.pv vars:%s", table.tostring(t.vars)))
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
            local result = t._is(id)
            if result.type == 'xavp' then
                if not result.indx then
                    result.indx = 0
                end
                if t.vars[result.private_id] then
                    if not result.key then
                        t.vars[result.private_id] = nil
                        return
                    end
                    result.real_indx = #t.vars[result.private_id]._et - result.indx
                    t.vars[result.private_id]._et[result.real_indx] = false
                end
            elseif result.type == 'avp' then
                t.vars[result.private_id] = nil
            elseif result.type == 'var' then
                t.vars[result.private_id] = nil
            end
            t.log("dbg", string.format("sr.pv vars:%s", table.tostring(t.vars)))
        end

        function t.is_null(id)
            local result = t._is(id)
            if not result then
                return true
            end
            if not t.vars[result.private_id] then
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