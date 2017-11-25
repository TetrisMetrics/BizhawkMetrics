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
    for c=0,9 do
      b[r][c] = memory.readbyte(Addresses["Playfield"] + (10*r) + c)
    end
  end
  --print(tableToString(b))
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
    print(game:dump())
  end
end

function linesClearedThisTurn()
  local low = readMemory("LinesLow")
  local high = readMemory("LinesHigh")
  local lines = tonumber(high .. string.format("%x", low))
  local nrThisTurn = lines - linesGlobal
  if nrThisTurn > 0 then
    game:addClear(nrThisTurn)
    linesGlobal = lines
  end
  return nrThisTurn
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
  if hasTetriminoLockedThisFrame() then
    game:addTetrimino({[getGameFrame()] = nt})
    local drought = game.drought:endTurn(linesClearedThisTurn(), readBoard():isTetrisReady(), at)
    local droughtLength = drought["drought"]
    local pauseLength = drought["paused"]

    --print(droughtLength,  pauseLength)

    -- Write drought counter to NES RAM so that it can be displayed.
    memory.writebyte(0x03fe, droughtLength);
    local droughtLengthDecimal = math.floor(droughtLength / 10) * 16 + (droughtLength % 10);
    memory.writebyte(0x03ff, droughtLengthDecimal);

    -- bcd not needed here, because it's just being tested against 0 right now.
    memory.writebyte(0x03ee, pauseLength);

    --readBoard():dump()
    --print(getGameFrame(), "added tetrimino:", getTetriminoNameById(nt))
  end
end

function main()
  if isGameRunning() and game ~= nil then
    updateControllerInputs();
    updateTetriminos();
  end
  updateGameStateGlobals();
end

game                    = nil
currentInputs           = joypad.get(1)
gameStateGlobal         = getGameState()
playStateGlobal         = getPlayState()
currentTetriminoGlobal  = getTetrimino()
linesGlobal             = 0



--
---- Memory domains on NES:
---- WRAM, CHR, CIRAM (nametables), PRG ROM, PALRAM, OAM, System Bus, RAM
--
--local spriteHeight = 8
--
--local function setDomain( newDomain )
--  local previousDomain = memory.getcurrentmemorydomain()
--  memory.usememorydomain( newDomain )
--  return previousDomain
--end
--
--local function visualizeSprite( index )
--  local y    = memory.read_u8( 4 * index + 0 )
--  local tile = memory.read_u8( 4 * index + 1 )
--  local attr = memory.read_u8( 4 * index + 2 )
--  local x    = memory.read_u8( 4 * index + 3 )
--
--  -- \note QuickNes and NesHawk cores differ in the origin of
--  -- gui.drawRectangle (bug?)
--  -- local topScanline = nes.gettopscanline() -- QuickNES
--  local topScanline = 0 -- NesHawk
--
--  local kSpriteWidth  = 8
--
--  gui.drawRectangle(
--    x, y + 1 - topScanline,
--    kSpriteWidth - 1, spriteHeight - 1,
--    0xB0FF00FF -- ARGB
--  )
--end
--
--local function visualizeSprites()
--  local previousDomain = setDomain( "OAM" )
--
--  for i = 0, 63 do
--    visualizeSprite( i )
--  end
--
--  memory.usememorydomain( previousDomain )
--end
--
--local guid2000 = event.onmemorywrite ( function()
--  local previousDomain = setDomain( "System Bus" )
--
--  -- Rely on read-only PPU registers returning the previous value written
--  -- to any PPU register. There doesn't seem to be any other way to
--  -- get the written value in BizHawk.
--  -- http://forums.nesdev.com/viewtopic.php?p=153077#p153077
--  local reg2000 = memory.read_u8( 0x2000 )
--
--  spriteHeight = bit.check( reg2000, 5 ) and 16 or 8
--
--  memory.usememorydomain( previousDomain )
--end, 0x2000 )
--
---- QuickNES core doesn't support onmemorywrite(), returns zero GUID
--assert( guid2000 ~= "00000000-0000-0000-0000-000000000000",
--"couldn't set memory write hook (use NesHawk core)" )
--
--print( "hardware-sprite-visualizer loaded" )

-- the main loop. runs main function, advances frame, then loops.
while true do
  main()
  --what()
  --visualizeSprites()
  emu.frameadvance()
end

--boardGlobal = nil
--readBoard()
--
--function setUpBoardCallbacks()
--  print("setting up callbacks")
--  for r=0,19 do
--    for c=0,9 do
--      event.onmemorywrite(function()
--        if game ~= nil then
--          local addr = Addresses["Playfield"] + (10*r) + c
--          print(addr, memory.readbyte(addr))
--        end
--      end, addr)
--    end
--  end
--end
--
--setUpBoardCallbacks()

--
--
--
--function what()
--  ----ROM Write (Compare) - If the value at ROM address 0x8614 is ever 0xA5, it changes it to 0xA9.
--  ----memory.writebyte(Addresses["TetriminoID"], 2)
--  --if(memory.readbyte(0x8614) == 165) then
--  --  --print("hi", memory.readbyte(0x8614))
--  --  memory.writebyte(0x8614, 169)
--  --end
--  --print("hi", memory.readbyte(0x0059))
--  memory.writebyte(0x0059, 3)
--  memory.writebyte(0x0079, 3)
--
--end
--
--
--
--event.onmemorywrite ( function()
--  print(memory.readbyte(0x0059))
--  memory.writebyte(0x0059, 3)
--  if(memory.readbyte(0x8614) == 0xA5) then
--    --print("hi", memory.readbyte(0x8614))
--    memory.writebyte(0x8614, 0xA9)
--  end
--end, 0x0059)
--

