--
-- Copyright 2014-2016 SipWise Team <development@sipwise.com>
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
-- luacheck: ignore TestNGCPDlgCnt
TestNGCPDlgCnt = {} --class

    function TestNGCPDlgCnt:setUp()
        mc = lemock.controller()
        self.fake_redis = mc:mock()
        self.client = mc:mock()
        self.scan_param = {match=""}

        package.loaded.redis = self.fake_redis
        local NGCPDlg = require 'ngcp.dlgcnt'

        self.dlg = NGCPDlg.new()
        assertTrue(self.dlg)

        self.dlg.client = self.client
        self.dlg.scan_param = self.scan_param
    end

    function TestNGCPDlgCnt:test_set_1()
        self.client:ping() ;mc :returns(true)
        self.client:set("callid0:total", 'OK')  ;mc :returns(true)
        self.client:expire("callid0:total", self.dlg.config.default_expire) ;mc :returns(true)

        mc:replay()
        self.dlg:set("callid0", "total")
        mc:verify()
    end

    function TestNGCPDlgCnt:test_set_1_expires()
        self.client:ping() ;mc :returns(true)
        self.client:set("callid0:total", 'OK')  ;mc :returns(true)
        self.client:expire("callid0:total", 5) ;mc :returns(true)

        mc:replay()
        self.dlg:set("callid0", "total", 5)
        mc:verify()
    end

    function TestNGCPDlgCnt:test_del()
        self.scan_param.match = 'callid0:*'
        self.client:ping() ;mc :returns(true)
        self.client:scan(0, self.scan_param) ;mc :returns({"0", {'callid0:total'}})
        self.client:del("callid0:total")  ;mc :returns(1)

        mc:replay()
        self.dlg:del("callid0")
        mc:verify()
    end

    function TestNGCPDlgCnt:test_del_zero()
        self.scan_param.match = 'callid0:*'
        self.client:ping() ;mc :returns(true)
        self.client:scan(0, self.scan_param) ;mc :returns({"0",{}})

        mc:replay()
        self.dlg:del("callid0")
        mc:verify()
    end

    function TestNGCPDlgCnt:test_del_multy()
        self.scan_param.match = 'callid0:*'
        local keys = {'callid0:total', 'callid0:totalout'}
        self.client:ping() ;mc :returns(true)
        self.client:scan(0, self.scan_param) ;mc :returns({"12", {keys[1]}})
        self.client:scan(12, self.scan_param) ;mc :returns({"0", {keys[2]}})
        self.client:del("callid0:total")  ;mc :returns(1)
        self.client:del("callid0:totalout")  ;mc :returns(1)

        mc:replay()
        self.dlg:del("callid0")
        mc:verify()
    end

    function TestNGCPDlgCnt:test_del_key()
        self.client:ping() ;mc :returns(true)
        self.client:del("callid0:total")  ;mc :returns(1)

        mc:replay()
        self.dlg:del_key("callid0", "total")
        mc:verify()
    end

    function TestNGCPDlgCnt:test_get_size()
        self.scan_param.match = '*:total'
        local keys = {'callid0:total', 'callid0:totalout'}
        self.client:ping() ;mc :returns(true)
        self.client:scan(0, self.scan_param) ;mc :returns({"0", {keys[1]}})

        mc:replay()
        local len = self.dlg:get_size("total")
        mc:verify()
        assertEquals(len, 1)
    end

    function TestNGCPDlgCnt:test_exists_ok()
        self.scan_param.match = 'callid0:*'
        local keys = {'callid0:total', 'callid0:totalout'}
        self.client:ping() ;mc :returns(true)
        self.client:scan(0, self.scan_param) ;mc :returns({"0", keys})

        mc:replay()
        local res = self.dlg:exists("callid0")
        mc:verify()
        assertTrue(res)
    end

    function TestNGCPDlgCnt:test_exists_ko()
        self.scan_param.match = 'callid1:*'
        self.client:ping() ;mc :returns(true)
        self.client:scan(0, self.scan_param) ;mc :returns({"0", {}})

        mc:replay()
        local res = self.dlg:exists("callid1")
        mc:verify()
        assertFalse(res)
    end

    function TestNGCPDlgCnt:test_get_ok()
        self.scan_param.match = 'callid0:*'
        local keys = {'callid0:total', 'callid0:totalout'}
        self.client:ping() ;mc :returns(true)
        self.client:scan(0, self.scan_param) ;mc :returns({"0", keys})

        mc:replay()
        local res = self.dlg:get("callid0")
        mc:verify()
        assertItemsEquals(res, keys)
    end

    function TestNGCPDlgCnt:test_get_ko()
        self.scan_param.match = 'callid1:*'
        self.client:ping() ;mc :returns(true)
        self.client:scan(0, self.scan_param) ;mc :returns({"0", {}})

        mc:replay()
        local res = self.dlg:get("callid1")
        mc:verify()
        assertItemsEquals(res, {})
    end

-- class TestNGCPDlgCnt
--EOF