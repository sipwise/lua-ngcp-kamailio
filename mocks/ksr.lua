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
local pvxMock = require 'mocks.pvx'

-- class srMock
local ksrMock = {
    __class__ = 'ksrMock',
    _logger = log_file("reports/ksr_%s.log", "%Y-%m-%d"),
    _logger_levels = {
        dbg  = logging.DEBUG,
        info = logging.INFO,
        warn = logging.WARN,
        err  = logging.ERROR,
        crit = logging.FATAL
    }
}
local ksrMock_MT = { __index = ksrMock, __newindex = lemock.controller():mock() }
    function ksrMock.new()
        local t = {}
        t.hdr = hdrMock.new()
        t.pv = pvMock.new(t.hdr)
            function t.log(level, message)
                if not t._logger_levels[level] then
                    error(string.format("level %s unknown", tostring(level)))
                end
                t._logger:log(t._logger_levels[level], message)
            end
            function t.dbg(message)
                t._logger:log(logging.DEBUG, message)
            end
            function t.err(message)
                t._logger:log(logging.ERROR, message)
            end
            function t.info(message)
                t._logger:log(logging.INFO, message)
            end
            function t.notice(message)
                t._logger:log(logging.INFO, message)
            end
            function t.warn(message)
                t._logger:log(logging.WARN, message)
            end
            function t.crit(message)
                t._logger:log(logging.FATAL, message)
            end
        t.pvx = pvxMock.new(t.pv)
        setmetatable(t, ksrMock_MT)
        return t
    end
-- end class
return ksrMock
