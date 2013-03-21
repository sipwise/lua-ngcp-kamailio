#!/usr/bin/env lua5.1
# Kamailio Lua utils

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
    local i,v

    for i,v in pairs(list) do
        sr.pv.unset('$avp(' .. i .. ')[*]')
    end
end

#EOF