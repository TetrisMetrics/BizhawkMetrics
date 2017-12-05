---
--- Created by Joshua.
--- DateTime: 10/25/2017 8:05 PM
---

-- don't run this function, it just has dumb examples in it.
function misc()

  -- code to set current and next tetrimino to a "Down T" block
  memory.writebyte(Addresses["TetriminoID"], 2)
  memory.writebyte(Addresses["NextTetriminoID"], 2)

  -- press or let go of buttons on the controller.
  controller = {}

  -- code to randomly move right or left.
  if math.random() < .15 then
    if math.random() < .75 then
      controller["P1 Right"] = true
    else
      controller["P1 Left"] = true
    end
  end

  joypad.set(controller)


  -- register function to run when frame is done
  -- event.onframeend(ShowInputKeys)

  -- print a bunch of states, update global states
  if(getGameState() ~= gameStateGlobal) then
    print("changed gameStateGlobal from", gameStateGlobal, "to", getGameState())
    gameStateGlobal = getGameState()
  end

  --if(getPlayState() ~= playState) then
  --  print("changed playState from", playState, "to", getPlayState())
  --  playState = getPlayState()
  --end

  --if(getLevel() ~= level) then
  --  print("changed level from", level, "to", getLevel())
  --  level = getLevel()
  --end
end

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
--event.onmemorywrite ( function()
--  print(memory.readbyte(0x0059))
--  memory.writebyte(0x0059, 3)
--  if(memory.readbyte(0x8614) == 0xA5) then
--    --print("hi", memory.readbyte(0x8614))
--    memory.writebyte(0x8614, 0xA9)
--  end
--end, 0x0059)
--
--
--linesCleared = 0
--memory.registerwrite(0x0056, 1, function ()
--  local newVal = memory.readbyte(0x0056)
--  if newVal ~= linesCleared then
--    print(newVal)
--    linesCleared = newVal
--  end
--end)
