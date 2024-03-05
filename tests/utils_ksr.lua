--
-- Copyright 2024 SipWise Team <development@sipwise.com>
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
local lu = require('luaunit')
local utils = require 'ngcp.utils'

-- luacheck: ignore TestUtilsKSR
TestUtilsKSR = {}

function TestUtilsKSR:setUp()
  if os.getenv('RESULTS') then
    self.file = os.getenv('RESULTS').."/test_utils_ksr"
  end
end

function TestUtilsKSR:test_simple()
    local KSR_log = {}
    local KSR = { log =  KSR_log }
    KSR = utils.KSR_log(KSR, self.file)
    lu.assertNotIs(KSR.log, KSR_log)
    lu.assertIs(KSR._log, KSR_log)
end

function TestUtilsKSR:test_twice()
  local KSR = {}
  lu.assertNil(KSR.log)
  KSR = utils.KSR_log(KSR, self.file)
  local KSR_log = KSR.log
  local KSR_logger = KSR._logger
  lu.assertNotNil(KSR.log)
  KSR = utils.KSR_log(KSR, self.file)
  lu.assertIs(KSR.log, KSR_log)
  lu.assertNotIs(KSR._logger, KSR_logger)
end
