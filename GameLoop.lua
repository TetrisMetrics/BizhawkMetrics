-- TETRIS

require("Board")
require("Memory")
require("MetricsDisplay")

game = nil

-- the main loop. runs main function, advances frame, then loops.
function loop(updateControllerInputs, updateTetriminos, onStart, onEnd, onLock, everyFrame)
  while true do
    tick(updateControllerInputs, updateTetriminos, onStart, onEnd, onLock, everyFrame)
    emu.frameadvance()
  end
end

function tick(updateControllerInputs, updateTetriminos, onStart, onEnd, onLock, everyFrame)
  if isGameRunning() and game ~= nil then
    local board = readBoard(memory)
    updateControllerInputs(game, board);
    drawJoypad(gui, joypad.get(1));
    updateTetriminos(game);
    lockTetrimino(board, onLock)
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
    game = nil
  end

  if everyFrame ~= nil then everyFrame() end
end

function lockTetrimino(board, onLock)
  if hasTetriminoLockedThisFrame() then
    local drought = game:lock(getTetrimino(), getNextTetrimino(),
                              board, emu.framecount(),
                              linesClearedThisTurn(game:getNrLines()))
    displayDroughtOnNES(memory, drought)
    onLock(game, board)
  end
end

function displayCheckerboard ()
  if playStateGlobal == 3 then writeBoard(memory) end
end
