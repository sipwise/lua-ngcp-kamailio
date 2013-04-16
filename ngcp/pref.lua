require 'ngcp.avp'
require 'ngcp.xavp'

-- class NGCPPrefs
NGCPPrefs = {
     __class__ = 'NGCPPrefs'
}
NGCPPrefs_MT = { __index = NGCPPrefs }

    function NGCPPrefs.init(group)
        local _,v, xavp
        local levels = {"caller", "callee"}
        for _,v in pairs(levels) do
            xavp = NGCPXAvp.init(v,group)
        end
    end

    function NGCPPrefs.set_avp(avp_name, xavp_name, default)
    	local xavp
    	local avp = NGCPAvp:new(avp_name)

    	if xavp_name then
    		xavp = sr.pv.get("$xavp(" .. xavp_name .. ")")
    	else
    		avp:clean()
    		return
    	end

    	if default and not xavp then
    		avp(default)
    	else
    		avp(xavp)
    	end
    end
-- class
--EOF