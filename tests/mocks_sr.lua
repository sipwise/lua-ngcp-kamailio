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

require('luaunit')
local ksrMock = require 'mocks.ksr'
local srMock = require 'mocks.sr'

-- luacheck: ignore TestSRMock
TestSRMock = {}
    function TestSRMock:setUp()
        self.ksr = ksrMock.new()
        self.sr = srMock.new(self.ksr)
    end

    function TestSRMock:test_hdr()
        assertIs(self.sr.hdr, self.ksr.hdr)
    end

    function TestSRMock:test_hdr_get()
        self.sr.hdr.insert("From: hola\r\n")
        assertEquals(self.sr.hdr.headers, {"From: hola\r\n"})
        assertEquals(self.sr.pv.get("$hdr(From)"), "hola")
    end

    function TestSRMock:test_pv()
        self.sr.pv.sets("$var(test)", "value")
        assertEquals(self.sr.pv.get("$var(test)"), "value")
        assertIs(self.sr.pv, self.ksr.pv)
    end

    function TestSRMock:test_pv_get()
        assertIs(self.sr.pv, self.ksr.pv)
    end

    function TestSRMock:test_log()
        assertNotNil(self.sr.log)
    end

    function TestSRMock:test_log_dbg()
        self.sr.log("dbg", "Hi dude!")
        assertError(self.sr.log, "debug", "Hi dude!")
    end

    function TestSRMock:test_xavp()
        assertNotNil(self.sr.xavp)
    end

    function TestSRMock:test_xavp_get()
        assertErrorMsgContains(
            "dummy not found", self.sr.xavp.get, "dummy", 0, 0)
    end
