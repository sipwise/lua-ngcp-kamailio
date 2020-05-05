--
-- Copyright 2020 SipWise Team <development@sipwise.com>
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

describe("preferences", function()
    local NGCPPrefs = require 'ngcp.pref'

    setup(function()
        local ksrMock = require 'mocks.ksr'
        _G.KSR = ksrMock.new()
    end)

    after_each(function()
        _G.KSR.pv.vars = {}
    end)

    it("check_level", function()
        assert.True(NGCPPrefs:check_level("caller"))
        assert.True(NGCPPrefs:check_level("callee"))
        assert.False(NGCPPrefs:check_level("what"))
    end)

    it("xavp_wrong_level", function()
        local pref = NGCPPrefs:create()
        assert.has_errors(function() pref.xavp(pref, 'what') end)
    end)

end)
