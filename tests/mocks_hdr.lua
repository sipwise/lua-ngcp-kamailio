--
-- Copyright 2015 SipWise Team <development@sipwise.com>
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
-- luaunit is not lua5.2 compatible
-- luacheck: ignore assertEquals assertTrue assertItemsEquals assertFalse
require('luaunit')
local hdrMock = require 'mocks.hdr'

-- luacheck: ignore TestHDRMock
TestHDRMock = {}
    function TestHDRMock:setUp()
        self.hdr = hdrMock.new()
    end

    function TestHDRMock:tearDown()
        self.hdr.headers = {}
        self.hdr.headers_reply = {}
    end

    function TestHDRMock:test_is_header()
        assertTrue(self.hdr._is_header("From: hi@there.com\r\n"))
        assertFalse(self.hdr._is_header("From hi@there.com\r\n"))
        assertFalse(self.hdr._is_header("From: hi@there.com\r"))
        assertFalse(self.hdr._is_header("From : hi@there.com\n"))
        assertFalse(self.hdr._is_header("From : hi@there.com\n\r"))
        assertTrue(self.hdr._is_header("From: hi@there.com:8080\r\n"))
    end

    function TestHDRMock:test_append()
        assertFalse(self.hdr._get_header("From"))
        self.hdr.append("From: hi@there.com\r\n")
        assertEquals(self.hdr.headers, {"From: hi@there.com\r\n"})
        self.hdr.append("To: bye@there.com\r\n")
        assertEquals(self.hdr.headers, {"From: hi@there.com\r\n", "To: bye@there.com\r\n"})
    end

    function TestHDRMock:test_insert()
        assertFalse(self.hdr._get_header("From"))
        self.hdr.insert("From: hi@there.com\r\n")
        assertEquals(self.hdr.headers, {"From: hi@there.com\r\n"})
        self.hdr.insert("To: bye@there.com\r\n")
        assertEquals(self.hdr.headers, {"To: bye@there.com\r\n", "From: hi@there.com\r\n"})
    end

    function TestHDRMock:test_get_header()
        self:test_append()
        assertEquals(self.hdr._get_header("From"), "hi@there.com")
    end

    function TestHDRMock:test_hdr_get()
        self.hdr.insert("From: hola\r\n")
        assertEquals(self.hdr.headers, {"From: hola\r\n"})
    end
-- end class
