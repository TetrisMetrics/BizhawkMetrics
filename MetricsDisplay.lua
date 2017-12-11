
local displayMetrics = "yes" -- input.popup("Display Metrics?")

function printMetrics(gui, memory, game)

  if displayMetrics == "no" then return; end

  local red = "#a81605"

  gui.drawrect(5,20,85,215,"black", red)

  local x1 = 8
  local y1 = 23

  local das = memory.readbyte(0x0046)
  local dasBackgroundColor
  if das < 10 then dasBackgroundColor = red else dasBackgroundColor = "#207005" end
  --gui.text(x1,y1+0,"DAS:" .. memory.readbyte(0x0046), "white", dasBackgroundColor)
  gui.text(x1,y1+0,"Clears:", "white", "black")

  printMetric(gui, -10, "Singles:  ", game.singles)
  printMetric(gui, 00, "Doubles:  ", game.doubles)
  printMetric(gui, 10, "Triples:  ", game.triples)
  printMetric(gui, 20, "Tetrises: ", game.tetrises)

  gui.text(x1,y1+60,"Other Metrics:", "white", "black")
  printMetric(gui, 50, "Accmdation:" , game.accommodation)
  printMetric(gui, 60, "Readiness:"  , game.lastReadiness)
  printMetric(gui, 70, "Surplus: "   , game.lastSurplus)
  printMetric(gui, 80, "Slope: "     , game.slope)
  printMetric(gui, 90, "Bumpiness:"  , game.bumpiness)

  gui.text(x1,y1+130,"Averages:", "white", "black")
  printMetric(gui, 120, "Clear:"  , game:avgClear())
  printMetric(gui, 130, "Drought:", game:avgDrought())
  printMetric(gui, 140, "Pause:"  , game:avgPause())

  gui.drawrect(192,y1+70,192+30,y1+82,"black")
  gui.text(192,y1+72,"DAS:" .. memory.readbyte(0x0046), "white", dasBackgroundColor)
end

function printMetric(gui, yOffset,title,num)
  local x1 = 12
  local y2 = 43
  local numDisplay = ""
  if num ~= nil then numDisplay = round(num, 2) end
  gui.text(x1,y2+yOffset, title .. numDisplay, "white", "black")
end

function drawJoypad(gui, j)
  local x1 = 95
  local x2 = 104
  local y1 = 22
  local y2 = 32
  function xDiff(n) return 11 * n end

  local aBackground = j["A"]     and "pink" or "gray"
  local bBackground = j["B"]     and "pink" or "gray"
  local lBackground = j["left"]  and "pink" or "gray"
  local dBackground = j["down"]  and "pink" or "gray"
  local rBackground = j["right"] and "pink" or "gray"

  -- black background
  gui.drawrect(x1+xDiff(0),y1,x2+xDiff(4)+3,y2,"black")

  -- Boxes for all buttons
  gui.drawrect(x1+xDiff(0),y1,x2+xDiff(0),y2,lBackground)
  gui.drawrect(x1+xDiff(1),y1,x2+xDiff(1),y2,dBackground)
  gui.drawrect(x1+xDiff(2),y1,x2+xDiff(2),y2,rBackground)

  gui.drawrect(x1+xDiff(3)+1,y1,x2+xDiff(3)+1,y2,bBackground)
  gui.drawrect(x1+xDiff(4)+1,y1,x2+xDiff(4)+1,y2,aBackground)

  -- B, A
  gui.text(x1+xDiff(3)+3,y1+2,"B", "white", bBackground)
  gui.text(x1+xDiff(4)+3,y1+2,"A", "white", aBackground)

  -- left arrow
  gui.drawline(x1+2+xDiff(0),y1+5,x2-5+xDiff(0),y1+3,"white")
  gui.drawline(x1+2+xDiff(0),y1+5,x2-2+xDiff(0),y1+5,"white")
  gui.drawline(x1+2+xDiff(0),y1+5,x2-5+xDiff(0),y2-3,"white")

  -- down arrow
  gui.drawline(x1+5+xDiff(1),y2-2,x1+3+xDiff(1),y1+6,"white")
  gui.drawline(x1+5+xDiff(1),y1+2,x1+5+xDiff(1),y2-2,"white")
  gui.drawline(x1+5+xDiff(1),y2-2,x2-2+xDiff(1),y1+6,"white")

  -- right arrow
  gui.drawline(x2-2+xDiff(2),y1+5,x2-4+xDiff(2),y1+3,"white")
  gui.drawline(x1+2+xDiff(2),y1+5,x2-2+xDiff(2),y1+5,"white")
  gui.drawline(x2-2+xDiff(2),y1+5,x2-4+xDiff(2),y2-3,"white")
end

function displayDroughtOnNES(memory, drought)
  local droughtLength = drought["drought"]
  local pauseLength   = drought["paused"]

  -- Write drought counter to NES RAM so that it can be displayed.
  memory.writebyte(0x03fe, droughtLength);
  local droughtLengthDecimal = math.floor(droughtLength / 10) * 16 + (droughtLength % 10);
  memory.writebyte(0x03ff, droughtLengthDecimal);

  -- bcd not needed here, because it's just being tested against 0 right now.
  memory.writebyte(0x03ee, pauseLength);
end
