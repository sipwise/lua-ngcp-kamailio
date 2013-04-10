#!/usr/bin/env lua5.1
require 'ngcp.pp'
require 'ngcp.dp'
require 'ngcp.up'
require 'ngcp.rp'
-- load drivers
require "luasql.mysql"

-- class NGCPConfig
NGCPConfig = {
     __class__ = 'NGCPConfig'
}
NGCPConfig_MT = { __index = NGCPConfig }

    function NGCPConfig:new()
        local t = {
            db_host = "127.0.0.1",
            db_port = 3306,
            db_username = "kamailio",
            db_pass = "somepasswd",
            db_database = "kamailio"
        }
        setmetatable( t, NGCPConfig_MT )
        return t
    end

    function NGCPConfig:getDBConnection()
        local env = assert (luasql.mysql())
        sr.log("dbg","connecting to mysql")
        return assert (env:connect( self.db_database,
            self.db_username, self.db_pass, self.db_host, self.db_port))
    end
-- class

-- class NGCP
NGCP = {
     __class__ = 'NGCP'
}
NGCP_MT = { __index = NGCP }

    function NGCP:new()
        local t = NGCP.init()
        setmetatable( t, NGCP_MT )
        return t
    end

    function NGCP.init()
        local t = {
            config = NGCPConfig:new()
        }
        t.prefs = {
            dom  = NGCPDomainPrefs:new(t.config),
            usr  = NGCPUserPrefs:new(t.config),
            peer = NGCPPeerPrefs:new(t.config),
            real = NGCPRealPrefs:new(),
        }
        return t
    end

    function NGCP:caller_peer_load(peer)
        local keys = self.prefs.peer:caller_load(peer)
        self.prefs.real:caller_usr_load(keys)
        return keys
    end

    function NGCP:callee_peer_load(peer)
        local keys = self.prefs.peer:callee_load(peer)
        self.prefs.real:callee_peer_load(keys)
        return keys
    end

    function NGCP:caller_usr_load(uuid, domain)
        local keys = {
            domain = self.prefs.dom:caller_load(domain),
            user   = self.prefs.usr:caller_load(uuid)
        }
        local unique_keys = table.deepcopy(keys.domain)
        local _,v
        for _,v in pairs(keys.user) do
            table.add(unique_keys, v)
        end
        self.prefs.real:caller_usr_load(unique_keys)
        return unique_keys
    end

    function NGCP:callee_usr_load(uuid, domain)
        local keys = {
            domain = self.prefs.dom:callee_load(domain),
            user   = self.prefs.usr:callee_load(uuid)
        }
        local unique_keys = table.deepcopy(keys.domain)
        local _,v
        for _,v in pairs(keys.user) do
            table.add(unique_keys, v)
        end
        self.prefs.real:callee_usr_load(unique_keys)
        return unique_keys
    end

    function NGCP:clean(vtype, group)
        local _,v
        if not group then
            for _,v in pairs(self.prefs) do
                v:clean(vtype)
            end
        else
            if self.prefs[group] then
                self.prefs[group]:clean(vtype)
            else
                error(string.format("unknown group:%s", group))
            end
        end
    end
-- class
--EOF