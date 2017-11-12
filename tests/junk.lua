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
