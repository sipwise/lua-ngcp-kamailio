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

-- load drivers
local driver = require "luasql.mysql"
-- luacheck: ignore luasql
if not luasql then
    luasql = driver
end
-- class NGCPConfig
local NGCPConfig = {
     __class__ = 'NGCPConfig'
}
local NGCPConfig_MT = { __index = NGCPConfig }

    function NGCPConfig:new()
        local t = {
            db_host = "127.0.0.1",
            db_port = 3306,
            db_username = "kamailio",
            db_pass = "somepasswd",
            db_database = "kamailio",
            default = {
                contract = {
                },
                fax = {
                },
                peer = {
                    sst_enable = "yes",
                    sst_expires = 300,
                    sst_min_timer = 90,
                    sst_max_timer = 7200,
                    sst_refresh_method = "UPDATE_FALLBACK_INVITE",
                    outbound_from_user = "npn",
                    inbound_upn = "from_user",
                    inbound_npn = "from_user",
                    inbound_uprn = "from_user",
                    ip_header = "P-NGCP-Src-Ip",
                },
                dom = {
                    sst_enable = "yes",
                    sst_expires = 300,
                    sst_min_timer = 90,
                    sst_max_timer = 7200,
                    sst_refresh_method = "UPDATE_FALLBACK_INVITE",
                    outbound_from_user = "npn",
                    inbound_upn = "from_user",
                    inbound_uprn = "from_user",
                    ip_header = "P-NGCP-Src-Ip",
                },
                -- just for prefs that are only on usr level
                usr = {
                    account_id = 0,
                    ext_subscriber_id = "",
                    ext_contract_id = "",
                    ringtimeout = 180,
                }
            }
        }
        setmetatable( t, NGCPConfig_MT )
        return t
    end

    local function check_connection(c)
        local cur = c:execute("SELECT 1")
        local result = false
        cur:fetch()
        if cur:numrows() == 1 then
            result = true
        end
        cur:close()
        return result
    end

    function NGCPConfig:getDBConnection()
        if not self.env then
            self.env = assert (luasql.mysql())
        end
        if self.con then
            local ok,_ = pcall(check_connection, self.con)
            if not ok then
                self.con = nil
                KSR.log("dbg", "lost database connection. Reconnecting")
            end
        end
        if not self.con then
            KSR.log("dbg","connecting to mysql")
            self.con = self.env:connect( self.db_database,
                self.db_username, self.db_pass, self.db_host, self.db_port)
        end
        return self.con
    end

    function NGCPConfig:get_defaults(vtype)
        local defs = {}

        if self.default[vtype] then
            for k,v in pairs(self.default[vtype]) do
                defs[k] = v
            end
        end
        return defs
    end
-- class
return NGCPConfig
