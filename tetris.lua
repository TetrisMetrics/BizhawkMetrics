-- TETRIS

require("Board")
require("Drought")
require("helpers")
require("TetrisGame")

ButtonNames = {"P1 A", "P1 B", "P1 Up", "P1 Down", "P1 Left", "P1 Right"}

Addresses = {
  ["OrientationTable"]   = 0x8A9C,
  ["TetriminoTypeTable"] = 0x993B,
  ["SpawnTable"]         = 0x9956,
  ["Copyright1"]         = 0x00C3,
  ["Copyright2"]         = 0x00A8,
  ["GameState"]          = 0x00C0,
  ["LowCounter"]         = 0x00B1,
  ["HighCounter"]        = 0x00B2,
  ["TetriminoX"]         = 0x0060,
  ["TetriminoY1"]        = 0x0061,
  ["TetriminoY2"]        = 0x0041,
  ["TetriminoID"]        = 0x0062,
  ["NextTetriminoID"]    = 0x00BF,
  ["FallTimer"]          = 0x0065,
  ["Playfield"]          = 0x0400,
  ["Level"]              = 0x0064,
  ["LevelTableAccess"]   = 0x9808,
  ["LinesHigh"]          = 0x0071,
  ["LinesLow"]           = 0x0070,
  ["PlayState"]          = 0x0068,
}

function readMemory(addr)   return memory.readbyte(Addresses[addr])    end

function getTetrimino()     return readMemory("TetriminoID")     end
function getNextTetrimino() return readMemory("NextTetriminoID") end
function getPlayState()     return readMemory("PlayState")       end
function getGameState()     return readMemory("GameState")       end
function getLevel()         return readMemory("Level")           end

function isGameStarting(oldState, newState)
  return oldState == 3 and newState == 4;
end

-- detecting game over:
-- this happens when the game officially ends:
-- changing playStateGlobal from 2 to 10
-- changing playStateGlobal from 10 to 0
-- for our purposes, we can just detect the first state change.
function isGameEnding(oldState, newState)
  return oldState == 2 and newState == 10;
end

function isGameRunning()
  return gameStateGlobal == 4;
end

function hasTetriminoLockedThisFrame()
  return playStateGlobal == 8 and getPlayState() == 1
end

function getGameFrame()
  return emu.framecount() - game.startFrame;
end

PRESSED   = { [1] = false,[2] = true }
UNPRESSED = { [1] = true, [2] = false }

--
function updateControllerInputs()
  local j    = joypad.get(1)
  local diff = getTableDiffs(currentInputs, j)
  if tableLength(diff) > 0 then
    -- change the ugly diffs to just true (for pressed) and false (for unpressed)
    for k,v in pairs(diff) do
      if (deepEquals(v,PRESSED))   then diff[k] = true  end
      if (deepEquals(v,UNPRESSED)) then diff[k] = false end
    end

    game:addFrame(emu.framecount(), diff)
    --print(getGameFrame(), tableToString(game:getFrame(emu.framecount())))
    currentInputs = j
  end
end

function readBoard()
  local b = {}
  for r=0,19 do
     b[r] = {}
    for c=0,9 do b[r][c] = memory.readbyte(Addresses["Playfield"] + (10*r) + c) end
  end
  return Board(b)
end

--
function updateGameStateGlobals()
  local gState   = getGameState()
  local pState   = getPlayState()
  local tet      = getTetrimino()
  local starting = isGameStarting(gameStateGlobal, gState)
  local ending   = isGameEnding(playStateGlobal, pState)

  if (gameStateGlobal ~= gState) then
    --print("changing gameStateGlobal from " .. gameStateGlobal .. " to " .. gState)
    gameStateGlobal = gState
  end

  if (playStateGlobal ~= pState) then
    --print("changing playStateGlobal from " .. playStateGlobal .. " to " .. pState)
    playStateGlobal = pState
  end

  if (currentTetriminoGlobal ~= tet) then
    currentTetriminoGlobal = tet
  end

  if(starting) then
    print("\n" .. "new game is starting on frame " .. emu.framecount() .. "\n")
    game = TetrisGame(emu.framecount(), getLevel())
  end

  if(ending) then
    print("\n" .. "game ended on frame " .. emu.framecount() .. "\n")
    if(game ~= nil) then print(game:dump()) end
  end
end

function linesClearedThisTurn()
  local low = readMemory("LinesLow")
  local high = readMemory("LinesHigh")
  local lines = tonumber(high .. string.format("%x", low))
  return lines - game:getNrLines()
end

function updateTetriminos()
  local at = getTetrimino()
  local nt = getNextTetrimino()
  -- when a game first starts, the tetriminos are always set to 19 and 14.
  -- so we need to detect when this changes, and add the first tetriminos to the game.
  if (currentTetriminoGlobal == 19 and at ~= 19) then
    game:addTetrimino({[getGameFrame()] = at})
    game:addTetrimino({[getGameFrame()] = nt})
    --print(getGameFrame(), "added tetrimino:", getTetriminoNameById(at))
    --print(getGameFrame(), "added tetrimino:", getTetriminoNameById(nt))
  end

  if hasTetriminoLockedThisFrame() then handleLock(at, nt) end
end

function handleLock (at, nt)
  local linesThisTurn = linesClearedThisTurn()
  if linesThisTurn > 0 then game:addClear(linesThisTurn) end
  local b = readBoard()
  --b:dump()
  local tetrisReadyRow = b:tetrisReadyRow()
  local isReady        = tetrisReadyRow ~= -1
  game:addTetrimino({[getGameFrame()] = nt}, b)
  --print(getGameFrame(), "added tetrimino:", getTetriminoNameById(nt))
  handleDrought(linesThisTurn, isReady, at)
  handleSurplus(b, linesThisTurn, tetrisReadyRow, isReady)
  game:setTetrisReady(isReady)
end

function handleDrought (lines, ready, at)
  local drought = game.drought:endTurn(lines, ready, at, game)
  displayDroughtOnNES(drought)
end

function handleSurplus(b, lines, tetrisReadyRow, ready)
  local haveBecomeReadyThisTurn =
    (ready and not game:isTetrisReady()) or (ready and linesThisTurn == 4)
  -- if we just became tetris ready, record the surplus
  if(haveBecomeReadyThisTurn) then
    game:addSurplus(b:getSurplus(tetrisReadyRow))
  end
end

function displayDroughtOnNES(drought)
  local droughtLength = drought["drought"]
  local pauseLength   = drought["paused"]

  -- Write drought counter to NES RAM so that it can be displayed.
  memory.writebyte(0x03fe, droughtLength);
  local droughtLengthDecimal = math.floor(droughtLength / 10) * 16 + (droughtLength % 10);
  memory.writebyte(0x03ff, droughtLengthDecimal);

  -- bcd not needed here, because it's just being tested against 0 right now.
  memory.writebyte(0x03ee, pauseLength);
end

function printMetrics()


  gui.drawrect(10,20,85,215,"gray", "red")

  local x1 = 13
  local y1 = 23

  local das = memory.readbyte(0x0046)
  local dasColor
  if das == 0 then dasColor = "red" end
  gui.text(x1,y1+0,"DAS:" .. memory.readbyte(0x0046), dasColor)

  local y2 = y1+20

  gui.text(x1,y2+ 0, "Singles:  "..game.singles)
  gui.text(x1,y2+10, "Doubles:  " ..game.doubles)
  gui.text(x1,y2+20, "Triples:  "..game.triples)
  gui.text(x1,y2+30, "Tetrises: "..game.tetrises)

  gui.text(x1,y2+50, "Averages:")

  gui.text(x1,y2+70, "Cnversion:"..round(game:conversionRatio(), 2))
  gui.text(x1,y2+80, "Clear:   "..round(game:avgClear(), 2))
  gui.text(x1,y2+90, "Accmdation:"..round(game:avgAccommodation(), 2))
  gui.text(x1,y2+100, "Max ht: " ..round(game:avgMaxHeight(), 2))
  gui.text(x1,y2+110, "Min ht:  "..round(game:avgMinHeight(), 2))
  gui.text(x1,y2+120, "Surplus: "..round(game:avgSurplus(), 2))
  gui.text(x1,y2+130, "Drought: "..round(game:avgDrought(), 2))
  gui.text(x1,y2+140, "Pause:  " ..round(game:avgPause(), 2))


end

function main()
  if isGameRunning() and game ~= nil then
    updateControllerInputs();
    updateTetriminos();
    printMetrics();
  end
  updateGameStateGlobals();
end

game                    = nil
currentInputs           = joypad.get(1)
gameStateGlobal         = getGameState()
playStateGlobal         = getPlayState()
currentTetriminoGlobal  = getTetrimino()

-- the main loop. runs main function, advances frame, then loops.
while true do
  main()
  --visualizeSprites()
  emu.frameadvance()
end
