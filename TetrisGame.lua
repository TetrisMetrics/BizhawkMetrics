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
  a.startFrame    = startFrame
  a.level         = level
  a.frames        = {}
  a.tetriminos    = List()
  a.clears        = List()
  a.drought       = Drought()
end)

function TetrisGame:dump()
  return "Game{" ..
    --"tetriminos: "    .. self.tetriminos:dump()            ..
    -- ", frames: "   .. tableToList(self.frames):dump()   ..
    "  clears: "      .. self.clears:dump()                ..
    ", droughts: "    .. self.drought.droughts:dump()      ..
    ", pauses: "      .. self.drought.pauseTimes:dump()    ..
    ", avg clear: "   .. self.clears:average()             ..
    ", avg drought: " .. self.drought.droughts:average()   ..
    ", avg pause: "   .. self.drought.pauseTimes:average() ..
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

function TetrisGame:addTetrimino (t)
  self.tetriminos:pushright(t)
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
