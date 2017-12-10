-- TETRIS

require("Board")
require("Memory")
require("MetricsDisplay")

game = nil

-- the main loop. runs main function, advances frame, then loops.
function loop(updateControllerInputs, updateTetriminos, onStart, onEnd, shouldDrawCheckerboard)
  while true do
    tick(updateControllerInputs, updateTetriminos, onStart, onEnd, shouldDrawCheckerboard)
    emu.frameadvance()
  end
end

function tick(updateControllerInputs, updateTetriminos, onStart, onEnd)
  if isGameRunning() and game ~= nil then
    updateControllerInputs(game);
    drawJoypad(gui, joypad.get(1));
    updateTetriminos(game);
    lockTetrimino()
    printMetrics(gui, memory, game);
    --if false then displayCheckerboard() end
  end
  updateGameStateGlobals();

  if starting then
    game = Game(emu.framecount(), getLevel())
    onStart(game)
  end

  if ending then
    print("\n" .. "game ended on frame " .. emu.framecount() .. "\n")
    if game ~= nil then game:dump() end
    onEnd(game)
  end
end

function lockTetrimino()
  if hasTetriminoLockedThisFrame() then
    local drought = game:lock(getTetrimino(), getNextTetrimino(),
                              readBoard(memory), emu.framecount(),
                              linesClearedThisTurn(game:getNrLines()))
    displayDroughtOnNES(memory, drought)
  end
end

function displayCheckerboard ()
  if playStateGlobal == 3 then writeBoard(memory) end
end
