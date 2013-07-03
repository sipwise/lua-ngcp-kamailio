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
require 'tests.utils'
require 'tests.mocks'
require 'tests.ngcp_avp'
require 'tests.ngcp_xavp'
require 'tests.ngcp_pref'
require 'tests.ngcp_dp'
require 'tests.ngcp_up'
require 'tests.ngcp_pp'
require 'tests.ngcp_rp'
require 'tests.ngcp'
---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()