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
require('luaunit')
require 'mocks.sr'
local NGCPDlgVar = require 'ngcp.dlg_var'

sr = srMock:new()

TestNGCPDlgVar = {} --class
    function TestNGCPDlgVar:setUp()
        self.var = NGCPDlgVar:new("testid")
    end

    function TestNGCPDlgVar:tearDown()
        sr.pv.vars = {}
    end

    function TestNGCPDlgVar:test_dlg_var_id()
        assertEquals(self.var.id, "$dlg_var(testid)")
    end

    function TestNGCPDlgVar:test_dlg_var_get()
        sr.pv.sets("$dlg_var(testid)", "value")
        assertEquals(self.var(), "value")
        sr.pv.sets("$dlg_var(testid)", "1")
        assertItemsEquals(self.var(), "1")
    end

    function TestNGCPDlgVar:test_dlg_var_set()
        self.var(1)
        assertEquals(self.var(),1)
        self.var("a")
        assertEquals(self.var(), "a")
    end

    function TestNGCPDlgVar:test_clean()
        self.var(1)
        self.var:clean()
        assertFalse(self.var())
    end

    function TestNGCPDlgVar:test_log()
        self.var:log()
    end

    function TestNGCPDlgVar:test_tostring()
        self.var(1)
        assertEquals(tostring(self.var), "$dlg_var(testid):1")
        self.var("hola")
        assertEquals(tostring(self.var), "$dlg_var(testid):hola")
    end
-- class TestNGCPDlgVar
--EOF