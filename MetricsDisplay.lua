
local displayMetrics = "yes" -- input.popup("Display Metrics?")

function toPercent(n)
  local _n = n *100
  return _n % 1 >= 0.5 and math.ceil(_n) or math.floor(_n)
end

function stepDown(offs, len)
  offs.y = offs.y + (len and len or 10)
end

function printMetrics(gui, memory, game)

  if displayMetrics == "no" then return; end

  local red = "#a81605"

  local x1 = 8
  local y1 = 20

  gui.drawrect(5,10,85,225,"black", red)


  local das = memory.readbyte(0x0046)
  local dasBackgroundColor
  if das < 10 then dasBackgroundColor = red else dasBackgroundColor = "#207005" end
  --gui.text(x1,y1+0,"DAS:" .. memory.readbyte(0x0046), "white", dasBackgroundColor)
  --
  --
  gui.text(x1,y1+0,"Clears:", "white", "black")

  local offs = {}
  offs.x = 15
  offs.y = y1 + 10

  printMetric(gui, offs, "Singles:  ", game.singles)
  printMetric(gui, offs, "Doubles:  ", game.doubles)
  printMetric(gui, offs, "Triples:  ", game.triples)
  printMetric(gui, offs, "Tetrises: ", game.tetrises)

  stepDown(offs, 5)
  gui.text(x1,offs.y, "Other Metrics:", "white", "black")
  stepDown(offs)
  printMetric(gui, offs, "Accmdation:" , game.accommodation)
  printMetric(gui, offs, "Readiness:"  , game.lastReadiness)
  printMetric(gui, offs, "Surplus: "   , game.lastSurplus)
  printMetric(gui, offs, "Slope: "     , game.slope)
  printMetric(gui, offs, "Bumpiness:"  , game.bumpiness)

  stepDown(offs, 5)
  gui.text(x1,offs.y,"Droughts:", "white", "black")
  stepDown(offs)
  printMetric(gui, offs, "Current:"    , game.droughtCounter)
  printMetric(gui, offs, "Max:"    , game.droughtMax)
  printMetric(gui, offs, "Avg:"    , game.droughtAvg)


  stepDown(offs, 5)
  gui.text(x1,offs.y,"Averages:", "white", "black")
  stepDown(offs)
  printMetric(gui, offs, "TetrisRate:"  , toPercent(game.tetrisRate), "%")
  printMetric(gui, offs, "Clear:"  , game:avgClear())
  printMetric(gui, offs, "Pause:"  , game:avgPause())

  gui.drawrect(192,y1+70,192+30,y1+82,"black")

  gui.text(192,y1+72,"DAS:" .. memory.readbyte(0x0046), "white", dasBackgroundColor)
end

function printMetric(gui, offs,title,num, suffix)
  local numDisplay = ""
  if num ~= nil then numDisplay = round(num, 2) end
  gui.text(offs.x,offs.y, title .. numDisplay .. (suffix or ""), "white", "black")
  stepDown(offs)
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
  local pauseLength   = drought["pauseTime"]

  -- Write drought counter to NES RAM so that it can be displayed.
  memory.writebyte(0x03fe, droughtLength);
  local droughtLengthDecimal = math.floor(droughtLength / 10) * 16 + (droughtLength % 10);
  memory.writebyte(0x03ff, droughtLengthDecimal);

  -- bcd not needed here, because it's just being tested against 0 right now.
  memory.writebyte(0x03ee, pauseLength);
end
