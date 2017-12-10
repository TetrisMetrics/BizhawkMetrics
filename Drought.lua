---
--- Created by josh.
--- DateTime: 11/2/17 4:02 AM
---

require 'Class'
require 'helpers'

-- drought counting notes
-- two ways to wipe it out
-- if you get a tetris
-- if you get a line, but don't use it to tetris and throw that one out for the average.
-- it pauses if you block your well or burn part of your well

-- its either getting wiped out, paused
-- or incremented, or ignored because its paused.
Drought = class(function(a, tet)
  a.tetrisReady  = false
  a.tetrimino    = tet
  a.drought      = 0
  a.paused       = false -- true if we closed our own well, until it become open again
  a.pauseTime    = 0
end)

function Drought:endTurn(nrLinesThisTurn, tetrisReadyAfterTurn, nextTet, game)
  if nrLinesThisTurn == 4 then
    -- we got a tetris. record drought and reset it
    game:addDrought(self.drought)
    self.drought = 0
    self.paused = false
  -- TODO: actually, we should record the number of times you failed to tetris when you could...
  -- else, if we have a line, toss out drought
  elseif self.tetrimino == 18 and not self.paused then
    self.drought = 0
  elseif self.tetrisReady and not tetrisReadyAfterTurn then
    -- we were tetris ready, but now we are not. draught must be paused.
    self.paused = true
  elseif self.paused and tetrisReadyAfterTurn then
    game:addPause(self.pauseTime)
    self.paused = false
    self.pauseTime = 0
  end

  self.tetrisReady = tetrisReadyAfterTurn
  self.tetrimino   = nextTet

  if self.tetrisReady then
    self.drought = self.drought + 1
  elseif self.paused then
    self.pauseTime = self.pauseTime + 1
  end

  return {["drought"] = self.drought, ["paused"] = self.pauseTime}
end
