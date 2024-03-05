--
-- Copyright 2014-2020 SipWise Team <development@sipwise.com>
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
local lu = require('luaunit')

local ksrMock = require 'mocks.ksr'
KSR = ksrMock:new()
local xavp_fmt = '$xavp(lua_dlgcnt_vals[0]=>%s)'
local mc
-- luacheck: ignore TestNGCPDlgCnt
TestNGCPDlgCnt = {} --class

    function TestNGCPDlgCnt:setUp()
        mc = lemock.controller()
        self.fake_redis = mc:mock()
        self.central = mc:mock()
        self.pair = mc:mock()

        package.loaded.redis = self.fake_redis
        local NGCPDlg = require 'ngcp.dlgcnt'

        self.dlg = NGCPDlg:new()
        lu.assertEvalToTrue(self.dlg)

        self.dlg.central.client = self.central;
        self.dlg.pair.client = self.pair
        self.dlg.config.debug = true
    end

    function TestNGCPDlgCnt:tearDown()
        KSR.pv.vars = {}
    end

    function TestNGCPDlgCnt:test_set_1()
        self.central:ping() ;mc :returns(true)
        self.central:incr("total")  ;mc :returns(1)

        self.pair:ping() ;mc :returns(true)
        self.pair:lpush("callid0", "total")  ;mc :returns(1)

        mc:replay()
        self.dlg:set("callid0", "total")
        mc:verify()

        lu.assertEquals(KSR.pv.get(string.format(xavp_fmt, "total")), 1)
    end

    function TestNGCPDlgCnt:test_set_2()
        self.central:ping() ;mc :returns(true)
        self.central:incr("total")  ;mc :returns(1)

        self.pair:ping() ;mc :returns(true)
        self.pair:lpush("callid0", "total")  ;mc :returns(1)

        self.central.ping(self.central) ;mc :returns(true)
        self.pair:ping() ;mc :returns(true)
        self.central:incr("total")  ;mc :returns(2)
        self.pair:lpush("callid1", "total")  ;mc :returns(1)

        mc:replay()
        self.dlg:set("callid0", "total")
        self.dlg:set("callid1", "total")
        mc:verify()

        lu.assertEquals(KSR.pv.get(string.format(xavp_fmt, "total")), 2)
    end

    function TestNGCPDlgCnt:test_del()
        self.pair:ping() ;mc :returns(true)
        self.pair:lpop("callid0") ;mc :returns("total")
        self.pair:lpop("callid0") ;mc :returns(nil)

        self.central:ping() ;mc :returns(true)
        self.central:decr("total")  ;mc :returns(1)

        mc:replay()
        self.dlg:del("callid0")
        mc:verify()

        lu.assertIs(self.dlg.central.client, self.central)
        lu.assertIs(self.dlg.pair.client, self.pair)
        lu.assertEquals(KSR.pv.get(string.format(xavp_fmt, "total")), 1)
    end

    function TestNGCPDlgCnt:test_del_zero()
        self.pair:ping() ;mc :returns(true)
        self.pair:lpop("callid0") ;mc :returns("total")
        self.pair:lpop("callid0") ;mc :returns(nil)
        self.central:del("total") ;mc :returns(true)

        self.central:ping() ;mc :returns(true)
        self.central:decr("total")  ;mc :returns(0)

        mc:replay()
        self.dlg:del("callid0")
        mc:verify()

        lu.assertIs(self.dlg.central.client, self.central)
        lu.assertIs(self.dlg.pair.client, self.pair)
        lu.assertIsNil(KSR.pv.get(string.format(xavp_fmt, "total")))
    end

    function TestNGCPDlgCnt:test_del_negative()
        local c = self.dlg.config
        c.allow_negative = false
        self.pair:ping() ;mc :returns(true)
        self.pair:lpop("callid0") ;mc :returns("total")
        self.pair:lpop("callid0") ;mc :returns(nil)

        self.central:ping() ;mc :returns(true)
        self.central:decr("total")  ;mc :returns(-1)
        self.central:del("total") ;mc :returns(true)

        mc:replay()
        self.dlg:del("callid0")
        mc:verify()

        lu.assertIs(self.dlg.central.client, self.central)
        lu.assertIs(self.dlg.pair.client, self.pair)
        lu.assertIsNil(KSR.pv.get(string.format(xavp_fmt, "total")))
    end

    function TestNGCPDlgCnt:test_del_negative_ok()
        local c = self.dlg.config
        c.allow_negative = true
        self.pair:ping() ;mc :returns(true)
        self.pair:lpop("callid0") ;mc :returns("total")
        self.pair:lpop("callid0") ;mc :returns(nil)

        self.central:ping() ;mc :returns(true)
        self.central:decr("total")  ;mc :returns(-1)

        mc:replay()
        self.dlg:del("callid0")
        mc:verify()

        lu.assertIs(self.dlg.central.client, self.central)
        lu.assertIs(self.dlg.pair.client, self.pair)
        lu.assertEquals(KSR.pv.get(string.format(xavp_fmt, "total")), -1)
    end

    function TestNGCPDlgCnt:test_del_multy()
        self.pair:ping() ;mc :returns(true)
        self.pair:lpop("callid0") ;mc :returns("total")

        self.central:ping() ;mc :returns(true)
        self.central:decr("total")  ;mc :returns(0)
        self.central:del("total") ;mc :returns(true)

        self.pair:lpop("callid0") ;mc :returns("whatever:gogo")
        self.central:decr("whatever:gogo")  ;mc :returns(0)
        self.central:del("whatever:gogo") ;mc :returns(true)

        self.pair:lpop("callid0") ;mc :returns("whatever:go")
        self.central:decr("whatever:go") ;mc :returns(0)
        self.central:del("whatever:go") ;mc :returns(true)

        self.pair:lpop("callid0") ;mc :returns(nil)

        mc:replay()
        self.dlg:del("callid0")
        mc:verify()

        lu.assertIs(self.dlg.central.client, self.central)
        lu.assertIs(self.dlg.pair.client, self.pair)
        lu.assertIsNil(KSR.pv.get(string.format(xavp_fmt, "total")))
    end

    function TestNGCPDlgCnt:test_is_in_set_fail()
        self.pair:ping() ;mc :returns(true)
        self.pair:lrange("callid0", 0, -1)  ;mc :returns(nil)

        mc:replay()
        local res = self.dlg:is_in_set("callid0", "fake")
        mc:verify()

        lu.assertIs(self.dlg.central.client, self.central)
        lu.assertIs(self.dlg.pair.client, self.pair)
        lu.assertFalse(res)
    end

    function TestNGCPDlgCnt:test_is_in_set_ok()
        self.pair:ping() ;mc :returns(true)
        self.pair:lrange("callid0", 0, -1)  ;mc :returns({"whatever", "fake", "jojo"})

        mc:replay()
        local res = self.dlg:is_in_set("callid0", "fake")
        mc:verify()

        lu.assertIs(self.dlg.central.client, self.central)
        lu.assertIs(self.dlg.pair.client, self.pair)
        lu.assertTrue(res)
    end

    function TestNGCPDlgCnt:test_is_in_set_regex_ok()
        self.pair:ping() ;mc :returns(true)
        self.pair:lrange("callid0", 0, -1)  ;mc :returns({"user:whatever", "fake", "jojo"})

        mc:replay()
        local res = self.dlg:is_in_set_regex("callid0", "^user:")
        mc:verify()

        lu.assertIs(self.dlg.central.client, self.central)
        lu.assertIs(self.dlg.pair.client, self.pair)
        lu.assertTrue(res)
    end

    function TestNGCPDlgCnt:test_is_in_set_regex_fail()
        self.pair:ping() ;mc :returns(true)
        self.pair:lrange("callid0", 0, -1)  ;mc :returns({"user:whatever", "fake", "jojo"})

        mc:replay()
        local res = self.dlg:is_in_set_regex("callid0", "^ser:")
        mc:verify()

        lu.assertIs(self.dlg.central.client, self.central)
        lu.assertIs(self.dlg.pair.client, self.pair)
        lu.assertFalse(res)
    end

    function TestNGCPDlgCnt:test_del_key()
        self.pair:ping() ;mc :returns(true)
        self.pair:lrem("callid0", 1, "key1") ;mc :returns(1)

        self.central:ping() ;mc :returns(true)
        self.central:decr("key1")  ;mc :returns(1)

        mc:replay()
        self.dlg:del_key("callid0", "key1")
        mc:verify()

        lu.assertIs(self.dlg.central.client, self.central)
        lu.assertIs(self.dlg.pair.client, self.pair)
    end

    function TestNGCPDlgCnt:test_logfile()
        local KSR_old = KSR
        local config = {
            logfile = '/dev/null'
        }
        local NGCPDlg = require 'ngcp.dlgcnt'
        dlg = NGCPDlg:new(config)
        -- no changes in global
        lu.assertIs(KSR, KSR_old)
        lu.assertEvalToTrue(dlg.KSR)
        lu.assertEvalToTrue(dlg.KSR._logger)
    end

-- class TestNGCPDlgCnt
--EOF
