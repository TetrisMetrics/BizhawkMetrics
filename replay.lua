-- TETRIS GAME REPLAYER

require("Game")
require("GameLoop")
require("GameReplay")
require("Memory")

currentInputs = joypad.get(1)
gameStartFrameGlobal = 0
replay = gameReplayFromJsonFile("replays/tetris-game.json")

function getFrameOffset()
  return emu.framecount() - gameStartFrameGlobal
end

--
function updateControllerInputs(game)
  local frame = getFrameOffset()
  local j = replay.frames[tostring(frame)]
  if j ~= nil then
    --print("frame", frame, "joypad", j)
    currentInputs =  {
      ["start"]  = frame == 1 and true or (frame == 11 and false or nil),
      ["A"]      = j["A"]     == nil and currentInputs["A"]     or j["A"],
      ["B"]      = j["B"]     == nil and currentInputs["B"]     or j["B"],
      ["up"]     = j["up"]    == nil and currentInputs["up"]    or j["up"],
      ["down"]   = j["down"]  == nil and currentInputs["down"]  or j["down"],
      ["left"]   = j["left"]  == nil and currentInputs["left"]  or j["left"],
      ["right"]  = j["right"] == nil and currentInputs["right"] or j["right"],
    }
    joypad.write(1, currentInputs)
  else
    if currentInputs["start"] == false then currentInputs["start"] = nil end
    joypad.write(1, currentInputs)
  end
end

function onStart(game)
  print("\n" .. "replay is starting on frame " .. emu.framecount() .. "\n")
  gameStartFrameGlobal = emu.framecount()
end

function onEnd(game) currentInputs = {} end

function updateTetriminos(game)
  local frame = getFrameOffset()
  -- when a game first starts, the tetriminos are always set to 19 and 14.
  -- so we need to detect when this changes, and add the first tetriminos to the game.
  if (frame == 4) then
    print("frame", frame, "first",  getTetriminoNameById(replay.firstTetrimino))
    print("frame", frame, "second", getTetriminoNameById(replay.secondTetrimino))
    memory.writebyte(Addresses["TetriminoID"],     replay.firstTetrimino)
    memory.writebyte(Addresses["NextTetriminoID"], replay.secondTetrimino)
  end

  local tet  = replay["tetriminos"][tostring(getFrameOffset() - 1)]
  if tet ~= nil then
    --print("frame", frame, "tet", getTetriminoNameById(tet))
    memory.writebyte(Addresses["NextTetriminoID"], tet)
  end
end

loop(updateControllerInputs, updateTetriminos, onStart, onEnd)
