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

function Drought:copy ()
  local res = Drought(self.tetrimino)
  res.tetrisReady = self.tetrisReady
  res.drought     = self.drought
  res.paused      = self.paused
  res.pauseTime   = self.pauseTime
  return res
end

function Drought:endTurn(nrLinesThisTurn, tetrisReadyAfterTurn, nextTet, game)
  local res = self:copy()

  if nrLinesThisTurn == 4 then
    -- we got a tetris. record drought and reset it
    game:addDrought(res.drought)
    res.drought = 0
    res.paused = false
  -- TODO: actually, we should record the number of times you failed to tetris when you could...
  -- else, if we have a line, toss out drought
  elseif res.tetrimino == 18 and not res.paused then
    res.drought = 0
  elseif res.tetrisReady and not tetrisReadyAfterTurn then
    -- we were tetris ready, but now we are not. drought must be paused.
    res.paused = true
  elseif res.paused and tetrisReadyAfterTurn then
    game:addPause(res.pauseTime)
    res.paused = false
    res.pauseTime = 0
  end

  res.tetrisReady = tetrisReadyAfterTurn
  res.drought     = res.tetrisReady and res.drought   + 1 or res.drought
  res.pauseTime   = res.paused      and res.pauseTime + 1 or res.pauseTime
  return res
end
