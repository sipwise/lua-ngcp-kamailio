#!/usr/bin/env lua5.1
require('luaunit')
require 'ngcp.utils'
require 'ngcp.rp'
require 'tests_v.dp_vars'
require 'tests_v.up_vars'
require 'lemock'

if not sr then
    require 'mocks.sr'
    sr = srMock:new()
else
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
       sr.pv.unset("$xavp(caller_dom_prefs)")
       sr.pv.unset("$xavp(callee_dom_prefs)")
       sr.pv.unset("$xavp(caller_peer_prefs)")
       sr.pv.unset("$xavp(callee_peer_prefs)")
       sr.pv.unset("$xavp(caller_usr_prefs)")
       sr.pv.unset("$xavp(callee_usr_prefs)")
       sr.pv.unset("$xavp(caller_real_prefs)")
       sr.pv.unset("$xavp(callee_real_prefs)")
       sr.log("info", "---cleaned---")
    end

    function TestNGCPRealPrefs:test_caller_load_empty()
        assertError(self.real.caller_load, nil)
    end

    function TestNGCPRealPrefs:test_callee_load_empty()
        assertError(self.real.callee_load, nil)
    end

    function TestNGCPRealPrefs:test_caller_peer_load()
        local keys = {"uno"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("caller"),
            user    = NGCPUserPrefs:xavp("caller"),
            peer    = NGCPPeerPrefs:xavp("caller"),
            real    = NGCPRealPrefs:xavp("caller")
        }
        xavp.domain("uno",1)
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>uno)"),1)
        xavp.user("uno",2)
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>uno)"),2)
        xavp.peer("uno",3)
        local real_keys = self.real:caller_peer_load(keys)
        assertEquals(real_keys, keys)
        assertEquals(xavp.real("uno"),3)
    end

    function TestNGCPRealPrefs:test_caller_usr_load()
        local keys = {"uno"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("caller"),
            user    = NGCPUserPrefs:xavp("caller"),
            real    = NGCPRealPrefs:xavp("caller")
        }
        xavp.domain("uno",1)
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>uno)"),1)
        xavp.user("uno",2)
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>uno)"),2)
        local real_keys = self.real:caller_usr_load(keys)
        assertEquals(real_keys, keys)
        assertEquals(xavp.real("uno"),2)
    end

    function TestNGCPRealPrefs:test_caller_usr_load1()
        local keys = {"uno", "dos"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("caller"),
            user    = NGCPUserPrefs:xavp("caller"),
            real    = NGCPRealPrefs:xavp("caller")
        }
        xavp.domain("uno",1)
        assertEquals(sr.pv.get("$xavp(caller_dom_prefs=>uno)"),1)
        xavp.user("dos",2)
        assertEquals(sr.pv.get("$xavp(caller_usr_prefs=>dos)"),2)
        local real_keys = self.real:caller_usr_load(keys)
        assertEquals(real_keys, keys)
        assertEquals(xavp.real("uno"),1)
        assertEquals(xavp.real("dos"),2)
    end

    function TestNGCPRealPrefs:test_callee_usr_load()
        local keys = {"uno"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("callee"),
            user    = NGCPUserPrefs:xavp("callee"),
            real    = NGCPRealPrefs:xavp("callee")
        }
        xavp.domain("uno",1)
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>uno)"),1)
        xavp.user("uno",2)
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>uno)"),2)
        local real_keys = self.real:callee_usr_load(keys)
        assertEquals(real_keys, keys)
        assertEquals(xavp.real("uno"),2)
    end

    function TestNGCPRealPrefs:test_callee_usr_load1()
        local keys = {"uno", "dos"}
        local xavp = {
            domain  = NGCPDomainPrefs:xavp("callee"),
            user    = NGCPUserPrefs:xavp("callee"),
            real    = NGCPRealPrefs:xavp("callee")
        }
        xavp.domain("uno",1)
        assertEquals(sr.pv.get("$xavp(callee_dom_prefs=>uno)"),1)
        xavp.user("dos",2)
        assertEquals(sr.pv.get("$xavp(callee_usr_prefs=>dos)"),2)
        local real_keys = self.real:callee_usr_load(keys)
        assertEquals(real_keys, keys)
        assertEquals(xavp.real("uno"),1)
        assertEquals(xavp.real("dos"),2)
    end

    function TestNGCPRealPrefs:test_set()
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>dummy)"), "caller")
        assertFalse(sr.pv.get("$xavp(callee_real_prefs=>testid)"))
        assertFalse(sr.pv.get("$xavp(callee_real_prefs=>foo)"))

        local callee_xavp = NGCPRealPrefs:xavp("callee")
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>dummy)"),'callee')

        callee_xavp("testid", 1)
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>testid)"), 1)
        callee_xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
    end

    function TestNGCPRealPrefs:test_clean()
        local callee_xavp = NGCPRealPrefs:xavp("callee")
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>dummy)"),'callee')

        callee_xavp("testid",1)
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>testid)"),1)
        callee_xavp("foo","foo")
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        
        self.real:clean()
        
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
    end

    function TestNGCPRealPrefs:test_callee_clean()
        local callee_xavp = NGCPRealPrefs:xavp("callee")
        local caller_xavp = NGCPRealPrefs:xavp("caller")

        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
        
        self.real:clean('callee')
        
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>dummy)"),'caller')
        assertFalse(sr.pv.get("$xavp(callee_real_prefs=>testid)"))
        assertFalse(sr.pv.get("$xavp(callee_real_prefs=>foo)"))
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
    end

    function TestNGCPRealPrefs:test_caller_clean()
        local callee_xavp = NGCPRealPrefs:xavp("callee")
        local caller_xavp = NGCPRealPrefs:xavp("caller")

        callee_xavp("testid",1)
        callee_xavp("foo","foo")
        
        caller_xavp("other",1)
        caller_xavp("otherfoo","foo")
        
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>other)"),1)
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>otherfoo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
        
        self.real:clean('caller')
        
        assertEquals(sr.pv.get("$xavp(caller_real_prefs=>dummy)"),"caller")
        assertFalse(sr.pv.get("$xavp(caller_real_prefs=>other)"))
        assertFalse(sr.pv.get("$xavp(caller_real_prefs=>otherfoo)"))
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>testid)"),1)
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>foo)"),"foo")
        assertEquals(sr.pv.get("$xavp(callee_real_prefs=>dummy)"),"callee")
    end
-- class TestNGCPRealPrefs
--EOF