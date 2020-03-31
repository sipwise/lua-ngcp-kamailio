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

luaunit = require('luaunit')
local ksrMock = require 'mocks.ksr'

-- luacheck: ignore TestKEMIMock
TestKEMIMock = {}
    function TestKEMIMock:setUp()
        self.KSR = ksrMock.new()
    end

    function TestKEMIMock:test_hdr_get()
        self.KSR.hdr.insert("From: hola\r\n")
        assertEquals(self.KSR.hdr.headers, {"From: hola\r\n"})
        assertEquals(self.KSR.pv.get("$hdr(From)"), "hola")
    end

    function TestKEMIMock:test_log()
        assertEvalToTrue(self.KSR.log)
        self.KSR.log("dbg", "Hi dude!")
        assertError(self.KSR.log, "debug", "Hi dude!")
    end
