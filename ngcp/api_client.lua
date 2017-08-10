--
-- Copyright 2017 SipWise Team <development@sipwise.com>
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

require("curl")
local utils = require 'ngcp.utils'
local utable = utils.table
_ENV = NGCPAPIClient

-- class NGCPAPIClient
local NGCPAPIClient_MT = { __index = NGCPAPIClient }

NGCPAPIClient_MT.__tostring = function (t)
    return string.format("config:%s", utable.tostring(t.config))
end

function NGCPAPIClient.new()
    local t = NGCPAPIClient.init();
    setmetatable( t, NGCPAPIClient_MT )
    return t;
end

function NGCPAPIClient.init()
	local t = {
        config = {
            ip   = '127.0.0.1',
            port = 1442,
            user = 'system',
            pass = 'password',
        },
        c = curl.easy_init(),
        j = require("cjson")
    };
    return t;
end

function NGCPAPIClient:request(method, request)
    local result = {}
    local ipport = self.config.ip .. ':' .. self.config.port
    local userpass = self.config.user .. ':' .. self.config.pass

    local headers = {
        'Content-Type: application/json',
        'Prefer: return=internal',
        'NGCP-UserAgent: NGCP::API::Client'
    }

    self.c:setopt(curl.OPT_VERBOSE, 0)

    self.c:setopt(curl.OPT_SSL_VERIFYHOST, 0)
    self.c:setopt(curl.OPT_SSL_VERIFYPEER, 0)

    self.c:setopt(curl.OPT_URL, 'https://' .. ipport .. '/api/' .. request)
    self.c:setopt(curl.OPT_HTTPAUTH, curl.AUTH_BASIC)
    self.c:setopt(curl.OPT_USERPWD, userpass)
    self.c:setopt(curl.OPT_WRITEFUNCTION,
        function(param,buf)
            table.insert(result, param)
            return buf
        end
    )

    self.c:setopt(curl.OPT_CUSTOMREQUEST, method)
    self.c:setopt(curl.OPT_HTTPHEADER, headers)

    local res, msg =  self.c:perform()

    if curl.close then
       self.c:close()
    end

    local res_data = table.concat(result)
    if (res_data == nil or res_data == '') then
        return "{}"
    end
    return self.j.decode(table.concat(result))
end

return NGCPAPIClient
