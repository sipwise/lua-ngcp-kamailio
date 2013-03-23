#!/usr/bin/env lua5.1
require 'lemock'

mc = lemock.controller()

srMock = {
    __class__ = 'srMock',
    pv = mc:mock()
}
srMock_MT = { __index = srMock, __newindex = mc:mock() }
    function srMock:new()
        --print("srMock:new")
        local t = {}
        setmetatable(t, srMock_MT)
        return t
    end
--EOF