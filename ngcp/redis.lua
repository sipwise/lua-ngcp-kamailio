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
-- luacheck: globals KSR
local utils = require 'ngcp.utils'
local redis = require 'redis';
local utable = utils.table
local NGCPRedis = utils.inheritsFrom()

_ENV = NGCPRedis

local defaults = {
  host = 'localhost',
  port = 6379,
  db = 0
}

-- class NGCPRedis
NGCPRedis.__tostring = function (t)
    return string.format("config:%s", utable.tostring(t.config))
end

function NGCPRedis:new(config)
  local t = NGCPRedis:create()
  t.config = utils.merge_defaults(config, defaults)
  return t;
end

function NGCPRedis:test_connection()
  if not self.client then return nil end
  local ok, _ = pcall(self.client.ping, self.client)
  if not ok then
    KSR.info(string.format("close redis server[%d]\n",
      self.client.network.socket:getfd()))
    self.client.network.socket:close()
    self.client = nil
  end
  return ok
end

function NGCPRedis:connect()
  self.client = redis.connect(self.config.host, self.config.port)
  self.client:select(self.config.db)
  KSR.info(string.format("connected to redis server[%d] %s:%s at %s\n",
      self.client.network.socket:getfd(),
      self.config.host, tostring(self.config.port), tostring(self.config.db)))
  return self.client
end

return NGCPRedis
