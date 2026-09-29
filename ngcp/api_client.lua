--
-- Copyright 2017-2022 SipWise Team <development@sipwise.com>
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

local NGCPAPIClient = {
     __class__ = 'NGCPAPIClient'
}

local https = require 'ssl.https'
local ltn12 = require 'ltn12'
local mime = require 'mime'
local utils = require 'ngcp.utils'
local utable = utils.table
_ENV = NGCPAPIClient

local defaults = {
    ip   = '127.0.0.1',
    port = 1442,
    user = 'system',
    pass = 'password',
}

-- class NGCPAPIClient
local NGCPAPIClient_MT = { __index = NGCPAPIClient }

NGCPAPIClient_MT.__tostring = function (t)
    return string.format("config:%s", utable.tostring(t.config))
end

function NGCPAPIClient:new(config)
    local t = NGCPAPIClient.init(utils.merge_defaults(config, defaults))
    setmetatable( t, NGCPAPIClient_MT )
    return t
end

function NGCPAPIClient.init(config)
	return {
        config = config,
        c = https,
        j = require 'cjson'
    }
end

function NGCPAPIClient:request(method, request)
    local result = {}
    local ipport = self.config.ip .. ':' .. self.config.port
    local userpass = self.config.user .. ':' .. self.config.pass

    local headers = {
        ['content-type'] = 'application/json',
        ['prefer'] = 'return=internal',
        ['ngcp-useragent'] = 'NGCP::API::Client',
        -- built here on purpose: socket.http unescapes the password it is
        -- given, which mangles credentials containing a percent sign
        ['authorization'] = 'Basic ' .. (mime.b64(userpass)),
    }

    self.c.request({
        url = 'https://' .. ipport .. '/api/' .. request,
        method = method,
        headers = headers,
        sink = ltn12.sink.table(result),
        -- the API is reached over an internal interface with a self signed
        -- certificate, as with the former CURLOPT_SSL_VERIFY*
        verify = 'none',
        redirect = false,
    })

    local res_data = table.concat(result)
    if (res_data == nil or res_data == '') then
        return "{}"
    end
    return self.j.decode(res_data)
end

return NGCPAPIClient
