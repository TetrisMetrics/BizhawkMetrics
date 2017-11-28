---
--- Created by Joshua.
--- DateTime: 10/25/2017 7:25 PM
---

require ("Board")
require ('Class')
require ("Drought")
require ('List')
require ('helpers')

TetrisGame = class(function(a,startFrame,level)
  a.startFrame     = startFrame
  a.level          = level
  a.frames         = {}
  a.tetriminos     = List()
  a.clears         = List()
  a.drought        = Drought()
  a.nrDrops        = -2
  a.accommodations = 0
  a.totalMaxHeight = 0
  a.totalMinHeight = 0
  a.nrTimesReady   = 0
  a.lastSurplus    = 0
  a.totalSurplus   = 0
end)

function TetrisGame:dump()
  return "Game{" ..
    --"tetriminos: "          .. self.tetriminos:dump()                ..
    --", frames: "            .. tableToList(self.frames):dump()       ..
    --", clears: "            .. self.clears:dump()                    ..
    --", droughts: "          .. self.drought.droughts:dump()          ..
    --", pauses: "            .. self.drought.pauseTimes:dump()        ..
    "  avg clear: "         .. self.clears:average()                 ..
    ", avg max height: "    .. self:avgMaxHeight()                   ..
    ", avg min height: "    .. self:avgMinHeight()                   ..
    ", avg drought: "       .. self.drought.droughts:average()       ..
    ", avg pause: "         .. self.drought.pauseTimes:average()     ..
    ", avg accommodation: " .. self:avgAccommodation()               ..
    ", avg surplus: "       .. self:avgSurplus()                     ..
  "}"
end

---- a diff will take the form {"P1 UP": PRESSED, "P1 A": UNPRESSED, ...}
---- for now...
---- only buttons that actually changed between this frame and the previous frame will appear in diffs.
function TetrisGame:addFrame (frame, diffs)
  self.frames[frame - self.startFrame] = diffs
end

function TetrisGame:getFrame (frame)
  return self.frames[frame - self.startFrame]
end

function TetrisGame:addClear (nrLines)
  self.clears:pushright(nrLines)
end

function TetrisGame:addTetrimino (t, board)
  self.tetriminos:pushright(t)
  self.nrDrops = self.nrDrops + 1
  if(board ~= nil) then
    self:addAccommodation(board:accommodationScore())
    self:addMaxHeight(board:maxHeight())
    self:addMinHeight(board:minHeight())
  end
end

function TetrisGame:addAccommodation (a)
  self.accommodations = self.accommodations + a
end

function TetrisGame:addMaxHeight (h)
  self.totalMaxHeight = self.totalMaxHeight + h
end

function TetrisGame:addMinHeight (h)
  self.totalMinHeight = self.totalMinHeight + h
end

function TetrisGame:avgMaxHeight ()
  return (self.totalMaxHeight / self.nrDrops)
end

function TetrisGame:addSurplus (s)
  self.lastSurplus  = s
  self.nrTimesReady = self.nrTimesReady + 1
  self.totalSurplus = self.totalSurplus + s
  print("adding surplus", s)
end

function TetrisGame:avgMinHeight ()
  return (self.totalMinHeight / self.nrDrops)
end

function TetrisGame:avgAccommodation ()
  return (self.accommodations / self.nrDrops)
end

function TetrisGame:avgSurplus ()
  return (self.totalSurplus / self.nrTimesReady)
end

function TetrisGame:getPreviousTetrimino ()
  local t = self.tetriminos:peekright(-2)
  if t ~= nil then return getFirstValueInTable(t) end
end

function TetrisGame:getActiveTetrimino ()
  local t = self.tetriminos:peekright(-1)
  if t ~= nil then return getFirstValueInTable(t) end
end

function TetrisGame:getNextTetrimino ()
  local t = self.tetriminos:peekright(0)
  if t ~= nil then return getFirstValueInTable(t) end
end

TetriminosById = {
  [2]  = "T",
  [7]  = "J",
  [8]  = "Z",
  [10] = "0",
  [11] = "S",
  [14] = "L",
  [18] = "I",
}

TetriminosByName = {
  ["T"] = 2,
  ["J"] = 7,
  ["Z"] = 8,
  ["0"] = 10,
  ["S"] = 11,
  ["L"] = 14,
  ["I"] = 18,
}

function getTetriminoNameById(id) return TetriminosById[id] end
