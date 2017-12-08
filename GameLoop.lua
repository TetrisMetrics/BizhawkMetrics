-- TETRIS

require("Board")
require("Memory")
require("MetricsDisplay")

game = nil
currentInputs = joypad.get(1)


function tick(updateControllerInputs, updateTetriminos, onStart, onEnd, shouldDrawCheckerboard)
  if isGameRunning() and game ~= nil then
    updateControllerInputs();
    drawJoypad(gui, joypad.get(1));
    updateTetriminos();
    lockTetrimino()
    printMetrics(gui, memory, game);
    if shouldDrawCheckerboard then displayCheckerboard() end
  end
  updateGameStateGlobals();
  if starting then onStart() end
  if ending   then onEnd()   end
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
