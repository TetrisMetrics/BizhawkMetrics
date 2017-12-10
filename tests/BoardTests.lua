---
--- Created by josh.
--- DateTime: 11/4/17 10:07 AM
---

require("helpers")
require('Board')
require("GameReplay")

function randomBoard()
  function testRow()
    local r = {}
    for i = 0, 8 do r[i] = randomNonEmptyTetrimino() end
    r[9] = EMPTY_SQUARE
    return r
  end

  function getRandomRow()
    if(math.random() < 0.8) then return testRow()
    else
      local r = {}
      for i = 0, 9 do r[i] = randomTetrimino() end
      return r
    end
  end

  function randomNonEmptyTetrimino()
    return math.floor(math.random() * 20)
  end

  function randomTetrimino()
    local i = randomNonEmptyTetrimino()
    if i < 5 then return i else return EMPTY_SQUARE end
  end

  local b = {}
  for i = 0, 19 do b[i] = getRandomRow() end
  return Board(b)
end

math.randomseed(os.time())
local b = randomBoard()
b:dump()

print(tableToString(gameReplayFromJsonFile("replays/tetris-game.json")))
