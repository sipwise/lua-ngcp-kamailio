--
-- Copyright 2015 SipWise Team <development@sipwise.com>
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

-- luacheck: ignore logging
require ('logging.file')
local utils = require 'ngcp.utils'
local utable = utils.table
local Stack = utils.Stack

local pvMock = {
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

function pvMock.new(hdr)
    local t = {}

    t.__class__ = 'pvMock'
    -- fake pseudo vars go here
    t.vars_pv = {
        ro = {
            si = "127.0.0.1",
            sp = "9090"
        },
        rw = {
            rU = "noname"
        }
    }
    t.vars = {}
    t.hdr = hdr

    t._is_xavp = function (id)
        local patterns = {
            '%$xavp%(([%w_^%[]+)%)$',
            '%$xavp%(([%w_^%[]+)%[(%d+)%]%)$',
            '%$xavp%(([%w_^%[]+)=>([%w_^%[]+)%)$',
            '%$xavp%(([%w_^%[]+)%[(%d+)%]=>([%w_^%[]+)%)$',
            '%$xavp%(([%w_^%[]+)=>([%w_^%[]+)%[(%d+)%]%)$',
            '%$xavp%(([%w_^%[]+)%[(%d+)%]=>([%w_^%[]+)%[(%d+)%]%)$',
            '%$xavp%(([%w_^%[]+)%[(%d+)%]=>([%w_^%[]+)%[%*%]%)$'
        }
        local logger = logging.file('reports/sr_pv_%s.log', '%Y-%m-%d')
        for _,v in pairs(patterns) do
            -- luacheck: push
            -- luacheck: ignore 512
            for _id, indx, key, kindx in string.gmatch(id, v) do
                logger:log(logging.DEBUG, string.format("_:%d id:%s v:%s _id:%s indx:%s key:%s kindx:%s", _, id, v, tostring(_id), tostring(indx), tostring(key), tostring(kindx)))
                if _ == 5 or _ == 3 then
                    kindx = key
                    key = indx
                    indx = nil
                else
                    indx = tonumber(indx)
                end
                if kindx then
                    kindx = tonumber(kindx)
                end
                return { id=_id, key=key,
                        indx=indx, kindx=kindx, clean=(v==patterns[7]),
                        type='xavp' }
            end
            -- luacheck: pop
        end
    end

    t._clean_id = function (id)
        local k
        k = string.gsub(id, 's:', '')
        k = string.gsub(k, 'i:', '')
        return k
    end

    t._is_avp = function (id)
        local patterns = {
            '%$avp%(([%w_]+)%)$',
            '%$%(avp%(([%w_]+)%)%)$',
            '%$%(avp%(([%w_]+)%)%[%*%]%)$'
        }
        local _id = t._clean_id(id)
        for _,v in pairs(patterns) do
            -- luacheck: push
            -- luacheck: ignore 512
            for i in string.gmatch(_id, v) do
                return { id=i, clean=(v==patterns[3]), type='avp' }
            end
            -- luacheck: pop
        end
    end

    t._is_var = function (id)
        local patterns = {
            '%$var%(([%w_]+)%)$',
            '%$%(var%(([%w_]+)%)%)$',
        }
        for _,v in pairs(patterns) do
            -- luacheck: push
            -- luacheck: ignore 512
            for key in string.gmatch(id, v) do
                return { id=key, clean=false, type='var' }
            end
            -- luacheck: pop
        end
    end

    t._is_hdr = function (id)
        local patterns = {
            '%$hdr%(([^:]+)%)$',
        }
        for _,v in pairs(patterns) do
            -- luacheck: push
            -- luacheck: ignore 512
            for key in string.gmatch(id, v) do
                return { id=key, clean=false, type='hdr' }
            end
            -- luacheck: pop
        end
    end

    t._is_pv = function (id)
        local real_id = string.match(id, '%$(%w+)$')
        if not real_id then
            return
        end
        for k,_ in pairs(t.vars_pv) do
            for k0,_ in pairs(t.vars_pv[k]) do
                --print(string.format("id:%s, k:%s k0:%s", real_id, k, k0))
                if real_id == k0 then
                    return { id=k0, clean=false, type='pv', mode=k}
                end
            end
        end
    end

    t._is = function (id)
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
            result = t._is_pv(id)
        end
        if not result then
            error(string.format("not implemented or wrong id:%s", id))
        end
        result.private_id = result.type .. ':' .. result.id
        return result
    end

    t.get = function (id)
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
            if not result.kindx then
                result.kindx = 0
            end
            if not result.key then
                if not result.indx then
                    return t.vars[result.private_id]
                end
            end
            if not result.indx then
                result.indx = 0
            end
            if t.vars[result.private_id][result.indx] then
                if t.vars[result.private_id][result.indx][result.key] then
                    if result.clean then
                        return t.vars[result.private_id][result.indx][result.key]
                    end
                    if t.vars[result.private_id][result.indx][result.key][result.kindx] then
                        return t.vars[result.private_id][result.indx][result.key][result.kindx]
                    end
                end
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
        elseif result.type == 'pv' then
            return t.vars_pv[result.mode][result.id]
        end
    end

    t._addvalue_new = function (result, value)
        local temp
        if result.type == 'var' then
            t.vars[result.private_id] = value
        elseif result.type == 'xavp' then
            if not result.indx then
                result.indx = 0
            end
            if not result.kindx then
                result.kindx = 0
            end
            if result.indx ~= 0 or result.kindx ~= 0 then
                error(string.format("xavp(%s) has not been initilizated", result.id))
            end
            t.vars[result.private_id] = Stack:new()
            temp = {}
            temp[result.key] = Stack:new()
            temp[result.key]:push(value)
            t.vars[result.private_id]:push(temp)
        elseif result.type == 'avp' then
            t.vars[result.private_id] = Stack:new()
            t.vars[result.private_id]:push(value)
        elseif result.type == 'pv' and result.mode == 'rw' then
            t.vars_pv.rw[result.id] = value
        end
    end

    t._addvalue_with_value = function (result, value)
        local temp
        if result.type == 'var' then
            t.vars[result.private_id] = value
        elseif result.type == 'xavp' then
            if not result.indx then
                if result.kindx and result.kindx ~= 0 then
                    error(string.format("kindx:%d must be 0", result.kindx))
                end
                temp = {}
                temp[result.key] = Stack:new()
                temp[result.key]:push(value)
                t.vars[result.private_id]:push(temp)
            else
                if t.vars[result.private_id][result.indx] == nil then
                    error(string.format("xavp(%s[%d]) does not exist", result.id, result.indx))
                elseif t.vars[result.private_id][result.indx] == false then
                    t.vars[result.private_id][result.indx] = {}
                end
                if not result.kindx then
                    result.kindx = 0
                end
                if not t.vars[result.private_id][result.indx][result.key] then
                    t.vars[result.private_id][result.indx][result.key] = Stack:new()
                    --error(string.format("t:%s result:%s", table.tostring(t.vars[result.private_id]), table.tostring(result)))
                end
                t.vars[result.private_id][result.indx][result.key]:push(value)
            end
        elseif result.type == 'avp' then
            t.vars[result.private_id]:push(value)
        elseif result.type == 'pv' and result.mode == 'rw' then
            t.vars_pv.rw[result.id] = value
        end
    end

    t._addvalue = function (id, value)
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
        t.log("dbg", string.format("sr.pv vars:%s", utable.tostring(t.vars)))
    end

    t.seti = function (id, value)
        if type(value) ~= 'number' then
            error("value is not a number")
        end
        t._addvalue(id, value)
    end

    t.sets = function (id, value)
        if type(value) ~= 'string' then
            error("value is not a string")
        end
        t._addvalue(id, value)
    end

    t.unset = function (id)
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
                        t.vars[result.private_id][result.indx] = false
                        return
                    end
                else
                    if not result.indx then
                        result.indx = 0
                    end
                end
                -- xavp(g[1]=>k)
                t.vars[result.private_id][result.indx][result.key] = nil
            end
        elseif result.type == 'avp' then
            t.vars[result.private_id] = nil
        elseif result.type == 'var' then
            t.vars[result.private_id] = nil
        end
        t.log("dbg", string.format("sr.pv vars:%s", utable.tostring(t.vars)))
    end

    t.is_null = function (id)
        local result = t._is(id)
        if not result then
            return true
        end
        if not t.vars[result.private_id] then
            return true
        end
        return false
    end

    t.log = function (level, message)
            if not t._logger_levels[level] then
                error(string.format("level %s unknown", level))
            end
            t._logger:log(t._logger_levels[level], message)
    end

    local pvMock_MT = { __index = pvMock }
    setmetatable(t, pvMock_MT)
    return t
end
-- end class
return pvMock
