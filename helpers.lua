---
--- Created by Joshua.
--- DateTime: 10/25/2017 8:00 PM
---

-- shallow diffs function
function getTableDiffs(o1, o2)
  local keySet = {}

  for key1, value1 in pairs(o1) do
    local value2 = o2[key1]
    if value2 == nil or value1 ~= value2 then
      keySet[key1] = {value1, value2}
    end
  end

  for key2, value2 in pairs(o2) do
    local value1 = o1[key2]
    if value1 == nil  then
      keySet[key2] = {nil, value2}
    end
  end

  return keySet
end

function deepEquals(o1, o2, ignore_mt)
  if o1 == o2 then return true end
  local o1Type = type(o1)
  local o2Type = type(o2)
  if o1Type ~= o2Type then return false end
  if o1Type ~= 'table' then return false end

  if not ignore_mt then
    local mt1 = getmetatable(o1)
    if mt1 and mt1.__eq then
      --compare using built in method
      return o1 == o2
    end
  end

  local keySet = {}

  for key1, value1 in pairs(o1) do
    local value2 = o2[key1]
    if value2 == nil or deepEquals(value1, value2, ignore_mt) == false then
      return false
    end
    keySet[key1] = true
  end

  for key2, _ in pairs(o2) do
    if not keySet[key2] then return false end
  end
  return true
end

function tableToString(o, sort)
  sort = sort or false
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. tableToString(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

function getKeys(tab)
  local keyset={}
  local n=0
  for k,_ in pairs(tab) do n=n+1; keyset[n]=k end
  return keyset
end

function getSortedKeys(tab)
  local t = getKeys(tab)
  table.sort(t)
  return t
end

function getValues(tab)
  local valueset={}
  local n=0
  for _,v in pairs(tab) do n=n+1; valueset[n]=v end
  return valueset
end

function getSortedValues(tab)
  local t = getValues(tab)
  table.sort(t)
  return t
end

function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function isOdd(n)  return n % 2 == 1 end
function isEven(n) return n % 2 == 0 end

-- Lua implementation of PHP scandir function
function scandir(directory)
  local i, t, popen = 0, {}, io.popen
  local pfile = popen('dir /b "'..directory..'"')
  for filename in pfile:lines() do
    i = i + 1
    t[i] = filename
  end
  pfile:close()
  return t
end