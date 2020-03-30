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

-- class xavpMock
local xavpMock = {
    __class__ =  'xavpMock',
    _logger = log_file("reports/xavp_%s.log", "%Y-%m-%d"),
    _logger_levels = {
        dbg  = logging.DEBUG,
        info = logging.INFO,
        warn = logging.WARN,
        err  = logging.ERROR,
        crit = logging.FATAL
    }
}
    function xavpMock.new(pv)
        local t = {}

        t.__class__ = 'xavpMock'
        t.pv = pv

        function t._get_xavp(xavp_name, index, mode)
            local private_id = "xavp:" .. xavp_name
            local temp = {}
            if not t.pv.vars[private_id] then
                error(string.format("%s not found", xavp_name))
            elseif not t.pv.vars[private_id][index] then
                error(string.format("%s[%s] not found",
                    xavp_name, tostring(index)))
            end
            if mode == 0 then
                for k,v in pairs(t.pv.vars[private_id][index]) do
                    temp[k] = v:list()
                end
            else
                for k,v in pairs(t.pv.vars[private_id][index]) do
                    temp[k] = v[0]
                end
            end
            return temp
        end

        function t.get_keys(xavp_name, index)
            local output = {}

            local xavp = t._get_xavp(xavp_name, index, 1)
            for k,_ in pairs(xavp) do
                table.insert(output, k)
            end
            return output
        end

        function t.get(xavp_name, index, mode)
            if not mode then mode = 0 end
            local xavp = t._get_xavp(xavp_name, index, mode)
            return xavp
        end

        local xavpMock_MT = { __index = xavpMock }
        setmetatable(t, xavpMock_MT)
        return t
    end
--end class
return xavpMock
