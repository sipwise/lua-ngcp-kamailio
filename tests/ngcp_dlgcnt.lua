--
-- Copyright 2014 SipWise Team <development@sipwise.com>
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
require 'ngcp.utils'

if not sr then
    require 'mocks.sr'
    sr = srMock:new()
else
    argv = {}
end

local mc

TestNGCPDlgCnt = {} --class

    function TestNGCPDlgCnt:setUp()
        mc = lemock.controller()
        self.fake_redis = mc:mock()
        self.central = mc:mock()
        self.pair = mc:mock()

        package.loaded.redis = self.fake_redis
        local NGCPDlg = require 'ngcp.dlgcnt'

        self.dlg = NGCPDlg.new()
        assertTrue(self.dlg)

        self.dlg.central = self.central;
        self.dlg.pair = self.pair
    end

    function TestNGCPDlgCnt:test_connection_ok()
        local prev = self.central
        self.central:ping() ;mc :returns(true)

        mc:replay()
        local ok = self.dlg._test_connection(self.central)
        mc:verify()

        assertTrue(ok)
        assertIs(prev, self.central)
    end

    function TestNGCPDlgCnt:test_connection_fail()
        local prev = self.central
        self.central:ping() ;mc :error("error")

        mc:replay()
        local res = self.dlg._test_connection(self.central)
        mc:verify()

        assertFalse(res)
        assertIs(prev, self.central)
    end

    function TestNGCPDlgCnt:test_connect_ok()
        local c = self.dlg.config
        self.fake_redis.connect(c.pair.host,c.pair.port) ;mc :returns(self.pair)
        self.pair:select(c.pair.db) ;mc :returns(true)

        mc:replay()
        local res = self.dlg._connect(c.pair)
        mc:verify()
        assertIs(res, self.pair)
    end

    function TestNGCPDlgCnt:test_set_1()
        local c = self.dlg.config
        self.central:ping() ;mc :returns(true)
        self.central:incr("total")  ;mc :returns(1)

        self.pair:ping() ;mc :returns(true)
        self.pair:lpush("callid0", "total")  ;mc :returns(1)

        mc:replay()
        self.dlg:set("callid0", "total")
        mc:verify()
    end

    function TestNGCPDlgCnt:test_set_2()
        local c = self.dlg.config
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
    end

    function TestNGCPDlgCnt:test_del()
        local c = self.dlg.config
        self.pair:ping() ;mc :returns(true)
        self.pair:lpop("callid0") ;mc :returns("total")
        self.pair:lpop("callid0") ;mc :returns(nil)

        self.central:ping() ;mc :returns(true)
        self.central:decr("total")  ;mc :returns(1)

        mc:replay()
        self.dlg:del("callid0")
        mc:verify()

        assertIs(self.dlg.central, self.central)
        assertIs(self.dlg.pair, self.pair)
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

        assertIs(self.dlg.central, self.central)
        assertIs(self.dlg.pair, self.pair)
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

        assertIs(self.dlg.central, self.central)
        assertIs(self.dlg.pair, self.pair)
    end

    function TestNGCPDlgCnt:test_del_multy()
        local c = self.dlg.config
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

        assertIs(self.dlg.central, self.central)
        assertIs(self.dlg.pair, self.pair)
    end

-- class TestNGCPDlgCnt
--EOF
