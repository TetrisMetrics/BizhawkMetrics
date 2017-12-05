-- TETRIS

require("Board")
require("Drought")
require("helpers")
require("Game")

local displayMetrics = input.popup("Display Metrics?")

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
    currentInputs = j
  end
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
    game = Game(emu.framecount(), getLevel())
  end

  if(ending) then
    print("\n" .. "game ended on frame " .. emu.framecount() .. "\n")
    if(game ~= nil) then game:dump() end
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
  local globalFrame = emu.framecount()
  -- when a game first starts, the tetriminos are always set to 19 and 14.
  -- so we need to detect when this changes, and add the first tetriminos to the game.
  if (currentTetriminoGlobal == 19 and at ~= 19) then
    game:addTetrimino(globalFrame, at)
    game:addTetrimino(globalFrame, nt)
  end

  if hasTetriminoLockedThisFrame() then
    local drought = game:lock(at, nt, readBoard(memory), globalFrame, linesClearedThisTurn())
    displayDroughtOnNES(drought)
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

  if displayMetrics == "no" then return; end

  local red = "#a81605"

  gui.drawrect(5,20,85,215,"black", red)

  local x1 = 8
  local y1 = 23

  local das = memory.readbyte(0x0046)
  local dasBackgroundColor
  if das < 10 then dasBackgroundColor = red else dasBackgroundColor = "#207005" end
  --gui.text(x1,y1+0,"DAS:" .. memory.readbyte(0x0046), "white", dasBackgroundColor)
  gui.text(x1,y1+0,"Clears:", "white", "black")

  local y2 = y1+20

  printMetric( 0, "Singles:  ", game.singles)
  printMetric(10, "Doubles:  ", game.doubles)
  printMetric(20, "Triples:  ", game.triples)
  printMetric(30, "Tetrises: ", game.tetrises)

  gui.text(x1,y2+50,"AVERAGES:", "white", "black")

  printMetric(70,  "Cnversion: " , game:conversionRatio())
  printMetric(80,  "Clear:    "  , game:avgClear())
  printMetric(90,  "Accmdation:" , game:avgAccommodation())
  printMetric(100, "Max height:" , game:avgMaxHeight())
  printMetric(110, "Min height:" , game:avgMinHeight())
  printMetric(120, "Surplus: "   , game:avgSurplus())
  printMetric(130, "Drought: "   , game:avgDrought())
  printMetric(140, "Pause:  "    , game:avgPause())
  printMetric(150, "Readiness:"  , game:avgReadinessDistance())
  printMetric(160, "Presses: "   , game:avgPressesPerTetrimino())

  gui.drawrect(192,y2+60,192+30,y2+72,"black")
  gui.text(192,y2+62,"DAS:" .. memory.readbyte(0x0046), "white", dasBackgroundColor)
end

function printMetric(yOffset,title,num)
  local x1 = 12
  local y2 = 43
  local numDisplay = ""
  if num ~= nil then numDisplay = round(num, 2) end
  gui.text(x1,y2+yOffset, title .. numDisplay, "white", "black")
end

function main()
  if isGameRunning() and game ~= nil then
    updateControllerInputs();
    updateTetriminos();
    printMetrics();
    if playStateGlobal == 3 then writeBoard(memory) end
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
  emu.frameadvance()
end
