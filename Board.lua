require 'Class'
require 'helpers'

EMPTY_SQUARE = 239

Board = class(function(a, rawBoard)
  a.rawBoard = rawBoard
  a.rows = {}
  for r=0,19 do a.rows[r]=Row(r,rawBoard[r]) end
end)

function Board:dump()
  for i = 0, 19 do print(self.rows[i]:dump()) end
  local r = self:tetrisReadyRow()
  print("Tetris ready row: ", r + 1)
  if r ~= -1 then print("surplus: ", self:surplus()) end
end

function Board:getSurplus(tetrisReadyRow)
  local r = tetrisReadRow
  if r == nil then r = self:tetrisReadyRow() end
  if r == -1 then return -1 else return self:blocksAboveRow(r-4) end
  return r
end

function Board:blocksAboveRow(r)
  local nr = 0
  for i=r,0,-1 do
    nr = nr + (self.rows[i]:nrColsFilled())
  end
  return nr
end

function Board:tetrisReadyRow ()
  for r=19,3,-1 do
    local col = self.rows[r]:well()
    if col ~= nil then
      local blockHasTetrisReadyWell =
      self.rows[r-1]:well() == col and self.rows[r-2]:well() == col and self.rows[r-3]:well() == col
      local wellIsClosedBelow = r == 19 or self.rows[r+1]:isFilledAt(col)
      local wellIsOpenAbove = self:isColumnEmptyUntil(col, r - 4)

      if blockHasTetrisReadyWell and wellIsClosedBelow and wellIsOpenAbove then
        -- only here have we found that we are tetris ready :)
        return r
      end
    end
  end
  return -1
end

function Board:maxHeight ()
  local max = 0;
  local hs = self:heights();
  for c=0,9 do
    if hs[c] > max then max = hs[c] end
  end
  return max;
end

function Board:minHeight ()
  local min = 20;
  local hs = self:heights();
  for c=0,9 do
    if hs[c] < min then min = hs[c] end
  end
  return min;
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
function Board:accommodationScore ()
  -- local t = {[0] = false, [1] = false, [-1] = false, [{0,0}] = false}
  local a = {["I"] = true}
  local rs = self:relativeHeights()
  for i = 0, 8 do
    -- width 2 tests
    if rs[i] ==  0 then a["0"] = true; a["J"] = true; a["L"] = true end
    if rs[i] ==  1 then a["Z"] = true; a["T"] = true end
    if rs[i] == -1 then a["S"] = true; a["T"] = true end
    if rs[i] ==  2 then a["J"] = true end
    if rs[i] == -2 then a["L"] = true end
    -- width 3 tests
    if i < 8 and rs[i] == -1 and rs[i+1] == 0 then a["Z"] = true end
    if i < 8 and rs[i] ==  0 and rs[i+1] == 1 then a["S"] = true end
    if i < 8 and rs[i] ==  0 and rs[i+1] == 0 then a["T"] = true end
  end
  return tableLength(a)
end

function Board:relativeHeights()
  local hs = self:heights()
  local rs = {}
  for i = 0, 8 do
    rs[i] = hs[i + 1] - hs[i]
  end
  return rs
end

-- TODO: would be nice if we could memoize this.
function Board:heights ()
  local hs = {}
  for c=0,9 do
    hs[c] = self:heightAtCol(c)
  end
  return hs
end

-- TODO: would be nice if we could memoize this.
function Board:heightAtCol(col)
  for r=0,19 do
    if self.rows[r].row[col] ~= EMPTY_SQUARE then return 20 - r end
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

function Row:nrColsFilled ()
  local nr = 0
  for i = 0, 9 do
    if self.row[i] ~= EMPTY_SQUARE then nr = nr + 1 end
  end
  return nr
end

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
