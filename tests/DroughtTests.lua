---
--- Created by josh.
--- DateTime: 11/4/17 10:06 AM
---

require("Drought")

-- just a test function
function test()
  d = Drought(18)
  d:endTurn(0, true,  18)
  d:endTurn(4, false, 2)
  d:endTurn(2, false, 2)
  d:endTurn(1, false, 2)
  d:endTurn(1, true,  18)
  d:endTurn(4, true,  7)
  d:endTurn(1, false, 2)
  d:endTurn(1, false, 2)
  d:endTurn(1, false, 11)
  print(tableToString(d))
end
