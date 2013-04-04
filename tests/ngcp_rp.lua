#!/usr/bin/env lua5.1
require('luaunit')
require 'ngcp.utils'
require 'ngcp.rp'
require 'tests_v.dp_vars'
require 'tests_v.up_vars'

if not sr then
    require 'mocks.sr'
    sr = srMock:new()
else
    require 'lemock'
    argv = {}
end
local mc = nil

PFetch = {
    __class__ = 'PFetch',
    _i = { domain=1, user=1 },
    _var = { domain=dp_vars, user=up_vars}
}
    function PFetch:new()
        local t = {}
        return setmetatable(t, { __index = PFetch })
    end

    function PFetch:val(group, uuid)
        if not self._i[group] then
            error(string.format("group:%s unknown", group))
        end
        self._i[group] = self._i[group] + 1
        local temp = self._var[group][uuid][self._i[group]-1]
        if not temp then
            print("var nil")
        end
    end

    function PFetch:reset(group)
        self._i[group] = 1
    end

TestNGCPRealPrefs = {} --class

    function TestNGCPRealPrefs:setUp()
        self.real = NGCPRealPrefs:new()
    end

    function TestNGCPRealPrefs:tearDown()
        sr.pv.vars = {}
    end

    function TestNGCPRealPrefs:test_caller_load()
        local keys = {"uno"}
        local xavp = {
            domain  = NGCPXAvp:new("caller", "domain", {}),
            user    = NGCPXAvp:new("caller", "user", {}),
            real    = NGCPXAvp:new("caller", "real", {})
        }
        xavp.domain("uno",1)
        assertEquals(sr.pv.get("$xavp(domain[0]=>uno)"),1)
        xavp.user("uno",2)
        assertEquals(sr.pv.get("$xavp(user[0]=>uno)"),2)
        local real_keys = self.real:caller_load(keys)
        assertEquals(real_keys, keys)
        assertEquals(xavp.real("uno"),2)
    end

    function TestNGCPRealPrefs:test_caller_load1()
        local keys = {"uno", "dos"}
        local xavp = {
            domain  = NGCPXAvp:new("caller", "domain", {}),
            user    = NGCPXAvp:new("caller", "user", {}),
            real    = NGCPXAvp:new("caller", "real", {})
        }
        xavp.domain("uno",1)
        assertEquals(sr.pv.get("$xavp(domain[0]=>uno)"),1)
        xavp.user("dos",2)
        assertEquals(sr.pv.get("$xavp(user[0]=>dos)"),2)
        local real_keys = self.real:caller_load(keys)
        assertEquals(real_keys, keys)
        assertEquals(xavp.real("uno"),1)
        assertEquals(xavp.real("dos"),2)
    end

    function TestNGCPRealPrefs:test_callee_load()
        local keys = {"uno"}
        local xavp = {
            domain  = NGCPXAvp:new("callee", "domain", {}),
            user    = NGCPXAvp:new("callee", "user", {}),
            real    = NGCPXAvp:new("callee", "real", {})
        }
        xavp.domain("uno",1)
        assertEquals(sr.pv.get("$xavp(domain[1]=>uno)"),1)
        xavp.user("uno",2)
        assertEquals(sr.pv.get("$xavp(user[1]=>uno)"),2)
        local real_keys = self.real:callee_load(keys)
        assertEquals(real_keys, keys)
        assertEquals(xavp.real("uno"),2)
    end

    function TestNGCPRealPrefs:test_callee_load1()
        local keys = {"uno", "dos"}
        local xavp = {
            domain  = NGCPXAvp:new("callee", "domain", {}),
            user    = NGCPXAvp:new("callee", "user", {}),
            real    = NGCPXAvp:new("callee", "real", {})
        }
        xavp.domain("uno",1)
        assertEquals(sr.pv.get("$xavp(domain[1]=>uno)"),1)
        xavp.user("dos",2)
        assertEquals(sr.pv.get("$xavp(user[1]=>dos)"),2)
        local real_keys = self.real:callee_load(keys)
        assertEquals(real_keys, keys)
        assertEquals(xavp.real("uno"),1)
        assertEquals(xavp.real("dos"),2)
    end

    function TestNGCPRealPrefs:test_clean()
        local xavp = NGCPXAvp:new('callee','real',{})
        xavp("testid",1)
        xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(real[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(real[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(real[0]=>dummy)"),"caller")
        self.real:clean()
        assertFalse(sr.pv.get("$xavp(real[0]=>dummy)"))
        assertFalse(sr.pv.get("$xavp(real[1]=>dummy)"))
        assertFalse(sr.pv.get("$xavp(real)"))
    end

    function TestNGCPRealPrefs:test_callee_clean()
        local callee_xavp = NGCPXAvp:new('callee','real',{})
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPXAvp:new('caller','real',{})
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(real[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(real[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(real[0]=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(real[0]=>other)"),1)
        assertEquals(sr.pv.get("$xavp(real[0]=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(real[1]=>dummy)"),"callee")
        self.real:clean('callee')
        assertEquals(sr.pv.get("$xavp(real[0]=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(real[1]=>testid)"))
        assertFalse(sr.pv.get("$xavp(real[1]=>foo)"))
        assertEquals(sr.pv.get("$xavp(real[0]=>other)"),1)
        assertEquals(sr.pv.get("$xavp(real[0]=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(real[1]=>dummy)"),"callee")
    end

    function TestNGCPRealPrefs:test_caller_clean()
        local callee_xavp = NGCPXAvp:new('callee','real',{})
        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        local caller_xavp = NGCPXAvp:new('caller','real',{})
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        assertEquals(sr.pv.get("$xavp(real[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(real[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(real[0]=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(real[0]=>other)"),1)
        assertEquals(sr.pv.get("$xavp(real[0]=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(real[1]=>dummy)"),"callee")
        self.real:clean('caller')
        assertEquals(sr.pv.get("$xavp(real[0]=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(real[0]=>other)"))
        assertFalse(sr.pv.get("$xavp(real[0]=>otherfoo)"))
        assertEquals(sr.pv.get("$xavp(real[1]=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(real[1]=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(real[1]=>dummy)"),"callee")
    end
-- class TestNGCPRealPrefs

---- Control test output:
lu = LuaUnit
lu:setOutputType( "TAP" )
lu:setVerbosity( 1 )
lu:run()
--EOF