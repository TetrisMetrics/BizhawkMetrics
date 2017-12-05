
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

  local y2 = y1+20

  printMetric(gui,  0, "Singles:  ", game.singles)
  printMetric(gui, 10, "Doubles:  ", game.doubles)
  printMetric(gui, 20, "Triples:  ", game.triples)
  printMetric(gui, 30, "Tetrises: ", game.tetrises)

  gui.text(x1,y2+50,"AVERAGES:", "white", "black")

  printMetric(gui, 70,  "Cnversion: " , game:conversionRatio())
  printMetric(gui, 80,  "Clear:    "  , game:avgClear())
  printMetric(gui, 90,  "Accmdation:" , game:avgAccommodation())
  printMetric(gui, 100, "Max height:" , game:avgMaxHeight())
  printMetric(gui, 110, "Min height:" , game:avgMinHeight())
  printMetric(gui, 120, "Surplus: "   , game:avgSurplus())
  printMetric(gui, 130, "Drought: "   , game:avgDrought())
  printMetric(gui, 140, "Pause:  "    , game:avgPause())
  printMetric(gui, 150, "Readiness:"  , game:avgReadinessDistance())
  printMetric(gui, 160, "Presses: "   , game:avgPressesPerTetrimino())

  gui.drawrect(192,y2+60,192+30,y2+72,"black")
  gui.text(192,y2+62,"DAS:" .. memory.readbyte(0x0046), "white", dasBackgroundColor)
end

function printMetric(gui, yOffset,title,num)
  local x1 = 12
  local y2 = 43
  local numDisplay = ""
  if num ~= nil then numDisplay = round(num, 2) end
  gui.text(x1,y2+yOffset, title .. numDisplay, "white", "black")
end
