--[[

Nintendo Tetris AI
Copyright (C) 2014 meatfighter.com

This file is part of Nintendo Tetris AI.

Nintendo Tetris AI is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

Nintendo Tetris AI is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

]]

-- This Lua script works with FCEUX 2.2.2 and Nintendo Tetris (USA version).

PLAY_FAST = false  -- disables drop movements

PLAYFIELD_WIDTH = 10
PLAYFIELD_HEIGHT = 20
TETRIMINOS_SEARCHED = 2

Tetriminos = {

  NONE = -1,
  T = 1,
  J = 2,
  Z = 3,
  O = 4,
  S = 5,
  L = 6,
  I = 7,

  ORIENTATIONS = { },
  TYPES = { }
}

globalMark = 1

function newQueue()

  local self = {
    enqueue = nil,
    dequeue = nil,
    isEmpty = nil,
    isNotEmpty = nil,
  }

  local head = nil
  local tail = nil

  function self.enqueue(state)
    if head == nil then
      head = state
      tail = state
    else
      tail.nextState = state
      tail = state
    end
    state.nextState = nil
  end

  function self.dequeue()
    local state = head
    if head ~= nil then
      if head == tail then
        head = nil
        tail = nil
      else
        head = head.nextState
      end
    end
    return state
  end

  function self.isEmpty()
    return head == nil
  end

  function self.isNotEmpty()
    return head ~= nil
  end

  return self
end

function newSearcher(searchListener)

  local self = {
    search = nil
  }

  local states = { }
  local queue = newQueue()

  local createStates = nil
  local lockTetrimino = nil
  local addChild = nil

  function createStates()
    for y = 1, PLAYFIELD_HEIGHT do
      states[y] = { }
      for x = 1, PLAYFIELD_WIDTH do
        states[y][x] = { }
        for rotation = 1, 4 do
          states[y][x][rotation] = {
            y = y,
            x = x,
            rotation = rotation,
            visited = 0,
            predecessor = nil,
            nextState = nil,
          }
        end
      end
    end
  end

  function lockTetrimino(playfield, tetriminoType, id, state)
    local squares = Tetriminos.ORIENTATIONS[tetriminoType][state.rotation]
    .squares
    for i = 1, 4 do
      local square = squares[i]
      local y = state.y + square.y
      if y >= 1 then
        playfield[y][state.x + square.x] = tetriminoType
        playfield[y][PLAYFIELD_WIDTH + 1]
        = playfield[y][PLAYFIELD_WIDTH + 1] + 1
      end
    end
    searchListener(playfield, tetriminoType, id, state)
    for i = 1, 4 do
      local square = squares[i]
      local y = state.y + square.y
      if y >= 1 then
        playfield[y][state.x + square.x] = Tetriminos.NONE
        playfield[y][PLAYFIELD_WIDTH + 1]
        = playfield[y][PLAYFIELD_WIDTH + 1] - 1
      end
    end
  end

  -- returns true if the position is valid even if the state is not enqueued
  function addChild(playfield, tetriminoType, mark, state, x, y, rotation)

    local orientation = Tetriminos.ORIENTATIONS[tetriminoType][rotation]
    if x < orientation.minX or x > orientation.maxX or y > orientation.maxY then
      return false
    end

    local childState = states[y][x][rotation];
    if childState.visited == mark then
      return true
    end

    local squares = orientation.squares
    for i = 1, 4 do
      local square = squares[i]
      local playfieldY = y + square.y
      if playfieldY >= 1
      and playfield[playfieldY][x + square.x] ~= Tetriminos.NONE then
        return false
      end
    end

    childState.visited = mark
    childState.predecessor = state

    queue.enqueue(childState)
    return true
  end

  function self.search(playfield, tetriminoType, id)

    local maxRotation = #Tetriminos.ORIENTATIONS[tetriminoType]

    local mark = globalMark
    globalMark = globalMark + 1

    if not addChild(playfield, tetriminoType, mark, nil, 6, 1, 1) then
      return false
    end

    while queue.isNotEmpty() do
      local state = queue.dequeue()

      if maxRotation ~= 1 then
        addChild(playfield, tetriminoType, mark, state, state.x, state.y,
        state.rotation == 1 and maxRotation or state.rotation - 1)
        if maxRotation ~= 2 then
          addChild(playfield, tetriminoType, mark, state, state.x, state.y,
          state.rotation == maxRotation and 1 or state.rotation + 1)
        end
      end

      addChild(playfield, tetriminoType, mark, state, state.x - 1, state.y, state.rotation)
      addChild(playfield, tetriminoType, mark, state, state.x + 1, state.y, state.rotation)

      if not addChild(playfield, tetriminoType, mark, state, state.x, state.y + 1, state.rotation) then
        lockTetrimino(playfield, tetriminoType, id, state)
      end
    end

    return true
  end

  createStates()

  return self
end

function newPlayfieldUtil()

  local self = {
    clearRows = nil,
    restoreRows = nil,
    evaluatePlayfield = nil,
  }

  local spareRows = { }
  local spareIndex = 1
  local columnDepths = { }

  local clearRow = nil
  local restoreRow = nil

  function clearRow(playfield, y)
    local clearedRow = playfield[y]
    clearedRow[PLAYFIELD_WIDTH + 1] = y;
    for i = y, 2, -1 do
      playfield[i] = playfield[i - 1]
    end
    playfield[1] = spareRows[spareIndex]
    playfield[1][PLAYFIELD_WIDTH + 1] = 0

    spareRows[spareIndex] = clearedRow
    spareIndex = spareIndex + 1
  end

  function restoreRow(playfield)
    spareIndex = spareIndex - 1
    local restoredRow = spareRows[spareIndex]
    local y = restoredRow[PLAYFIELD_WIDTH + 1]

    spareRows[spareIndex] = playfield[1]
    for i = 1, y - 1 do
      playfield[i] = playfield[i + 1]
    end
    restoredRow[PLAYFIELD_WIDTH + 1] = PLAYFIELD_WIDTH
    playfield[y] = restoredRow
  end

  function self.evaluatePlayfield(playfield, e)

    for x = 1, PLAYFIELD_WIDTH do
      for y = 1, PLAYFIELD_HEIGHT do
        if y == PLAYFIELD_HEIGHT or playfield[y][x] ~= Tetriminos.NONE then
          columnDepths[x] = y
          break
        end
      end
    end

    e.wells = 0
    for x = 1, PLAYFIELD_WIDTH do
      local minY = 1
      if x == 1 then
        minY = columnDepths[2]
      elseif x == PLAYFIELD_WIDTH then
        minY = columnDepths[PLAYFIELD_WIDTH - 1]
      else
        minY = math.max(columnDepths[x - 1],
        columnDepths[x + 1])
      end
      for y = columnDepths[x], minY, -1 do
        if (x == 1 or playfield[y][x - 1] ~= Tetriminos.NONE)
        and (x == PLAYFIELD_WIDTH
        or playfield[y][x + 1] ~= Tetriminos.NONE) then
          e.wells = e.wells + 1
        end
      end
    end

    e.holes = 0
    e.columnTransitions = 0
    for x = 1, PLAYFIELD_WIDTH do
      local solid = true
      for y = columnDepths[x] + 1, PLAYFIELD_HEIGHT do
        if playfield[y][x] == Tetriminos.NONE then
          if playfield[y - 1][x] ~= Tetriminos.NONE then
            e.holes = e.holes + 1
          end
          if solid then
            solid = false
            e.columnTransitions = e.columnTransitions + 1
          end
        elseif not solid then
          solid = true
          e.columnTransitions = e.columnTransitions + 1
        end
      end
    end

    e.rowTransitions = 0
    for y = 1, PLAYFIELD_HEIGHT do
      local solidFound = false
      local solid = true
      local transitions = 0
      for x = 1, PLAYFIELD_WIDTH + 1 do
        if x == PLAYFIELD_WIDTH + 1 then
          if not solid then
            transitions = transitions + 1
          end
        elseif playfield[y][x] == Tetriminos.NONE then
          if solid then
            solid = false
            transitions = transitions + 1
          end
        else
          solidFound = true
          if not solid then
            solid = true
            transitions = transitions + 1
          end
        end
      end
      if solidFound then
        e.rowTransitions = e.rowTransitions + transitions
      end
    end
  end

  function self.restoreRows(playfield, rows)
    for i = 1, rows do
      restoreRow(playfield)
    end
  end

  function self.clearRows(playfield, tetriminoY)

    local rows = 0
    local startRow = tetriminoY - 2
    local endRow = tetriminoY + 1

    if startRow < 2 then
      startRow = 2
    end
    if endRow > 20 then
      endRow = 20
    end

    for y = startRow, endRow do
      if playfield[y][PLAYFIELD_WIDTH + 1] == PLAYFIELD_WIDTH then
        rows = rows + 1
        clearRow(playfield, y)
      end
    end

    return rows
  end

  for y = 1, 8 * TETRIMINOS_SEARCHED do
    spareRows[y] = { }
    for x = 1, PLAYFIELD_WIDTH do
      spareRows[y][x] = Tetriminos.NONE
    end
    spareRows[y][PLAYFIELD_WIDTH + 1] = 0
  end

  for i = 1, PLAYFIELD_WIDTH do
    columnDepths[i] = 0
  end

  return self
end

function newPlayfieldEvaluation()
  return {
    holes = 0,
    columnTransitions = 0,
    rowTransitions = 0,
    wells = 0,
  }
end

function newAI(tetriminos)

  local WEIGHTS = {
    1.0,
    12.885008263218383,
    15.842707182438396,
    26.89449650779595,
    27.616914062397015,
    30.18511071927904,
  }

  local self = {
    search = nil,
  }

  local searchers = { }
  local tetriminoIndices = { }
  local playfieldUtil = newPlayfieldUtil()
  local e = newPlayfieldEvaluation()
  local totalRows = 0
  local totalDropHeight = 0
  local bestResult = nil
  local bestFitness = 0
  local result1 = nil

  local computeFitness = nil
  local handleResult = nil

  function computeFitness()
    return WEIGHTS[1] * totalRows
    + WEIGHTS[2] * totalDropHeight
    + WEIGHTS[3] * e.wells
    + WEIGHTS[4] * e.holes
    + WEIGHTS[5] * e.columnTransitions
    + WEIGHTS[6] * e.rowTransitions
  end

  function handleResult(playfield, tetriminoType, id, state)

    if id == 1 then
      result1 = state
    end

    local orientation = Tetriminos.ORIENTATIONS[tetriminoType][state.rotation]
    local rows = playfieldUtil.clearRows(playfield, state.y)
    local originalTotalRows = totalRows
    local originalTotalDropHeight = totalDropHeight
    totalRows = totalRows + rows
    totalDropHeight = totalDropHeight + orientation.maxY - state.y

    local nextID = id + 1

    if nextID == #tetriminoIndices + 1 then
      playfieldUtil.evaluatePlayfield(playfield, e)
      local fitness = computeFitness()
      if fitness < bestFitness then
        bestFitness = fitness
        bestResult = result1
      end
    else
      searchers[nextID].search(playfield, tetriminoIndices[nextID], nextID)
    end

    totalDropHeight = originalTotalDropHeight
    totalRows = originalTotalRows
    playfieldUtil.restoreRows(playfield, rows)
  end

  function self.search(playfield, _tetriminoIndices)

    tetriminoIndices = _tetriminoIndices
    bestResult = nil
    bestFitness = 1000000000

    searchers[1].search(playfield, tetriminoIndices[1], 1)

    return bestResult
  end

  for i = 1, tetriminos do
    searchers[i] = newSearcher(handleResult)
  end

  self.computeFitness = computeFitness

  return self
end

function createEmptyPlayfield()
  local playfield = { }
  for y = 1, PLAYFIELD_HEIGHT do
    playfield[y] = { }
    for x = 1, PLAYFIELD_WIDTH do
      playfield[y][x] = Tetriminos.NONE
    end
    playfield[y][PLAYFIELD_WIDTH + 1] = 0
  end
  return playfield
end

-- FCEUX code starts

orientationTableAddress = 0x8A9C
tetriminoTypeTableAddress = 0x993B
spawnTableAddress = 0x9956
copyrightAddress1 = 0x00C3
copyrightAddress2 = 0x00A8
gameStateAddress = 0x00C0
playStateAddress = 0x0048
lowCounterAddress = 0x00B1
highCounterAddress = 0x00B2
tetriminoXAddress = 0x0060
tetriminoYAddress1 = 0x0061
tetriminoYAddress2 = 0x0041
tetriminoIDAddress = 0x0062
nextTetriminoIDAddress = 0x00BF
fallTimerAddress = 0x0065
playfieldAddress = 0x0400
levelAddress = 0x0064
levelTableAccessAddress = 0x9808
linesHighAddress = 0x0071
linesLowAddress = 0x0070
playStateAddress = 0x0068

emptySquare = 0xEF

lastPlayState = 8
targetTetriminoY = 0
maxScoreHit = false
startCounter = 0

function buildOrientationTable()
  for i = 1, 7 do
    Tetriminos.ORIENTATIONS[i] = { }
  end

  local spawnIndices = { }

  for orientationID = 0, 18 do

    local tetriminoType
    = memory.readbyteunsigned(tetriminoTypeTableAddress + orientationID) + 1
    table.insert(Tetriminos.TYPES, tetriminoType)

    local orientation = {
      orientationID = orientationID,
      squares = { },
      minX = 100,
      maxX = -100,
      maxY = -100,
    }
    table.insert(Tetriminos.ORIENTATIONS[tetriminoType], orientation)

    if orientationID
    == memory.readbyteunsigned(spawnTableAddress + orientationID) then
      table.insert(spawnIndices, #Tetriminos.ORIENTATIONS[tetriminoType])
    end

    for square = 0, 3 do
      local index = 12 * orientationID + 3 * square
      local x = memory.readbytesigned(orientationTableAddress + index + 2)
      local y = memory.readbytesigned(orientationTableAddress + index)
      table.insert(orientation.squares, { x = x, y = y })
      orientation.minX = math.min(orientation.minX, x)
      orientation.maxX = math.max(orientation.maxX, x)
      orientation.maxY = math.max(orientation.maxY, y)
    end

    orientation.minX = 1 - orientation.minX
    orientation.maxX = PLAYFIELD_WIDTH - orientation.maxX
    orientation.maxY = PLAYFIELD_HEIGHT - orientation.maxY
  end

  for i = 1, 7 do
    local orientations = Tetriminos.ORIENTATIONS[i]
    Tetriminos.ORIENTATIONS[i] = { }
    for j = 1, #orientations do
      table.insert(Tetriminos.ORIENTATIONS[i],
      orientations[((j + spawnIndices[i] - 2) % #orientations) + 1])
    end
  end
end

function pressStart()
  if startCounter == 0 then
    startCounter = 10
  end
  if startCounter >= 5 then
    joypad.set(1, { start = true })
  elseif startCounter < 5 then
    joypad.set(1, { start = false })
  end
  startCounter = startCounter - 1
end

function skipCopyrightScreen(gameState)
  local copyright1 = memory.readbyteunsigned(copyrightAddress1)
  local copyright2 = memory.readbyteunsigned(copyrightAddress2)

  if gameState == 0 then
    if copyright1 > 1 then
      memory.writebyte(copyrightAddress1, 0)
    elseif copyright2 > 2 then
      memory.writebyte(copyrightAddress2, 1)
    end
  end
end

function skipTitleAndDemoScreens(gameState)
  if gameState == 1 or gameState == 5 then
    pressStart()
  end
end

function spawned()
  local playState = memory.readbyteunsigned(playStateAddress)
  local tetriminoX = memory.readbyteunsigned(tetriminoXAddress)
  local tetriminoY = memory.readbyteunsigned(tetriminoYAddress1)
  local result = lastPlayState ~= 1 and playState == 1 and tetriminoX == 5
  and tetriminoY == 0
  lastPlayState = playState
  return result
end

function readPlayfield(playfield)
  for i = 0, 19 do
    playfield[i + 1][11] = 0
    for j = 0, 9 do
      if memory.readbyteunsigned(playfieldAddress + 10 * i + j) == emptySquare then
        playfield[i + 1][j + 1] = Tetriminos.NONE
      else
        playfield[i + 1][j + 1] = Tetriminos.I
        playfield[i + 1][11] = playfield[i + 1][11] + 1
      end
    end
  end
end

function readTetrimino()
  return Tetriminos.TYPES[memory.readbyteunsigned(tetriminoIDAddress) + 1]
end

function readNextTetrimino()
  return Tetriminos.TYPES[memory.readbyteunsigned(nextTetriminoIDAddress) + 1]
end

function resetPlayState(gameState)
  if gameState ~= 4 then
    memory.writebyte(playStateAddress, 0)
  end
end

function isPlaying(gameState)
  return gameState == 4 and memory.readbyteunsigned(playStateAddress) < 9
end

function search(tetriminos, playfield, ai)

  tetriminos[1] = readTetrimino()
  tetriminos[2] = readNextTetrimino()
  readPlayfield(playfield)

  local state = ai.search(playfield, tetriminos)

  local result = { }
  while state ~= nil do
    table.insert(result, 1, state)
    state = state.predecessor
  end

  return result
end

function tetriminoYUpdated1()
  tetriminoYUpdated(tetriminoYAddress1)
end

function tetriminoYUpdated2()
  tetriminoYUpdated(tetriminoYAddress2)
end

function tetriminoYUpdated(address)
  unregisterYUpdatedListeners()
  local tetriminoY = memory.readbyteunsigned(address)
  if tetriminoY == 0 then
    targetTetriminoY = 0
  elseif tetriminoY ~= targetTetriminoY then
    setTetriminoYAddress(address, targetTetriminoY)
  end
  registerYUpdatedListeners()
end

function setTetriminoYAddress(address, y)
  targetTetriminoY = y
  memory.writebyte(address, y)
end

function setTetriminoY(y)
  setTetriminoYAddress(tetriminoYAddress1, y)
end

function registerYUpdatedListeners()
  memory.registerwrite(tetriminoYAddress1, tetriminoYUpdated1)
  memory.registerwrite(tetriminoYAddress2, tetriminoYUpdated2)
end

function unregisterYUpdatedListeners()
  memory.registerwrite(tetriminoYAddress1, nil)
  memory.registerwrite(tetriminoYAddress2, nil)
end

function updateScore()
  -- cap the points multiplier at 30 to avoid the kill screen
  if memory.readbyteunsigned(0x00A8) > 30 then
    memory.writebyte(0x00A8, 30)
  end
end

function speedUpDrop()
  memory.setregister("x", 0x1E)
end

function setTetriminoYAddress(address, y)
  targetTetriminoY = y
  memory.writebyte(address, y)
end

function setTetriminoY(y)
  setTetriminoYAddress(tetriminoYAddress1, y)
  setTetriminoYAddress(tetriminoYAddress2, y)
end

function makeMove(tetriminoType, state, finalMove)
  if finalMove then
    memory.writebyte(0x006E, 0x03)
  end
  memory.writebyte(tetriminoXAddress, state.x - 1)
  setTetriminoY(state.y - 1)
  memory.writebyte(tetriminoIDAddress,
  Tetriminos.ORIENTATIONS[tetriminoType][state.rotation].orientationID)
end