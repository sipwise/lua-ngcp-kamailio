--
-- Copyright 2013-2020 SipWise Team <development@sipwise.com>
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

local logging = require('logging')
local log_file = require('logging.file')
local ut = require('ngcp.utils')

local hdrMock = {
    __class__ = 'hdrMock',
    headers = {},
    headers_reply = {},
    _logger = log_file('reports/ksr_hdr_%s.log', '%Y-%m-%d'),
    _logger_levels = {
        dbg  = logging.DEBUG,
        info = logging.INFO,
        warn = logging.WARN,
        err  = logging.ERROR,
        crit = logging.FATAL
    }
}
    function hdrMock.new()
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
          if text then
            local pattern = "^" .. text .. ": (.+)\r\n$"
            for _,v in ipairs(t.headers) do
                local result = string.match(v, pattern)
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
            if text then
                for i,v in ipairs(t.headers) do
                    if ut.string.starts(v, text .. ":") then
                        table.remove(t.headers, i)
                        return
                    end
                end
            end
        end

        local hdrMock_MT = { __index = hdrMock }
        setmetatable(t, hdrMock_MT)
        return t
    end
-- end class
return hdrMock
