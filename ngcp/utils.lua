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
-- Lua utils

local utils = {}
utils.table = {}
utils.string = {}
utils.math = {}
local ut = utils.table
local us = utils.string

-- improving the built-in pseudorandom generator
-- http://lua-users.org/wiki/MathLibraryTutorial
local oldrandom = math.random
local randomtable
function utils.math.random()
    if randomtable == nil then
       randomtable = {}
       for i = 1, 97 do
          randomtable[i] = oldrandom()
       end
    end
    local x = oldrandom()
    local i = 1 + math.floor(97*x)
    x, randomtable[i] = randomtable[i], x
    return x
 end
 -- luacheck: ignore math
math.random = utils.math.random

-- copy a table
function ut.deepcopy(object)
    local lookup_table = {}
    local function _copy(obj)
        if type(obj) ~= "table" then
            return obj
        elseif lookup_table[obj] then
            return lookup_table[obj]
        end
        local new_table = {}
        lookup_table[obj] = new_table
        for index, value in pairs(obj) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(obj))
    end
    return _copy(object)
end

function ut.contains(t, element)
    if t then
      for _, value in pairs(t) do
        if value == element then
          return true
        end
      end --for
    end --if
    return false
end

-- add if element is not in table
function ut.add(t, element)
  if not ut.contains(t, element) then
    table.insert(t, element)
  end
end

function ut.del(t, element)
    local i
    local pos = {}

    if t then
      i = 1
      for _, v in pairs(t) do
        if v == element then
          table.insert(pos, i)
        end
        i = i + 1
      end
      i = 0
      for _,v in ipairs(pos) do
        table.remove(t, v-i)
        i = i + 1
      end
    end
end

function ut.merge(t, other)
  if t and other then
    for _, value in ipairs(other) do
      ut.add(t, value)
    end
  end
  return t;
end

function ut.size(t)
  if t then
    local c = 0
    for _ in pairs(t) do
      c = c + 1
    end
    return c
  end
  return 0
end

function ut.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and ut.tostring( v ) or
      tostring( v )
  end
end

function ut.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. ut.val_to_str( k ) .. "]"
  end
end

function ut.tostring( tbl )
  local result, done = {}, {}
  if not tbl then return "nil" end
  for k, v in ipairs( tbl ) do
    table.insert( result, ut.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        ut.key_to_str( k ) .. "=" .. ut.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

function ut.shuffle(tab)
  local n, order, res = #tab, {}, {}
  math.randomseed( os.time() );
  for i=1,n do order[i] = { rnd = math.random(), idx = i } end
  table.sort(order, function(a,b) return a.rnd < b.rnd end)
  for i=1,n do res[i] = tab[order[i].idx] end
  return res
end

-- range(start)             returns an iterator from 1 to a (step = 1)
-- range(start, stop)       returns an iterator from a to b (step = 1)
-- range(start, stop, step) returns an iterator from a to b, counting by step.
utils.range = function (i, to, inc)
  -- range(--[[ no args ]]) -> return "nothing" to fail the loop in the caller
  if i == nil then return end

  if not to then
     to = i
     i  = to == 0 and 0 or (to > 0 and 1 or -1)
  end

  -- we don't have to do the to == 0 check
  -- 0 -> 0 with any inc would never iterate
  inc = inc or (i < to and 1 or -1)

  -- step back (once) before we start
  i = i - inc

  return function () if i == to then return nil end i = i + inc return i, i end
end

function ut.shift(t, position)
  local res = {}
  local p = position % #t

  if p == 0 then return end
  for k in utils.range(1, p) do
    table.insert(res, table.remove(t, k-#res))
  end
  for _,v in ipairs(res) do
    table.insert(t, v)
  end
end

-- from table to string
-- t = {'a','b'}
-- implode(",",t,"'")
-- "'a','b'"
-- implode("#",t)
-- "a#b"
function utils.implode(delimiter, list, quoter)
    local len = #list
    if not delimiter then
        error("delimiter is nil")
    end
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
function utils.explode(delimiter, text)
    local list = {}
    local pos = 1

    if not delimiter then
        error("delimiter is nil")
    end
    if not text then
        error("text is nil")
    end
    if string.find("", delimiter, 1) then
        -- We'll look at error handling later!
        error("delimiter matches empty string!")
    end
    while 1 do
        local first, last = string.find(text, delimiter, pos)
        -- print (first, last)
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

-- from string to table with all the values of that string from 1 to len
-- "123" -> {'1', '12', '123'}
function us.explode_lnp(s)
  local list = {}
  local t = ""

  if not s then
    error("string is null")
  end

  for i = 1, #s do
    t = t..s[i]
    table.insert(list, s)
  end
  return list
end

function us.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function us.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

-- Stack Table
-- Uses a table as stack, use <table>:push(value) and <table>:pop()
-- Lua 5.1 compatible

-- GLOBAL
local Stack = {
  __class__ = 'Stack'
}
local Stack_MT = {
  __tostring = function(t)
    return ut.tostring(Stack.list(t))
  end,
  -- this works only on Lua5.2
  __len = function(t)
    return Stack.size(t)
  end,
  __index = function(t,k)
    if type(k) == 'number' then
      return Stack.get(t,k)
    end
    return rawget(Stack,k)
  end,
  __newindex = function(t,k,v)
    if type(k) == 'number' then
      Stack.set(t,k,v)
    end
  end
}

-- Create a Table with stack functions
function Stack.new()
  local t = { _et = {} }
  setmetatable(t, Stack_MT)
  return t
end

-- push a value on to the stack
function Stack:push(...)
  if ... then
    local targs = {...}
    -- add values
    for _,v in pairs(targs) do
      table.insert(self._et, v)
    end
  end
end

-- pop a value from the stack
function Stack:pop(num)
  -- get num values from stack
  local n = num or 1

  -- return table
  local entries = {}

  -- get values into entries
  for _ = 1, n do
    -- get last entry
    if #self._et ~= 0 then
      table.insert(entries, self._et[#self._et])
      -- remove last value
      table.remove(self._et)
    else
      break
    end
  end
  -- return unpacked entries
  return unpack(entries)
end

-- get pos ( starts on 0)
function Stack:get(pos)
  assert(pos)
  assert(pos>=0)
  local indx = #self._et - pos
  if indx>0 then
    return self._et[indx]
  end
end

-- set a value in a pos (stars on 0)
function Stack:set(pos, value)
  assert(pos)
  assert(pos>=0)
  local indx = #self._et - pos
  if indx>0 then
    if self._et[indx] then
      self._et[indx] = value
    else
      error("No pos:"..pos)
    end
  end
end

-- get entries
function Stack:size()
  return #self._et
end

-- list values
function Stack:list()
  local entries = {}
  for i = #self._et, 1, -1 do
    table.insert(entries, self._et[i])
  end
  return entries
end
-- end class
--EOF

utils.Stack = Stack
return utils
