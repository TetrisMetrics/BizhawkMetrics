require ("Board")
require ('Class')
require ("Drought")
require ('List')
require ('helpers')

-- TODO: APM ?
-- TODO: DAS info...
TetrisGame = class(function(a,startFrame,startLevel)
  a.startFrame      = startFrame -- the exact NES frame the game started on.
  a.startLevel      = startLevel -- the level the game started on.

  a.drought         = Drought() -- the drought object helps calculate droughts

  a.frames          = {} -- list of everything that happened every frame. indexed by frame nr.
  a.tetriminos      = {} -- list of all the tetriminos that spawned, indexed by frame.
  a.clears          = {} -- list of every clear that happened, indexed by frame.
  a.nrDrops         = -2 -- this weird -2 is fixed when we add the first two tetriminos

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

  a.nrPresses       = -2 -- Start gets pressed and unpressed to start the game, and we ignore those.
  a.nrPressesPerTet = 0
end)

function TetrisGame:dump()
  --print("Game:")
  --print("tetriminos: "              .. tableToList(self.tetriminos):dump())
  --print("frames: "                  .. tableToList(self.frames):dump())
  --print("clears: "                  .. tableToList(self.clears):dump())
  print("  avg clear: "             .. self:avgClear())
  print("  avg accommodation: "     .. self:avgAccommodation())
  print("  avg max height: "        .. self:avgMaxHeight())
  print("  avg min height: "        .. self:avgMinHeight())
  print("  avg drought: "           .. self:avgDrought())
  print("  avg pause: "             .. self:avgPause())
  print("  avg surplus: "           .. self:avgSurplus())
  print("  conversion ratio: "      .. self:conversionRatio())
  print("  avg ready distance: "    .. self:avgReadinessDistance())
  print("  avg presses (per tet): " .. self:avgPressesPerTetrimino())
end

---- a diff will take the form {"P1 UP": PRESSED, "P1 A": UNPRESSED, ...}
---- for now...
---- only buttons that actually changed between this frame and the previous frame will appear in diffs.
function TetrisGame:addFrame (frame, diffs)
  self.frames[frame - self.startFrame] = diffs
  if diffs ~= nil then
    self.nrPresses = self.nrPresses + tableLength(diffs)
  end
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

function TetrisGame:addClear (frame, nrLines)
  self.clears[frame] = nrLines
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

function TetrisGame:addTetrimino (frame, t, board)
  self.tetriminos[frame] = at
  self.nrDrops = self.nrDrops + 1
  if(board ~= nil) then
    --print("self.nrPresses", self.nrPresses, "self.nrDrops", self.nrDrops)
    self.nrPressesPerTet = (self.nrPresses / 2) / self.nrDrops
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
  return (self.nrClears == 0) and 0 or (self.nrLines / self.nrClears)
end

function TetrisGame:avgMaxHeight ()
  return (self.nrDrops == 0) and 0 or (self.totalMaxHeight / self.nrDrops)
end

function TetrisGame:avgMinHeight ()
  return (self.nrDrops == 0) and 0 or (self.totalMinHeight / self.nrDrops)
end

function TetrisGame:avgAccommodation ()
  return (self.nrDrops == 0) and 0 or (self.accommodations / self.nrDrops)
end

function TetrisGame:avgSurplus ()
  return (self.nrTimesReady == 0) and 0 or (self.totalSurplus / self.nrTimesReady)
end

function TetrisGame:avgDrought ()
  return (self.nrDroughts == 0) and 0 or (self.totalDrought / self.nrDroughts)
end

function TetrisGame:avgPause ()
  return (self.nrPauses == 0) and 0 or (self.totalPause / self.nrPauses)
end

function TetrisGame:avgReadinessDistance ()
  return (self.nrTimesReady == 0) and 0 or (self.readyDistance / self.nrTimesReady)
end

function TetrisGame:avgPressesPerTetrimino ()
  return self.nrPressesPerTet
end

function TetrisGame:conversionRatio()
  return (self.nrTimesReady == 0) and 0 or (self.tetrises / self.nrTimesReady)
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

TetriminosById = { [2]  = "T", [7]  = "J", [8]  = "Z", [10] = "0", [11] = "S", [14] = "L", [18] = "I" }
TetriminosByName = { ["T"] = 2, ["J"] = 7, ["Z"] = 8, ["0"] = 10, ["S"] = 11, ["L"] = 14, ["I"] = 18 }

function getTetriminoNameById(id) return TetriminosById[id] end
