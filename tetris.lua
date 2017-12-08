-- TETRIS

require("Board")
require("Drought")
require("helpers")
require("Game")
require("GameLoop")
require("GameReplay")
require("Memory")
require("MetricsDisplay")

shouldDrawCheckerboard = false
shouldWriteGameFiles   = true

--
function updateControllerInputs()
  game:addFrame(emu.framecount(),joypad.get(1), currentInputs)
  currentInputs = joypad.get(1)
end

function onStart()
  print("\n" .. "new game is starting on frame " .. emu.framecount() .. "\n")
  game = Game(emu.framecount(), getLevel())
end

function onEnd()
  print("\n" .. "game ended on frame " .. emu.framecount() .. "\n")
  if game ~= nil then
    game:dump()
    if shouldWriteGameFiles then gameReplayFromGame(game):writeReplay() end
  end
end

function updateTetriminos()
  -- when a game first starts, the tetriminos are always set to 19 and 14.
  -- so we need to detect when this changes, and add the first tetriminos to the game.
  if (currentTetriminoGlobal == 19 and getTetrimino() ~= 19) then
    game:setInitialTetriminos(emu.framecount(), getTetrimino(), getNextTetrimino())
  end
end

while true do
  tick(updateControllerInputs, updateTetriminos, onStart, onEnd, shouldDrawCheckerboard)
  emu.frameadvance()
end