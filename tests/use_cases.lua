--
-- Copyright 2013-2016 SipWise Team <development@sipwise.com>
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
require('luaunit')
local NGCPXAvp = require 'ngcp.xavp'
local NGCPAvp = require 'ngcp.avp'

local srMock = require 'mocks.sr'
sr = srMock:new()

-- luacheck: ignore TestUseCases
TestUseCases = {}

function TestUseCases:tearDown()
    sr.pv.vars = {}
end

function TestUseCases:test_copy_avp()
	local avp = NGCPAvp:new("tmp")
	local xavp = NGCPXAvp:new('callee', 'real_prefs')
	local vals = {1, 2, "3", 4}
	local okvals = {4, "3", 2, 1}

	for i=1,#vals do
		avp(vals[i])
	end
	assertItemsEquals(avp:all(), okvals)
	xavp:clean('cfu')
	assertItemsEquals(xavp:all('cfu'), nil)
	xavp('cfu', avp:all())
	assertItemsEquals(xavp:all('cfu'), okvals)
end
