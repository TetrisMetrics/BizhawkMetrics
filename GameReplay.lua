require('Game')
require("helpers")
json  = require "json"

GameReplay = class(function(a, filename, startLevel, first, second, frames, tetriminos)
  a.filename        = filename
  a.startLevel      = startLevel
  a.firstTetrimino  = first
  a.secondTetrimino = second
  a.frames          = frames
  a.tetriminos      = tetriminos
end)

function gameReplayFromGame(game)
  return GameReplay(game.filename, game.startLevel, game.firstTetrimino, game.secondTetrimino, game.frames, game.tetriminos)
end

function gameReplayJsonObject(filename, j)
  return GameReplay(filename, j["startLevel"], j["firstTetrimino"], j["secondTetrimino"], j["frames"], j["tetriminos"])
end

function gameReplayFromJsonFile (filename)
  local f = io.open(filename, "r")
  io.input(f)
  local j = json.decode(io.read())
  io.close(f)
  return gameReplayJsonObject(filename, j)
end

function GameReplay:toJson()
  local t = {}
  t.startLevel      = self.startLevel
  t.firstTetrimino  = self.firstTetrimino
  t.secondTetrimino = self.secondTetrimino
  t.frames          = self.frames
  t.tetriminos      = self.tetriminos
  return json.encode(t)
end

function GameReplay:writeReplay()
  local f = io.open("replays/" .. self.filename, "w")
  f:write(self:toJson())
  f:flush()
  f:close()
end
