-- TETRIS

require("Board")
require("Drought")
require("helpers")
require("Game")
require("GameLoop")
require("GameReplay")
require("Memory")
require("MetricsDisplay")
require("Neat")
require("NintacoTetrisAI")

state_file = "tetris.state"
startCounter = 0
num_inputs = 205
max_nodes = 1000000
gain = 0
highest_fitness = 0
highest_distance = 0
global_max_fitness = 0
global_best_genome = new_genome()
replay_best_genome = false
not_advanced = 20
num_buttons = 5
global_innovation = 0
current_species = 0
population_size = 200
compatibility_threshold = 1.0
c1 = 1
c2 = 1
c3 = 1
mutate_weights_chance   = 0.25
weight_perturbation     = 2
-- must be at least one so all genomes have at least one gene
mutate_structure_chance = 1
add_node_chance         = 0.66
button_input_names = { "A", "B", "down", "left", "right" }

--myAi = newAI(2)

function normalize(n, min, max) return (n - min) / (max - min) end
function normalize_tetriminio_id(tid) return normalize(tid, 0,18) end
function normalize_x(x) return normalize(x, 0,9) end
function normalize_y(y) return normalize(y, 0,19) end
function normalize_level(l) return normalize(l, 0,29) end

function updateControllerInputs(game, board)
  local is = board:flatten()
  is[200] = normalize_tetriminio_id(readMemory("TetriminoID"))
  is[201] = normalize_tetriminio_id(readMemory("NextTetriminoID"))
  is[202] = normalize_x(readMemory("TetriminoX"))
  is[203] = normalize_y(readMemory("TetriminoY1"))
  is[204] = normalize_level(readMemory("Level"))
  local outputs = evaluate_network(current_network, is)
  joypad.write(1, outputs)
  --game:addFrame(emu.framecount(),joypad.get(1), joypad.get(1))
end

function calculateFitness(game, board)
  return readScore()
end

function updateFitness(game, board)
  local boardFitness = calculateFitness(game, board)
  local fitness = game.nrDrops * 100 + boardFitness

  print("updating fitness: ", fitness)

  local species = pop.species[pop.current_species]
  local genome = species.genomes[pop.current_genome]

  if fitness > highest_fitness then
    highest_fitness = fitness
    genome.fitness = round(highest_fitness)
  end

  if fitness > species.fitness then
    species.fitness = fitness
  end

  if fitness > global_max_fitness then
    global_max_fitness = highest_fitness
  end
end

function onStart(game)
  print("\n" .. "new game is starting on frame " .. emu.framecount() .. "\n")
  -- create a new organism here
  next_genome(pop,true)
  initialize_run(false)
end

function onEnd(game, board)
  --if game ~= nil then
  --  updateFitness(game, board)
  --end
end

function updateTetriminos(game)
  -- when a game first starts, the tetriminos are always set to 19 and 14.
  -- so we need to detect when this changes, and add the first tetriminos to the game.
  if (currentTetriminoGlobal == 19 and getTetrimino() ~= 19) then
    game:setInitialTetriminos(emu.framecount(), getTetrimino(), getNextTetrimino())
  end
end


function initialize_population()
  pop = new_pop(population_size)

  for i = 1, pop.size do
    local genome = new_genome()
    mutate(genome)
    speciate(genome)
  end

  next_genome(pop,false)
  initialize_run(false)
  create_backup("backup_"..state_file.."_gen_0.txt", global_best_genome, pop)
end

function initialize_run(best_run)
  --savestate.load(state_file)
  highest_fitness = 0
  highest_distance = 0
  gain = 0
  advanced = 0
  not_advanced = 20
  --clear_controller()
  local g = best_run and global_best_genome or pop.species[pop.current_species].genomes[pop.current_genome]
  current_network = create_network(g)
end

function main ()
  function everyFrame()
    local gameState = memory.readbyteunsigned(gameStateAddress)
    skipCopyrightScreen(gameState)
    skipTitleAndDemoScreens(gameState)
    resetPlayState(gameState)
    if not isPlaying(gameState) then pressStart()  end
  end

  initialize_population()
  loop(updateControllerInputs, updateTetriminos, onStart, onEnd, updateFitness, everyFrame)
end

main()
