EXPORT_ASSERT_TO_GLOBALS = true
require "tests/ngcp_recentcalls"
-- Control test output:
local lu = LuaUnit
lu:setOutputType('JUNIT')
lu:setVerbosity(1)
lu:run()
