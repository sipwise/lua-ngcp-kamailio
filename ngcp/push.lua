--
-- Copyright 2022 SipWise Team <development@sipwise.com>
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

local NGCPPush = {
     __class__ = 'NGCPPush'
}
local NGCPRedis = require 'ngcp.redis';
local curl = require 'curl'
local utils = require 'ngcp.utils'
local utable = utils.table
local separator = "#"

local defaults = {
    url   = 'http://127.0.0.1:45059/push',
    central = {
        host = '127.0.0.1',
        port = 6379,
        db = 3
    },
}

-- class NGCPPush
local NGCPPush_MT = { __index = NGCPPush }

NGCPPush_MT.__tostring = function (t)
    return string.format("config:%s", utable.tostring(t.config))
end

function NGCPPush:new(config)
    local t = NGCPPush.init(utils.merge_defaults(config, defaults));
    setmetatable( t, NGCPPush_MT )
    return t;
end

function NGCPPush.init(config)
    return {
        config = config,
        c = curl.easy_init(),
        redis = NGCPRedis:new(config.central)
    }
end

function NGCPPush:len(key, node)
    local values = self:get(key)
    local res = 0

    if values then
        for _,v in pairs(values) do
            if v.node == node then
                res = res + 1
            end
        end
    end
    return res
end

local function value_base(v)
    return v.idx .. separator .. v.label .. separator .. v.node .. separator .. v.node_uri .. separator .. v.mode
end

function NGCPPush:add(v)
    if not self.redis:test_connection() then
        self.redis:connect()
    end
    local val_base = value_base(v)
    local val = v.callid.. separator ..val_base
    local pos = self.redis.client:lpush(v.key, val)
    KSR.dbg(string.format("lpush[%s]=>[%s] %s\n",
        v.key, val, tostring(pos)));

    val = v.key .. separator .. val_base
    pos = self.redis.client:lpush(v.callid, val)
    KSR.dbg(string.format("lpush[%s]=>[%s] %s\n",
        v.callid, val, tostring(pos)));
    if v.expire then
        self.redis.client:expire(v.key, v.expire)
        self.redis.client:expire(v.callid, v.expire)
        KSR.dbg(string.format(
            "set expire %d for keys:[%s, %s]", v.expire, v.key, v.callid));
    end
end

local function split_val(value)
    local t = utils.explode(separator, value);
    return t[1], t[2], t[3], t[4], t[5], t[6];
end

local function insert_val(res, v, key_name)
    local key, idx, label, node, node_uri, mode = split_val(v)
    local val = {idx=idx, label=label, node=node, node_uri=node_uri, mode=mode}
    val[key_name] = key
    table.insert(res, val)
end

function NGCPPush:get(key)
    if not self.redis:test_connection() then
        self.redis:connect()
    end
    local res = {}
    for _,v in pairs(self.redis.client:lrange(key, 0, -1)) do
        insert_val(res, v, "callid")
    end
    return res
end

function NGCPPush:callid_get(callid)
    if not self.redis:test_connection() then
        self.redis:connect()
    end
    local res = {}
    for _,v in pairs(self.redis.client:lrange(callid, 0, -1)) do
        insert_val(res, v, "key")
    end
    return res
end

function NGCPPush:del(v)
    if not self.redis:test_connection() then
        self.redis:connect()
    end
    local val_base = value_base(v)
    local val = v.callid.. separator ..val_base
    local res = self.redis.client:lrem(v.key, 0, val)
    KSR.dbg(string.format("lrem[%s] all [%s] %s\n",
            v.key, val, tostring(res)));
    if self.redis.client:llen(v.key) == 0 then
        self:clear(v.key)
    end

    val = v.key .. separator .. val_base
    res = self.redis.client:lrem(v.callid, 0, val)
    KSR.dbg(string.format("lrem[%s] all [%s] %s\n",
            v.callid, val, tostring(res)));
    if self.redis.client:llen(v.callid) == 0 then
        self.redis.client:del(v.callid)
    end
end

function NGCPPush:clear(key)
    if not self.redis:test_connection() then
        self.redis:connect()
    end
    local res = self.redis.client:del(key)
    KSR.dbg(string.format("del[%s] %s\n", key, tostring(res)));
end

--function helper for result
--taken from luasocket page (MIT-License)
local function build_w_cb(t)
    return function(s,len)
        table.insert(t, s)
    return len,nil
    end
end

--function helper for headers
--taken from luasocket page (MIT-License)
local function h_build_w_cb(t)
    return function(s,len)
        --stores the received data in the table t
        --prepare header data
        local name, value = s:match("(.-): (.+)")
        if name and value then
            t.headers[name] = value:gsub("[\n\r]", "")
        else
            local code, codemessage = string.match(s, "^HTTP/.* (%d+) (.+)$")
            if code and codemessage then
                t.code = tonumber(code)
                t.codemessage = codemessage:gsub("[\n\r]", "")
            end
        end
        return len,nil
    end
end

local function postfields(data)
    local str = ""
    for k, v in pairs(data) do
        str = str .. string.format("%s=%s&", k, curl.escape(v))
    end
    return str:sub(1, -1)
end

function NGCPPush:request(postdata)
    local ret = {headers={}}
    local response_body = {}
    local headers = {
        'Content-Type: application/x-www-form-urlencoded',
    }
    self.c:setopt(curl.OPT_VERBOSE, 0)

    self.c:setopt(curl.OPT_SSL_VERIFYHOST, 0)
    self.c:setopt(curl.OPT_SSL_VERIFYPEER, 0)
    self.c:setopt(curl.OPT_HTTPHEADER, headers)
    self.c:setopt(curl.OPT_URL, self.config.url)
    self.c:setopt(curl.OPT_HEADERFUNCTION, h_build_w_cb(ret))
    self.c:setopt(curl.OPT_WRITEFUNCTION, build_w_cb(response_body))
    self.c:setopt(curl.OPT_POSTFIELDS, postfields(postdata))
    self.c:perform()

    if curl.close then
       self.c:close()
    end
    ret.body = table.concat(response_body)
    return ret
end

return NGCPPush
