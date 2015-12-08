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
--

local lemock = require('lemock')
require('luaunit')

local srMock = require 'mocks.sr'
sr = srMock:new()

local mc

-- luacheck: ignore TestNGCPDlgList
TestNGCPDlgList = {} --class

function TestNGCPDlgList:setUp()
    mc = lemock.controller()
    self.fake_redis = mc:mock()
    self.central = mc:mock()
    self.pair = mc:mock()

    package.loaded.redis = self.fake_redis
    local NGCPDlgList = require 'ngcp.dlglist'

    self.dlg = NGCPDlgList.new()
    assertTrue(self.dlg)

    self.dlg.central = self.central;
    self.dlg.pair = self.pair
end

-- class
