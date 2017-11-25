require 'Class'
require 'helpers'

EMPTY_SQUARE = 239

Board = class(function(a, rawBoard)
  a.rawBoard = rawBoard
  a.rows = {}
  for r=0,19 do
    a.rows[r]=Row(r,rawBoard[r])
  end
end)

function Board:dump()
  for i = 0, 19 do print(self.rows[i]:dump()) end
  print("Tetris ready: ", self:isTetrisReady())
end

function Board:isTetrisReady ()
  for r=19,3,-1 do
    local col = self.rows[r]:well()
    if col ~= nil then
      local blockHasTetrisReadyWell =
      self.rows[r-1]:well() == col and self.rows[r-2]:well() == col and self.rows[r-3]:well() == col
      local wellIsClosedBelow = r == 19 or self.rows[r+1]:isFilledAt(col)
      local wellIsOpenAbove = self:isColumnEmptyUntil(col, r - 4)

      if blockHasTetrisReadyWell and wellIsClosedBelow and wellIsOpenAbove then
        -- only here have we found that we are tetris ready :)
        return true
      end
    end
  end
  return false
end

--[[
   we want to get sets of relative height diffs across rows
   possibilities we are looking for are:
   0: fits O, L, J
   1, -1: fits Z, S, T
   -2: fits L
   2: fits J
   {0, 0}: fits T, L, J
   {0, 0, 0}: fits I (but basically every board fits an I)
]]
function Board:accomodationScore ()
  -- local t = {[0] = false, [1] = false, [-1] = false, [{0,0}] = false}
  local a = {["I"] = true}
  local rs = self.relativeHeights()
  for i = 0, 8 do
    if rs[i] ==  0 then a["0"] = true; a["J"] = true; a["L"] = true end
    if rs[i] ==  1 then a["Z"] = true; a["S"] = true; a["T"] = true end
    if rs[i] == -1 then a["Z"] = true; a["S"] = true; a["T"] = true end
    if rs[i] ==  2 then a["J"] = true end
    if rs[i] == -2 then a["L"] = true end
  end
  return tableLength(rs)
end

function Board:relativeHeights()
  local hs = self.heights()
  local rs = {}
  for i = 0, 8 do
    rs[i] = hs[i + 1] - hs[i]
  end
  return rs
end

-- TODO: would be nice if we could memoize this.
function Board:heights ()
  local hs = {}
  for c=0,9 do hs[c] = heightAtCol(c) end
  return hs
end

-- TODO: would be nice if we could memoize this.
function Board:heightAtCol(col)
  for r=19,0,-1 do
    if self.rawBoard[i][col] ~= EMPTY_SQUARE then return r end
  end
  return 0
end

--- TODO: do we need to adjust to depth - 1?
function Board:isColumnEmptyUntil (col, depth)
  for i=0,depth do
    if self.rows[i].row[col] ~= EMPTY_SQUARE then return false end
  end
  return true
end

Row = class(function(a, index, raw)
  a.index = index
  a.row = raw
end)

function Row:well ()
  local fullCount = 0
  local emptyIndex
  for k,v in pairs(self.row) do
    if v ~= EMPTY_SQUARE then fullCount = fullCount + 1
    else emptyIndex = k end
  end
  if fullCount == 9 then return emptyIndex else return nil end
end

function Row:isTetrisReady () return self.well ~= nil end
function Row:isTetrisReadyAt (col) return self.well == col end
function Row:isEmptyAt (col)  return self.row[col] == EMPTY_SQUARE end
function Row:isFilledAt (col) return self.row[col] ~= EMPTY_SQUARE end

function Row:toString()
  local s = ""
  for i = 0, 9 do if self.row[i] == EMPTY_SQUARE then s = s .. "_" else s = s .. "X" end end
  return s
end

function Row:dump()
  function printInt(i) if(i<10) then return " " .. i else return i end end
  function printWell()
    local w = self:well()
    if w == nil then return "NA" else return printInt(w) end
  end

  local metaString = "{" .. printInt(self.index + 1) .. ", " .. printWell() .. "}"
  return self:toString() .. " " .. metaString
end
