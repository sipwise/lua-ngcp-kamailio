--
-- Copyright 2013-2015 SipWise Team <development@sipwise.com>
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
local NGCPXAvp = require 'ngcp.xavp'
local NGCPPrefs = require 'ngcp.pref'

-- class NGCPContractPrefs
local NGCPContractPrefs = utils.inheritsFrom(NGCPPrefs)

NGCPContractPrefs.__class__ = 'NGCPContractPrefs'
NGCPContractPrefs.group = "contract_prefs"
NGCPContractPrefs.db_table = "contract_preferences"
NGCPContractPrefs.query = "SELECT * FROM %s WHERE uuid ='%s' AND location_id IS NULL"
NGCPContractPrefs.query_location_id = [[
SELECT location_id FROM provisioning.voip_contract_locations cl JOIN
  provisioning.voip_contract_location_blocks cb ON cb.location_id = cl.id
  WHERE cl.contract_id = %s AND
    _%s_net_from <= UNHEX(HEX(INET_ATON('%s'))) AND
    _%s_net_to >= UNHEX(HEX(INET_ATON('%s')))
  ORDER BY cb.ip DESC, cb.mask DESC LIMIT 1
]]
-- luacheck: globals KSR
function NGCPContractPrefs:new(config)
    local instance = NGCPContractPrefs:create()
    self.config = config
    -- creates xavp usr
    instance:init()
    return instance
end

function NGCPContractPrefs:caller_load(contract, ip)
    if not contract then
        return {}
    end
    return self:_load("caller", contract, ip)
end

function NGCPContractPrefs:callee_load(contract, ip)
    if not contract then
        return {}
    end
    return self:_load("callee", contract, ip)
end

function NGCPContractPrefs:_get_location_id(con, id, ip)
    local ip_type = "ipv4"
    if string.find(ip, ':') ~= nil then
        ip_type = "ipv6"
    end
    local query = self.query_location_id:format(id, ip_type, ip, ip_type, ip)
    local cur = assert(con:execute(query))

    local row = cur:fetch({}, "a")
    cur:close()

    if row then
        return row.location_id
    end
end

function NGCPContractPrefs:_load(level, contract, ip)
    local con = self.config:getDBConnection()
    local location_id = nil
    local query = self.query:format(self.db_table, contract)
    if ip then
        location_id = self:_get_location_id(con, contract, ip)
        if location_id then
            query = string.format("SELECT * FROM %s WHERE uuid ='%s' AND location_id = %d",
                self.db_table, contract, location_id)
        end
    end
    local cur = assert(con:execute(query))
    local keys = self:_set_xavp(level, cur, query)
    local xavp = self:xavp(level)
    xavp("location_id", location_id)

    return keys
end

-- class
return NGCPContractPrefs
