-- TETRIS

require("Board")
require("Drought")
require("helpers")
require("Game")
require("GameLoop")
require("GameReplay")
require("Memory")
require("MetricsDisplay")

currentInputs = joypad.get(1)

POSIX = 'POSIX'
WINDOWS = 'WINDOWS'

if package.config:sub(1,1) == "/" then
  osFamily = POSIX
  statsPath = os.getenv("HOME") .. "/tetris_stats/"
  os.execute("mkdir -p " .. statsPath)
  os.execute("mkdir -p " .. statsPath .. "/replays/")
else
  -- TODO: Someone who has actually done something with
  --       windows in the last decade should fix this
  osFamily = WINDOWS
  statsPath = "\\tetris_stats\\"
end
print("Running on " .. osFamily .. "\n")

--
function updateControllerInputs(game)
  game:addFrame(emu.framecount(),joypad.get(1), currentInputs)
  currentInputs = joypad.get(1)
end

function onStart(game)
  print("\n" .. "new game is starting on frame " .. emu.framecount() .. "\n")
end

function onEnd(game)
  if game ~= nil then gameReplayFromGame(game):writeReplay() end
end

function updateTetriminos(game)
  -- when a game first starts, the tetriminos are always set to 19 and 14.
  -- so we need to detect when this changes, and add the first tetriminos to the game.
  if (currentTetriminoGlobal == 19 and getTetrimino() ~= 19) then
    game:setInitialTetriminos(emu.framecount(), getTetrimino(), getNextTetrimino())
  end
end

loop(updateControllerInputs, updateTetriminos, onStart, onEnd)
