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
local lemock = require ('lemock')

local hdrMock = require 'mocks.hdr'
local pvMock = require 'mocks.pv'
local xavpMock = require 'mocks.xavp'

-- class srMock
local srMock = {
    __class__ = 'srMock',
    _logger = log_file("reports/sr_%s.log", "%Y-%m-%d"),
    _logger_levels = {
        dbg  = logging.DEBUG,
        info = logging.INFO,
        warn = logging.WARN,
        err  = logging.ERROR,
        crit = logging.FATAL
    }
}
local srMock_MT = { __index = srMock, __newindex = lemock.controller():mock() }
    function srMock.new()
        local t = {}
        t.hdr = hdrMock.new()
        t.pv = pvMock.new(t.hdr)
            function t.log(level, message)
                if not t._logger_levels[level] then
                    error(string.format("level %s unknown", tostring(level)))
                end
                t._logger:log(t._logger_levels[level], message)
            end
        t.xavp = xavpMock.new(t.pv)
        setmetatable(t, srMock_MT)
        return t
    end
-- end class
return srMock
