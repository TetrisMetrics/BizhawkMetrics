-- TETRIS

require("Board")
require("Drought")
require("helpers")
require("Game")
require("MetricsDisplay")

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

function readMemory(addr)   return memory.readbyte(Addresses[addr])   end

function getTetrimino()     return readMemory("TetriminoID")     end
function getNextTetrimino() return readMemory("NextTetriminoID") end
function getPlayState()     return readMemory("PlayState")       end
function getGameState()     return readMemory("GameState")       end
function getLevel()         return readMemory("Level")           end

function isGameStarting(oldState, newState)
  return oldState == 3 and newState == 4
end

-- detecting game over:
-- this happens when the game officially ends:
-- changing playStateGlobal from 2 to 10
-- changing playStateGlobal from 10 to 0
-- for our purposes, we can just detect the first state change.
function isGameEnding(oldState, newState)
  return oldState == 2 and newState == 10
end

function isGameRunning() return gameStateGlobal == 4  end

function hasTetriminoLockedThisFrame()
  return playStateGlobal == 8 and getPlayState() == 1
end

--
function updateControllerInputs()
  local j = joypad.get(1)
  game:addFrame(emu.framecount(), j)
  currentInputs = j
  drawJoypad(gui, j)
end

--
function updateGameStateGlobals()
  if (gameStateGlobal ~= getGameState()) then
    --print("changing gameStateGlobal from " .. gameStateGlobal .. " to " .. getGameState())
    gameStateGlobal = getGameState()
  end

  if (playStateGlobal ~= getPlayState()) then
    --print("changing playStateGlobal from " .. playStateGlobal .. " to " .. getPlayState())
    playStateGlobal = getPlayState()
  end

  if (currentTetriminoGlobal ~= getTetrimino()) then
    currentTetriminoGlobal = getTetrimino()
  end

  local starting = isGameStarting(gameStateGlobal, getGameState())
  if(starting) then
    print("\n" .. "new game is starting on frame " .. emu.framecount() .. "\n")
    game = Game(emu.framecount(), getLevel())
  end

  local ending = isGameEnding(playStateGlobal, getPlayState())
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
    displayDroughtOnNES(memory, drought)
  end
end

function tick()
  if isGameRunning() then
    if game == nil then game = Game(emu.framecount(), getLevel()) end
    updateControllerInputs();
    updateTetriminos();
    printMetrics(gui, memory, game);
    --displayCheckerboard();
  end
  updateGameStateGlobals();
end

function displayCheckerboard ()
  if playStateGlobal == 3 then writeBoard(memory) end
end

game                    = nil
currentInputs           = joypad.get(1)
gameStateGlobal         = getGameState()
playStateGlobal         = getPlayState()
currentTetriminoGlobal  = getTetrimino()

-- the main loop. runs main function, advances frame, then loops.
while true do
  tick()
  emu.frameadvance()
end
