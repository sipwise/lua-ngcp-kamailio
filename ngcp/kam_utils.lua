#!/usr/bin/env lua5.1
-- Kamailio Lua utils
require 'ngcp.utils'

-- kamailio log for a table
function table.log(t, msg, level)
    if not level then
        level = "dbg"
    end
    if msg then
        sr.log(level, msg)
    end
    if not t then
        -- empty table
        return
    end
    sr.log(level, table.tostring(t))
end

-- cleans and sets string values from the table list
function sets_avps(list)
    if not list then
        error("list is empty")
    end

    local i, v

    for i,v in pairs(list) do
        -- sr.log("dbg","i:" .. i .. " v:" .. v)
        sr.pv.unset('$avp(' .. i ..')[*]')
        sr.pv.sets('$avp(' .. i .. ')', v)
    end
end

-- cleans and sets int values from the table list
function seti_avps(list)
    if not list then
        error("list is empty")
    end
    local i, v

    for i,v in pairs(list) do
        -- sr.log("debug","i:" .. i .. " v:" .. v)
        sr.pv.unset('$avp(' .. i ..')[*]')
        sr.pv.seti('$avp(' .. i .. ')', v)
    end
end

function clean_avp(obj)
    if not obj then
        error("obj is empty")
    end

    if type(obj) == "string" then
        sr.pv.unset('$avp(' .. obj .. ')[*]')
    elseif type(obj) == "table" then
        local i,_

        for i,_ in pairs(obj) do
            sr.pv.unset('$avp(' .. i .. ')[*]')
        end
    end
end

--EOF