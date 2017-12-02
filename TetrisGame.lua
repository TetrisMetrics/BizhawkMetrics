---
--- Created by Joshua.
--- DateTime: 10/25/2017 7:25 PM
---

require ("Board")
require ('Class')
require ("Drought")
require ('List')
require ('helpers')

-- TODO: Number of clicks per tetrimino and APM
-- TODO: DAS info...
TetrisGame = class(function(a,startFrame,startLevel)
  a.startFrame      = startFrame -- the exact NES frame the game started on.
  a.startLevel      = startLevel -- the level the game started on.

  a.drought         = Drought() -- the drought object helps calculate droughts

  a.frames          = {}     -- list of everything that happened every frame. indexed by frame nr.
  a.tetriminos      = List() -- list of all the tetriminos that spawned. in order, and on what frame.
  a.clears          = List() -- list of every clear that happened. in order.
  a.nrDrops         = -2  -- this weird -2 is fixed when we add the first two tetriminos

  a.accommodations  = 0 -- really this is accommodation total. total across all drops.

  a.totalMaxHeight  = 0 -- the total of the max heights at every drop
  a.totalMinHeight  = 0 -- he total of the min heights at every drop

  a.tetrisReady     = false -- is the board tetris ready or not
  a.nrTimesReady    = 0     -- how many times the board has been tetris ready

  a.lastTetris      = 0 -- tetrimino/drop count when we last got a tetris
  a.readyDistance   = 0 -- total distance between last tetris and tetris readiness.

  a.lastSurplus     = 0 -- number of blocks above perfection the last time we became tetris ready.
  a.totalSurplus    = 0 -- the total of all of those

  a.nrLines         = 0 -- number of lines cleared so far
  a.nrClears        = 0 -- number of times lines have been cleared (singles, doubles, ...)
  a.tetrises        = 0 -- number of tetrises scored so far
  a.triples         = 0 -- number of triples scored so far
  a.doubles         = 0 -- number of doubles scored so far
  a.singles         = 0 -- number of singles scored so far

  a.totalPause      = 0 -- total amount of time (blocks dropped) that a tetris ready well has been covered
  a.nrPauses        = 0 -- total number of times that a tetris ready well has been covered up
  a.totalDrought    = 0 -- total number of blocks dropped until a line comes, WHEN we become tetris ready.
  a.nrDroughts      = 0 -- TODO: this seems like it should be the same as nrTimesReady. check.
end)

function TetrisGame:dump()
  print("Game:")
  --print("tetriminos: "             .. self.tetriminos:dump())
  --print("frames: "                 .. tableToList(self.frames):dump())
  print("  avg clear: "          .. round(self:avgClear(), 3))
  print("  avg accommodation: "  .. round(self:avgAccommodation(), 3))
  print("  avg max height: "     .. round(self:avgMaxHeight(), 2))
  print("  avg min height: "     .. round(self:avgMinHeight(), 2))
  print("  avg drought: "        .. round(self:avgDrought(), 2))
  print("  avg pause: "          .. round(self:avgPause(), 2))
  print("  avg surplus: "        .. round(self:avgSurplus(), 2))
  print("  conversion ratio: "   .. round(self:conversionRatio(), 2))
  print("  avg ready distance: " .. round(self:avgReadinessDistance(), 2))
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

function TetrisGame:setTetrisReady (r)
  self.tetrisReady = r
end

function TetrisGame:isTetrisReady ()
  return self.tetrisReady
end

function TetrisGame:getNrLines ()
  return self.nrLines
end

function TetrisGame:addClear (nrLines)
  self.clears:pushright(nrLines)
  self.nrClears = self.nrClears + 1
  self.nrLines  = self.nrLines + nrLines
  if nrLines == 4 then
    self.tetrises = self.tetrises + 1
    self.lastTetris = self.nrDrops -- todo: move that last part?
  end
  if nrLines == 3 then self.triples  = self.triples  + 1 end
  if nrLines == 2 then self.doubles  = self.doubles  + 1 end
  if nrLines == 1 then self.singles  = self.singles  + 1 end
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
  if self.nrDrops == 0 then return 0
  else return (self.totalMaxHeight / self.nrDrops) end
end

function TetrisGame:addSurplus (s)
  self.lastSurplus  = s
  self.nrTimesReady = self.nrTimesReady + 1
  self.totalSurplus = self.totalSurplus + s
  -- TODO: move this someplace better,
  -- or have a function, "become ready" that calls addSurplus and this
  self.readyDistance = self.readyDistance + (self.nrDrops - self.lastTetris)
end

function TetrisGame:addDrought (d)
  self.totalDrought = self.totalDrought + d
  self.nrDroughts = self.nrDroughts + 1
end

function TetrisGame:addPause (p)
  self.totalPause = self.totalPause + p
  self.nrPauses = self.nrPauses + 1
end

function TetrisGame:avgClear ()
  if self.nrClears == 0 then return 0
  else return (self.nrLines / self.nrClears) end
end

function TetrisGame:avgMinHeight ()
  if self.nrDrops == 0 then return 0
  else return (self.totalMinHeight / self.nrDrops) end
end

function TetrisGame:avgAccommodation ()
  if self.nrDrops == 0 then return 0
  else return (self.accommodations / self.nrDrops) end
end

function TetrisGame:avgSurplus ()
  if self.nrTimesReady == 0 then return 0
  else return (self.totalSurplus / self.nrTimesReady) end
end

function TetrisGame:avgDrought ()
  if self.nrDroughts == 0 then return 0
  else return (self.totalDrought / self.nrDroughts) end
end

function TetrisGame:avgPause ()
  if self.nrPauses == 0 then return 0
  else return (self.totalPause / self.nrPauses) end
end

function TetrisGame:avgReadinessDistance ()
  if self.nrTimesReady == 0 then return 0
  else return (self.readyDistance / self.nrTimesReady) end
end

function TetrisGame:conversionRatio()
  if self.nrTimesReady == 0 then return 1
  else return self.tetrises / self.nrTimesReady end
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
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
