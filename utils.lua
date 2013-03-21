#!/usr/bin/env lua5.1
# Lua utils

-- kamailio log for a table
function log_table(table, msg, level)
    if not level then
        level = "debug"
    end
    if msg then
        sr.log(level, msg)
    end
    if not table then
        -- empty table
        return
    end
    for i,v in pairs(table) do
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
            log_table(v,string.format("i:" .. iformat .. " v:", i),level)
        end
    end
end

-- copy a table
function table_deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

-- from table to string
-- t = {'a','b'}
-- implode(",",t,"'")
-- "'a','b'"
-- implode("#",t)
-- "a#b"
function implode(delimiter, list, quoter)
    local len = #list
    if len == 0 then
            return nil
        end
        if not quoter then
            quoter = ""
        end
        local string = quoter .. list[1] .. quoter
        for i = 2, len do
            string = string .. delimiter .. quoter .. list[i] .. quoter
        end
        return string
end

-- from string to table
function explode(delimiter, text)
  local list = {}; local pos = 1
  if string.find("", delimiter, 1) then
    -- We'll look at error handling later!
    error("delimiter matches empty string!")
  end
  while 1 do
    local first, last = string.find(text, delimiter, pos)
    print (first, last)
    if first then
      table.insert(list, string.sub(text, pos, first-1))
      pos = last+1
    else
      table.insert(list, string.sub(text, pos))
      break
    end
  end
  return list
end

function compare_desc_len(a,b)
    return string.len(a) > string.len(b)
end

function findpattern(text, pattern, start)
    return string.sub(text, string.find(text, pattern, start))
end

#EOF