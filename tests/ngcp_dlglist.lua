--
-- Copyright 2013-2017 SipWise Team <development@sipwise.com>
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

function TestNGCPDlgList:test_exists()
    self.pair:ping() ;mc :returns(true)
    self.pair:llen("list:fakeAAA") ;mc :returns(0)

    mc:replay()
    local ok = self.dlg:exists('fakeAAA')
    mc:verify()

    assertFalse(ok)
end

function TestNGCPDlgList:test_add()
    local key, callid = 'key1', 'fakeAAA'
    self.central:ping() ;mc :returns(true)
    self.central:rpush(key, callid) ;mc :returns(1)
    self.pair:ping() ;mc :returns(true)
    self.pair:lpush("list:"..callid, key) ;mc :returns(1)

    mc:replay()
    self.dlg:add(callid, key)
    mc:verify()
end

function TestNGCPDlgList:test_del()
    local key, callid = 'key1', 'fakeAAA'
    self.pair:ping() ;mc :returns(true)
    self.pair:lrem("list:"..callid, 0, key) ;mc :returns(1)
    self.central:ping() ;mc :returns(true)
    self.central:lrem(key, 0, callid) ;mc :returns(true)
    self.central:llen(key) ;mc :returns(0)
    self.central:del(key) ;mc :returns(true)

    mc:replay()
    self.dlg:del(callid, key)
    mc:verify()
end

function TestNGCPDlgList:test_is_in_set()
    local key, callid = 'key1', 'fakeAAA'
    local content = {'key0', 'key1', 'key2'}
    self.pair:ping() ;mc :returns(true)
    self.pair:lrange("list:"..callid, 0, -1) ;mc :returns(content)
    self.pair:ping() ;mc :returns(true)
    self.pair:lrange("list:"..callid, 0, -1) ;mc :returns(content)

    mc:replay()
    local ok = self.dlg:is_in_set(callid, key)
    local ko = self.dlg:is_in_set(callid, 'key3')
    mc:verify()

    assertTrue(ok)
    assertFalse(ko)
end

function TestNGCPDlgList:test_destroy_empty()
    local callid = 'fakeAAA'
    self.pair:ping() ;mc :returns(true)
    self.pair:lpop("list:"..callid) ;mc :returns(nil)
    self.pair:del("list:"..callid) ;mc :returns(true)

    mc:replay()
    assertError(self.dlg.destroy, self.dlg, callid)
    mc:verify()
end

function TestNGCPDlgList:test_destroy()
    local callid = 'fakeAAA'
    self.pair:ping() ;mc :returns(true)
    self.pair:lpop("list:"..callid) ;mc :returns('key1')
    self.central:ping() ;mc :returns(true)
    self.central:lrem('key1', 0, callid) ;mc :returns(true)
    self.central:llen('key1') ;mc :returns(1)
    self.pair:lpop("list:"..callid) ;mc :returns('key2')
    self.central:lrem('key2', 0, callid) ;mc :returns(true)
    self.central:llen('key2') ;mc :returns(1)
    self.pair:lpop("list:"..callid) ;mc :returns(nil)

    mc:replay()
    self.dlg:destroy(callid)
    mc:verify()
end
-- class
