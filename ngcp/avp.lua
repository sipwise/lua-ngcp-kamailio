--
-- Copyright 2013-2016 SipWise Team <development@sipwise.com>
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

-- class NGCPAvp
local NGCPAvp = {
     __class__ = 'NGCPAvp'
}
local NGCPAvp_MT = {
    __index = NGCPAvp,
}

    function NGCPAvp:new(id)
        local t = { id = "$avp(s:" .. id .. ")" }
        NGCPAvp_MT.__call = function(s, value)
            if not value then
                return sr.pv.get(s.id)
            elseif type(value) == "table" then
                for i = #value, 1, -1 do
                    s(value[i])
                end
            elseif type(value) == "number" then
                sr.pv.seti(s.id, value)
            elseif type(value) == "string" then
                sr.pv.sets(s.id, value)
            else
                error("value is not a number or string")
            end
        end
        function t.all()
            return sr.pv.get("$(avp(" .. id .. ")[*])")
        end
        NGCPAvp_MT.__tostring = function(s)
            local value = sr.pv.get(s.id)
            return string.format("%s:%s", s.id, tostring(value))
        end
        return setmetatable( t, NGCPAvp_MT )
    end

    function NGCPAvp:log(level)
        if not level then
            level = "dbg"
        end
        sr.log(level, tostring(self))
    end

    function NGCPAvp:clean()
        sr.pv.unset(self.id)
    end
-- class
return NGCPAvp
