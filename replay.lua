-- TETRIS GAME REPLAYER

require("Game")
require("GameLoop")
require("GameReplay")
require("Memory")

shouldDrawCheckerboard = false
gameStartFrameGlobal    = 0
replay = gameReplayFromJsonFile("replays/tetris-game-12-08-2017_16-54.json")

--
function updateControllerInputs()
  local frame = emu.framecount() - gameStartFrameGlobal
  local j = replay.frames[tostring(frame)]
  if j ~= nil then
    j["start"] = nil
    print("frame", frame, "joypad", j)
    joypad.write(1, j)
    currentInputs = j
  else
    joypad.write(1, currentInputs)
  end
end

function onStart()
  print("\n" .. "new game is starting on frame " .. emu.framecount() .. "\n")
  gameStartFrameGlobal = emu.framecount()
  game = Game(emu.framecount(), getLevel())
end

function onEnd()
  print("\n" .. "game ended on frame " .. emu.framecount() .. "\n")
  if game ~= nil then game:dump() end
end

function updateTetriminos()
  local frame = emu.framecount() - gameStartFrameGlobal
  -- when a game first starts, the tetriminos are always set to 19 and 14.
  -- so we need to detect when this changes, and add the first tetriminos to the game.
  if (frame == 4) then
    --print("frame", frame, "first",  getTetriminoNameById(replay.firstTetrimino))
    --print("frame", frame, "second", getTetriminoNameById(replay.secondTetrimino))
    memory.writebyte(Addresses["TetriminoID"],     replay.firstTetrimino)
    memory.writebyte(Addresses["NextTetriminoID"], replay.secondTetrimino)
  end

  local tet  = replay["tetriminos"][tostring(emu.framecount() - gameStartFrameGlobal)]
  if tet ~= nil then
    --print("frame", frame, "tet", getTetriminoNameById(tet))
    memory.writebyte(Addresses["NextTetriminoID"], tet)
  end
end

-- the main loop. runs main function, advances frame, then loops.
while true do
  tick(updateControllerInputs, updateTetriminos, onStart, onEnd, shouldDrawCheckerboard)
  emu.frameadvance()
end
