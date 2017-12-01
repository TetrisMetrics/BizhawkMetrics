require('class')
require('helpers')

List = class(function(a)
  a.first  = 0
  a.last   = -1
end)

function List:dump()
  return tableToString(self)
end

function tableToList(tab)
  local l = List()
  local keys = getSortedKeySet(tab)
  for _,k in pairs(keys) do
    l:pushright({[k] = tab[k]})
  end
  return l
end

-- offset must be positive
function List:peekleft (offset)
  offset = offset or 0
  return self[self.first + offset]
end

-- offset must be negative
function List:peekright (offset)
  offset = offset or 0
  return self[self.last + offset]
end

function List:pushleft (value)
  local first = self.first - 1
  self.first = first
  self[first] = value
end

function List:pushright (value)
  local last = self.last + 1
  self.last = last
  self[last] = value
end

function List:popleft ()
  local first = self.first
  if first > self.last then
    error("list is empty")
  end
  local value = self[first]
  self[first] = nil        -- to allow garbage collection
  self.first = first + 1
  return value
end

function List:popright ()
  local last = self.last
  if self.first > last then
    error("list is empty")
  end
  local value = self[last]
  self[last] = nil         -- to allow garbage collection
  self.last = last - 1
  return value
end
