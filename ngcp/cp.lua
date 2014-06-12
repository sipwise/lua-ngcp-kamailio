--
-- Copyright 2013 SipWise Team <development@sipwise.com>
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
require 'ngcp.utils'
require 'ngcp.pref'

-- class NGCPContractPrefs
NGCPContractPrefs = {
     __class__ = 'NGCPContractPrefs'
}
NGCPContractPrefs_MT = { __index = NGCPContractPrefs }

NGCPContractPrefs_MT.__tostring = function ()
        local output = ''
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

    function NGCPContractPrefs:caller_load(contract)
        if not contract then
            return {}
        end
        return NGCPContractPrefs._load(self,"caller",contract)
    end

    function NGCPContractPrefs:callee_load(contract)
        if not contract then
            return {}
        end
        return NGCPContractPrefs._load(self,"callee",contract)
    end

    function NGCPContractPrefs:_defaults(level)
        local defaults = self.config:get_defaults('contract')
        local keys = {}
        local k,_

        if defaults then
            for k,_ in pairs(defaults) do
                table.insert(keys, k)
            end
        end
        return keys, defaults
    end

    function NGCPContractPrefs:_load(level, contract)
        local con = self.config:getDBConnection()
        local query = "SELECT * FROM " .. self.db_table .. " WHERE uuid ='" .. contract .."'"
        local cur = con:execute(query)
        local defaults
        local keys
        local result = {}
        local row = cur:fetch({}, "a")
        local k,v
        local xavp

        keys, defaults = self:_defaults(level)

        if row then
            while row do
                --sr.log("info", string.format("result:%s row:%s", table.tostring(result), table.tostring(row)))
                table.insert(result, row)
                table.add(keys, row.attribute)
                defaults[row.attribute] = nil
                row = cur:fetch({}, "a")
            end
        else
            sr.log("dbg", string.format("no results for query:%s", query))
        end
        cur:close()
        con:close()

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
--EOF
