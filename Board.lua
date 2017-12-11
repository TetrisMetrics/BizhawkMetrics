require 'Class'
require 'helpers'

EMPTY_SQUARE = 239

Board = class(function(a, rawBoard)
  a.rows = {}
  for r=0,19 do a.rows[r]=Row(r,rawBoard[r]) end

  -- calculate column heights
  a.heights = {}
  for c=0,9 do
    a.heights[c] = 0
    for r=0,19 do
      if a.rows[r].cols[c] ~= EMPTY_SQUARE then
        a.heights[c] = 20 - r
        break;
      end
    end
  end

  -- calculate max and min heights (across all columns)
  a.maxHeight = 0
  a.minHeight = 20
  for c=0,9 do
    if a.heights[c] > a.maxHeight then a.maxHeight = a.heights[c] end
    if a.heights[c] < a.minHeight then a.minHeight = a.heights[c] end
  end

  -- calculate relativeHeights (differences between neighboring column heights)
  a.relativeHeights = {}
  for i = 0, 8 do a.relativeHeights[i] = a.heights[i + 1] - a.heights[i] end

  -- calculate slope from relativeHeights
  a.totalSlope = 0
  for i = 0, 8 do a.totalSlope = a.totalSlope + a.relativeHeights[i] end
  a.slope = a.totalSlope / 9

  -- calculate bumpiness/jaggeness from relativeHeights
  a.totalBumpiness = 0
  for i = 0, 8 do a.totalBumpiness = a.totalBumpiness + math.abs(a.relativeHeights[i]) end
  a.bumpiness = a.totalBumpiness / 9

  -- calculate tetris readiness
  a.tetrisReadyCol = -1
  a.tetrisReadyRow = -1

  for r=19,3,-1 do
    local col = a.rows[r].well
    if col ~= nil then
      local blockHasTetrisReadyWell =
        a.rows[r-1].well == col and a.rows[r-2].well == col and a.rows[r-3].well == col
      local wellIsClosedBelow = r == 19 or a.rows[r+1]:isFilledAt(col)
      local wellIsOpenAbove = a.heights[col] < 19 - r + 4

      if blockHasTetrisReadyWell and wellIsClosedBelow and wellIsOpenAbove then
        -- only here have we found that we are tetris ready :)
        a.tetrisReadyCol = col
        a.tetrisReadyRow = r
        break;
      end
    end
  end
end)

function Board:isTetrisReady() return self.tetrisReadyCol ~= -1 end

function Board:getSurplus(tetrisReadyRow)
  local r = tetrisReadyRow
  if r == nil then r = self.tetrisReadyRow end
  if r == -1  then return -1 else return self:blocksAboveRow(r-4) end
  return r
end

function Board:blocksAboveRow(r)
  local nr = 0
  for i=r,0,-1 do nr = nr + (self.rows[i].nrColsFilled) end
  return nr
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
  local rs = self.relativeHeights
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

function Board:dump()
  for i = 0, 19 do print(self.rows[i]:dump()) end
  local c = self.tetrisReadyCol
  local r = self.tetrisReadyRow
  if r ~= -1 then
    print("Tetris ready col: ", c + 1)
    print("Tetris ready row: ", r + 1)
    print("surplus: ", self:getSurplus())
  else
    print("board not tetris ready")
  end
end

Row = class(function(a, index, cols)
  a.index = index
  a.cols = cols

  -- calculate # of columns filed
  a.nrColsFilled = 0
  a.emptyIndex = nil
  for i = 0, 9 do
    if cols[i] ~= EMPTY_SQUARE then a.nrColsFilled = a.nrColsFilled + 1
    else a.emptyIndex = i end
  end

  a.well = a.nrColsFilled == 9 and a.emptyIndex or nil
end)

function Row:isTetrisReady () return self.well ~= nil end
function Row:isTetrisReadyAt (col) return self.well == col end
function Row:isEmptyAt  (col) return self.cols[col] == EMPTY_SQUARE end
function Row:isFilledAt (col) return self.cols[col] ~= EMPTY_SQUARE end
function Row:nrColsFilled () return self.nrColsFilled end

function Row:toString()
  local s = ""
  for i = 0, 9 do if self.cols[i] == EMPTY_SQUARE then s = s .. "_" else s = s .. "X" end end
  return s
end

function Row:dump()
  function printInt(i) if(i<10) then return " " .. i else return i end end
  function printWell()
    local w = self.well
    if w == nil then return "NA" else return printInt(w) end
  end
  local metaString = "{" .. printInt(self.index + 1) .. ", " .. printWell() .. "}"
  return self:toString() .. " " .. metaString
end


function readBoard(memory)
  local playfieldAddr = 0x0400
  local b = {}
  for r=0,19 do
    b[r] = {}
    for c=0,9 do
      b[r][c] = memory.readbyte(playfieldAddr + (10*r) + c)
    end
  end
  return Board(b)
end

-- writes the checkerboard
function writeBoard(memory)
  local playfieldAddr = 0x0400
  for r=0,19 do
    for c=0,9 do
      local id = memory.readbyte(playfieldAddr + (10*r) + c)
      if id ~= EMPTY_SQUARE then
        local tColor = isOdd(r+c) and 124 or 125
        memory.writebyte(playfieldAddr + (10*r) + c, tColor)
      end
    end
  end
end
