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

describe("use cases", function()
    local NGCPXAvp
    local NGCPAvp

    setup(function()
        local ksrMock = require 'mocks.ksr'
        _G.KSR = ksrMock.new()
        NGCPXAvp = require 'ngcp.xavp'
        NGCPAvp = require 'ngcp.avp'
    end)

    after_each(function()
        _G.KSR.pv.vars = {}
    end)

    it("copy_avp", function()
        local avp = NGCPAvp:new("tmp")
        local xavp = NGCPXAvp:new('callee', 'real_prefs')
        local vals = {1, 2, "3", 4}
        local okvals = {4, "3", 2, 1}

        for i=1,#vals do
            avp(vals[i])
        end
        assert.equal_items(avp:all(), okvals)
        xavp:clean('cfu')
        assert.equal_items(xavp:all('cfu'), nil)
        xavp('cfu', avp:all())
        assert.equal_items(xavp:all('cfu'), okvals)
    end)
end)
