--
-- Copyright 2013-2015 SipWise Team <development@sipwise.com>
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

local logging = require ('logging')
local log_file = require ('logging.file')

-- class pvxMock
local pvxMock = {
    __class__ =  'pvxMock',
    _logger = log_file("reports/pvx_%s.log", "%Y-%m-%d"),
    _logger_levels = {
        dbg  = logging.DEBUG,
        info = logging.INFO,
        warn = logging.WARN,
        err  = logging.ERROR,
        crit = logging.FATAL
    }
}
    function pvxMock.new(pv)
        local t = {}

        t.__class__ = 'pvxMock'
        t.pv = pv

        function t._get_xavp(xavp_name, mode)
            local private_id = "xavp:" .. xavp_name
            if not t.pv.vars[private_id] then
                if mode == "NULL_NONE" then
                    return nil
                elseif mode == "NULL_EMPTY" then
                    return ""
                elseif mode == "NULL_PRINT" then
                    return "<null>"
                end
            else
                local s = tostring(t.pv.vars[private_id])
                return "<<xavp:"..s:sub(8)..">>"
            end
        end

        function t.xavp_get(xavp_name)
            return t._get_xavp(xavp_name, "NULL_NONE")
        end

        function t.xavp_gete(xavp_name)
            return t._get_xavp(xavp_name, "NULL_EMPTY")
        end

        function t.xavp_getw(xavp_name)
            return t._get_xavp(xavp_name, "NULL_PRINT")
        end

        function t.xavp_get_keys(xavp_name, index)
            local private_id = "xavp:" .. xavp_name
            local output = {}
            if not t.pv.vars[private_id] then
                error(string.format("%s not found", xavp_name))
            elseif not t.pv.vars[private_id][index] then
                error(string.format("%s[%s] not found",
                    xavp_name, tostring(index)))
            end
            local xavp = t.pv.vars[private_id][index]
            for k,_ in pairs(xavp) do
                table.insert(output, k)
            end
            return output
        end

        function t.xavp_getd(xavp_name)
            local private_id = "xavp:" .. xavp_name
            local output = {}

            if not t.pv.vars[private_id] then
                error(string.format("%s not found", xavp_name))
            end
            for _,v in ipairs(t.pv.vars[private_id]:list()) do
                local avp = {}
                for k, s in pairs(v) do
                    avp[k] = s:list()
                end
                table.insert(output, avp)
            end
            return output
        end


        function t.xavp_getd_p1(xavp_name, index)
            local private_id = "xavp:" .. xavp_name

            if not t.pv.vars[private_id] then
                error(string.format("%s not found", xavp_name))
            elseif not t.pv.vars[private_id][index] then
                error(string.format("%s[%s] not found",
                    xavp_name, tostring(index)))
            end
            local output = {}
            for k, s in pairs(t.pv.vars[private_id][index]) do
                output[k] = s:list()
            end
            return output
        end

        local pvxMock_MT = { __index = pvxMock }
        setmetatable(t, pvxMock_MT)
        return t
    end
--end class
return pvxMock
