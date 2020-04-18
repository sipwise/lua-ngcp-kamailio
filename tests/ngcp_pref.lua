--
-- Copyright 2013 SipWise Team <development@sipwise.com>
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
--
local lu = require('luaunit')
local NGCPPrefs = require 'ngcp.pref'
-- luacheck: globals KSR
local ksrMock = require 'mocks.ksr'
KSR = ksrMock.new()

-- luacheck: ignore TestNGCPPrefs
TestNGCPPrefs = {} --class

    function TestNGCPPrefs:tearDown()
        KSR.pv.vars = {}
    end

    function TestNGCPPrefs:test_check_level()
        lu.assertTrue(NGCPPrefs:check_level("caller"))
        lu.assertTrue(NGCPPrefs:check_level("callee"))
        lu.assertFalse(NGCPPrefs:check_level("what"))
    end

    function TestNGCPPrefs:test_xavp_wrong_level()
        local pref = NGCPPrefs:create()
        lu.assertErrorMsgContains("unknown level", pref.xavp, pref, 'what')
    end
-- class TestNGCP