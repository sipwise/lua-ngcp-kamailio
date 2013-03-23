#!/usr/bin/env lua5.1
require('luaunit')
require 'mocks.sr'
require 'kam_utils'

sr = srMock:new()

TestKamUtils = {} --class

    function TestKamUtils:setUp()
        self.list_ids = {
            id1 = 1,
            id2 = 2,
            id3 = 3
        }
    end

    function TestKamUtils:test_table_log()
        table.log(self.list_ids, "list ids")
        table.log(self.list_ids, "list ids", "info")
        table.log(nil, "list ids")
        table.log(self.list_ids, "list ids", nil)
        table.log(self.list_ids, nil)
    end

    function TestKamUtils:test_sets_avps()
        assertError(sets_avps, nil)
        sets_avps(self.list_ids)
    end

    function TestKamUtils:test_seti_avps()
        assertError(seti_avps, nil)
        seti_avps(self.list_ids)
    end

    function TestKamUtils:test_clean_avp()
        assertError(clean_avp, nil)
        clean_avp(self.list_ids)
        clean_avp("testid")
    end
-- class TestKamUtils

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF