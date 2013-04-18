#!/usr/bin/env lua5.1
require ('logging.file')
require 'lemock'
require 'ngcp.utils'

hdrMock = {
    __class__ = 'hdrMock',
    headers = {},
    headers_reply = {},
    _logger = logging.file('reports/sr_hdr_%s.log', '%Y-%m-%d'),
    _logger_levels = {
        dbg  = logging.DEBUG,
        info = logging.INFO,
        warn = logging.WARN,
        err  = logging.ERROR,
        crit = logging.FATAL
    }
}
    function hdrMock:new()
        local t = {}

        t.__class__ = 'hdrMock'
        t.headers = {}
        t.headers_reply = {}

        function t._is_header(text)
            local result = string.match(text,'[^:]+: .+\r\n$')
            if result then
                return true
            end
            return false
        end

        function t._get_header(text)
            local _,v, result
            local pattern = "^" .. text .. ": (.+)\r\n$"
            if text then
                for _,v in ipairs(t.headers) do
                    result = string.match(v, pattern)
                    --print(string.format("v:%s pattern:%s result:%s", v, pattern, tostring(result)))
                    if result then
                        return result
                    end
                end
            end
        end

        function t.append(text)
            if text then
                if not t._is_header(text) then
                    error("text: " .. text .. " malformed header")
                end
                table.insert(t.headers, text)
            end
        end

        function t.insert(text)
            if text then
                if not t._is_header(text) then
                    error("text: " .. text .. " malformed header")
                end
                table.insert(t.headers, 1, text)
            end
        end

        function t.remove(text)
            local i,v
            if text then
                for i,v in ipairs(t.headers) do
                    if string.starts(v, text .. ":") then
                        table.remove(t.headers, i)
                        return
                    end
                end
            end
        end

        hdrMock_MT = { __index = hdrMock }
        setmetatable(t, hdrMock_MT)
        return t
    end
-- end class

pvMock = {
    __class__ = 'pvMock',
    vars = {},
    hdr = nil,
    _logger = logging.file('reports/sr_pv_%s.log', '%Y-%m-%d'),
    _logger_levels = {
        dbg  = logging.DEBUG,
        info = logging.INFO,
        warn = logging.WARN,
        err  = logging.ERROR,
        crit = logging.FATAL
    }
}
    function pvMock:new(hdr)
        local t = {}

        t.__class__ = 'pvMock'
        t.vars = {}
        t.hdr = hdr

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

        function t._is_hdr(id)
            local key, _, v
            local patterns = {
                '%$hdr%(([^:]+)%)$',
            }
            for _,v in pairs(patterns) do
                for key in string.gmatch(id, v) do
                    return { id=key, clean=false, type='hdr' }
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
                result = t._is_hdr(id)
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
                if not t.vars[result.private_id] then
                    return
                end
                if not result.key then
                    if not result.indx then
                        return t.vars[result.private_id]
                    else
                        result.real_indx = #t.vars[result.private_id]._et - result.indx
                        return t.vars[result.private_id]._et[result.real_indx]
                    end
                end
                if not result.indx then
                    result.indx = 0
                end
                result.real_indx = #t.vars[result.private_id]._et - result.indx
                if t.vars[result.private_id]._et[result.real_indx] then
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
            elseif result.type == 'hdr' then
                if t.hdr then
                    return t.hdr._get_header(result.id)
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
                if t.vars[result.private_id] then
                    if not result.key then
                        if not result.indx then
                            -- xavp(g) -> clean all
                            t.vars[result.private_id] = nil
                            return
                        else
                            -- xavp(g[0])
                            result.real_indx = #t.vars[result.private_id]._et - result.indx
                            t.vars[result.private_id]._et[result.real_indx] = false
                            return
                        end
                    else
                        if not result.indx then
                            result.indx = 0
                        end
                    end
                    -- xavp(g[1]=>k)
                    result.real_indx = #t.vars[result.private_id]._et - result.indx
                    t.vars[result.private_id]._et[result.real_indx][result.key] = nil
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
        local t = {}
        t.hdr = hdrMock:new()
        t.pv = pvMock:new(t.hdr)
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