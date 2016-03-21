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
local utable = utils.table
local NGCPXAvp = require 'ngcp.xavp'
local NGCPPrefs = require 'ngcp.pref'

-- class NGCPContractPrefs
local NGCPContractPrefs = {
     __class__ = 'NGCPContractPrefs'
}
local NGCPContractPrefs_MT = { __index = NGCPContractPrefs }

NGCPContractPrefs_MT.__tostring = function ()
        local output
        local xavp = NGCPXAvp:new('caller','contract_prefs')
        output = string.format("caller_contract_prefs:%s\n", tostring(xavp))
        xavp = NGCPXAvp:new('callee','contract_prefs')
        output = output .. string.format("callee_contract_prefs:%s\n", tostring(xavp))
        return output
    end

    function NGCPContractPrefs:new(config)
        local t = {
            config = config,
            db_table = "contract_preferences"
        }
        -- creates xavp contract
        NGCPPrefs.init("contract_prefs")
        return setmetatable( t, NGCPContractPrefs_MT )
    end

    function NGCPContractPrefs:caller_load(contract,ip)
        if not contract then
            return {}
        end
        return NGCPContractPrefs._load(self,"caller",contract,ip)
    end

    function NGCPContractPrefs:callee_load(contract,ip)
        if not contract then
            return {}
        end
        return NGCPContractPrefs._load(self,"callee",contract,ip)
    end

    function NGCPContractPrefs:_defaults(_)
        local defaults = self.config:get_defaults('contract')
        local keys = {}

        if defaults then
            for k,_ in pairs(defaults) do
                table.insert(keys, k)
            end
        end
        return keys, defaults
    end

    function NGCPContractPrefs:_get_location_id(contract, ip)
        if not ip then
            return nil;
        end

        local con = self.config:getDBConnection()
        local query = string.format("SELECT location_id FROM provisioning.voip_contract_locations cl JOIN provisioning.voip_contract_location_blocks cb ON cb.location_id = cl.id WHERE cl.contract_id = %d AND _ipv4_net_from >= UNHEX(HEX(INET_ATON('%s'))) AND UNHEX(HEX(INET_ATON('%s'))) <= _ipv4_net_to LIMIT 1", contract, ip, ip)
        if string.find(ip, ':') ~= nil then
            query = string.format("SELECT location_id FROM provisioning.voip_contract_locations cl JOIN provisioning.voip_contract_location_blocks cb ON cb.location_id = cl.id WHERE cl.contract_id = %d AND _ipv6_net_from >= UNHEX(HEX(INET_ATON('%s'))) AND UNHEX(HEX(INET_ATON('%s'))) <= _ipv6_net_to LIMIT 1", contract, ip, ip)
        end

        local cur,err = con:execute(query)

        if err then
            return nil
        end

        local row = cur:fetch({}, "a")

        cur:close()

        if row then
            return row.location_id
        end

        return nil;
    end

    function NGCPContractPrefs:_load(level, contract, ip)
        local con = self.config:getDBConnection()
        local query = string.format("SELECT * FROM %s WHERE uuid ='%s' AND location_id IS NULL", self.db_table, contract)
        if ip then
            local location_id = self:_get_location_id(contract, ip)
            if location_id then
                query = string.format("SELECT * FROM %s WHERE uuid ='%s' AND location_id = %d", self.db_table, contract, location_id)
            end
        end
        local cur = con:execute(query)
        local defaults
        local keys
        local result = {}
        local row = cur:fetch({}, "a")
        local xavp

        keys, defaults = self:_defaults(level)

        if row then
            while row do
                table.insert(result, row)
                utable.add(keys, row.attribute)
                defaults[row.attribute] = nil
                row = cur:fetch({}, "a")
            end
        else
            sr.log("dbg", string.format("no results for query:%s", query))
        end
        cur:close()

        xavp = self:xavp(level, result)
        for k,v in pairs(defaults) do
            xavp(k, v)
        end

        return keys
    end

    function NGCPContractPrefs:xavp(level, l)
        if level ~= 'caller' and level ~= 'callee' then
            error(string.format("unknown level:%s. It has to be [caller|callee]", tostring(level)))
        end
        return NGCPXAvp:new(level,'contract_prefs', l)
    end

    function NGCPContractPrefs:clean(vtype)
        if not vtype then
            NGCPContractPrefs:xavp('callee'):clean()
            NGCPContractPrefs:xavp('caller'):clean()
        else
            NGCPContractPrefs:xavp(vtype):clean()
        end
    end
-- class
return NGCPContractPrefs
