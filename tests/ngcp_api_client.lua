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

require('luaunit')

local lemock = require('lemock')
local srMock = require 'mocks.sr'

sr = srMock:new()

local mc

-- luacheck: ignore TestNGCPAPIClient
TestNGCPAPIClient = {} --class

    function TestNGCPAPIClient:setUp()
        mc = lemock.controller()
        self.c = mc:mock()
        self.j = mc:mock()

        local NGCPAPIClient = require 'ngcp.api_client'

        self.client = NGCPAPIClient.new()
        assertTrue(self.client)

        self.client.c = self.c;
        self.client.j = self.j;

    end

    function TestNGCPAPIClient:test_api_request()
        local method  = 'GET'
        local request = 'domains'

        local result = {}
        local ipport = self.client.config.ip .. ':' .. self.client.config.port
        local userpass = self.client.config.user .. ':' .. self.client.config.pass

        local headers = {
            'Content-Type: application/json',
            'Prefer: return=internal',
            'NGCP-UserAgent: NGCP::API::Client'
        }

        self.c:setopt(curl.OPT_VERBOSE, 0) ;mc :returns(true)

        self.c:setopt(curl.OPT_SSL_VERIFYHOST, 0) ;mc :returns(true)
        self.c:setopt(curl.OPT_SSL_VERIFYPEER, 0) ;mc :returns(true)

        self.c:setopt(curl.OPT_URL, 'https://' .. ipport .. '/api/' .. request) ;mc :returns(true)
        self.c:setopt(curl.OPT_HTTPAUTH, curl.AUTH_BASIC) ;mc :returns(true)
        self.c:setopt(curl.OPT_USERPWD, userpass) ;mc :returns(true)
        self.c:setopt(curl.OPT_WRITEFUNCTION, mc.ANYARGS)

        self.c:setopt(curl.OPT_CUSTOMREQUEST, method) ;mc :returns(true)
        self.c:setopt(curl.OPT_HTTPHEADER, mc.ANYARGS) ;mc :returns(true)

        local res, msg = self.c:perform() ;mc :returns(0)

        if curl.close then
           self.c:close() ;mc :returns(true)
        end

        mc:replay()
        local res = self.client:request(method, request)
        mc:verify()

        assertTrue(res)
        assertIs(self.client.c, self.c)
    end

-- class TestNGCAPIClient
--EOF
