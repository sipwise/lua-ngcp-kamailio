--
-- Copyright 2015-2022 SipWise Team <development@sipwise.com>
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
local utils = require 'ngcp.utils'
-- load drivers
local driver = require "luasql.mysql"
-- luacheck: ignore luasql
if not luasql then
    luasql = driver
end

local defaults = {
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
            reseller_id = 0,
            ringtimeout = 180,
        }
    },
    -- blob prefs to be loaded automaticaly
    blob_prefs = {
        emergency_provider_info = true,
        emergency_location_object = true,
    }
}

-- class NGCPConfig
local NGCPConfig = {
     __class__ = 'NGCPConfig'
}
local NGCPConfig_MT = { __index = NGCPConfig }
-- luacheck: globals KSR
    function NGCPConfig:new(config)
        local t = utils.merge_defaults(config, defaults)
        setmetatable( t, NGCPConfig_MT )
        return t
    end

    function NGCPConfig:getDBConnection()
        if not self.env then
            self.env = assert (luasql.mysql())
        end
        if self.con then
            if not self.con:ping() then
                self.con = nil
                KSR.dbg("lost database connection. Reconnecting\n")
            end
        end
        if not self.con then
            KSR.dbg("connecting to mysql\n")
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
