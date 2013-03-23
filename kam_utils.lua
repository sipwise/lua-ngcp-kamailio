#!/usr/bin/env lua5.1
-- Kamailio Lua utils

-- kamailio log for a table
function table.log(t, msg, level)
    if not level then
        level = "debug"
    end
    if msg then
        sr.log(level, msg)
    end
    if not t then
        -- empty table
        return
    end
    for i,v in pairs(t) do
        if type(i) == "number" then
            iformat = "%d"
        elseif type(i) == "string" then
            iformat = "%s"
        end
        if type(v) == "string" then
            sr.log(level, string.format("i:" .. iformat .. " v: %s", i, v))
        elseif type(v) == "number" then
            sr.log(level, string.format("i:" .. iformat .. " v: %d", i, v))
        elseif type(v) == "table" then
            table.log(v,string.format("i:" .. iformat .. " v:", i),level)
        end
    end
end

-- cleans and sets string values from the table list
function sets_avps(list)
    local i, v

    for i,v in pairs(list) do
        -- sr.log("debug","i:" .. i .. " v:" .. v)
        sr.pv.unset('$avp(' .. i ..')[*]')
        sr.pv.sets('$avp(' .. i .. ')', v)
    end
end

-- cleans and sets int values from the table list
function seti_avps(list)
    local i, v

    for i,v in pairs(list) do
        -- sr.log("debug","i:" .. i .. " v:" .. v)
        sr.pv.unset('$avp(' .. i ..')[*]')
        sr.pv.seti('$avp(' .. i .. ')', v)
    end
end

function clean_avps(list)
    if not list then
        error("list is empty")
    end
    local i,v

    for i,v in pairs(list) do
        sr.pv.unset('$avp(' .. i .. ')[*]')
    end
end

--EOF