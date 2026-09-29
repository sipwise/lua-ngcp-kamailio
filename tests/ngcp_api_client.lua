--
-- Copyright 2014-2026 SipWise Team <development@sipwise.com>
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

local lu = require('luaunit')
local ltn12 = require('ltn12')
local mime = require('mime')
local ksrMock = require 'mocks.ksr'

KSR = ksrMock:new()

-- luacheck: ignore TestNGCPAPIClient
TestNGCPAPIClient = {} --class

    function TestNGCPAPIClient:setUp()
        local NGCPAPIClient = require 'ngcp.api_client'

        self.client = NGCPAPIClient:new()
        lu.assertNotNil(self.client)

        local this = self
        self.response = '{"uuid":"1234"}'
        self.requests = {}
        -- stands in for ssl.https
        self.client.c = {
            request = function(reqt)
                table.insert(this.requests, reqt)
                ltn12.pump.all(ltn12.source.string(this.response), reqt.sink)
                return 1, 200, {}, 'HTTP/1.1 200 OK'
            end
        }
    end

    function TestNGCPAPIClient:test_api_request()
        local res = self.client:request('GET', 'domains')

        lu.assertEquals(#self.requests, 1)
        local reqt = self.requests[1]
        lu.assertEquals(reqt.url, 'https://127.0.0.1:1442/api/domains')
        lu.assertEquals(reqt.method, 'GET')
        lu.assertEquals(reqt.verify, 'none')
        lu.assertEquals(reqt.redirect, false)
        lu.assertEquals(reqt.headers, {
            ['content-type'] = 'application/json',
            ['prefer'] = 'return=internal',
            ['ngcp-useragent'] = 'NGCP::API::Client',
            ['authorization'] = 'Basic ' .. (mime.b64('system:password')),
        })
        lu.assertEquals(res, {uuid = '1234'})
    end

    function TestNGCPAPIClient:test_api_request_no_content()
        self.response = ''

        local res = self.client:request('DELETE', 'managersecretary/1234')

        lu.assertEquals(self.requests[1].method, 'DELETE')
        lu.assertEquals(self.requests[1].url,
            'https://127.0.0.1:1442/api/managersecretary/1234')
        lu.assertEquals(res, "{}")
    end

    function TestNGCPAPIClient:test_api_request_credentials()
        self.client = require('ngcp.api_client'):new({
            ip = '192.168.1.1', port = 443, user = 'me', pass = 'pa%73s'
        })
        local this = self
        self.client.c = {
            request = function(reqt)
                table.insert(this.requests, reqt)
                return 1, 200, {}, 'HTTP/1.1 200 OK'
            end
        }

        self.client:request('PUT', 'managersecretary/1234')

        local reqt = self.requests[1]
        lu.assertEquals(reqt.url, 'https://192.168.1.1:443/api/managersecretary/1234')
        -- the percent sign has to survive untouched
        lu.assertEquals(reqt.headers['authorization'],
            'Basic ' .. (mime.b64('me:pa%73s')))
    end

-- class TestNGCAPIClient
--EOF
