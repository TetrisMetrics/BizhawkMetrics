
function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function new_pop(size)
  local pop = {}
  pop.size = size
  pop.species = {}
  pop.generation = 1
  pop.current_species = 1
  pop.current_genome = 0
  pop.member = 0
  pop.frame_count = -1
  return pop
end


function new_species()
  local species = {}
  species.genomes = {}
  species.fitness = 0
  species.last_fitness = 0
  species.improvement_age = 0
  return species
end

function new_genome()
  local genome = {}
  -- gonna try to do this with just one genes table,
  -- instead of nodes and connections
  genome.genes = {}
  -- keep track of how many nodes are in the network (not including outputs)
  genome.num_neurons = num_inputs
  genome.fitness = 0
  genome.shared_fitness = 0
  genome.network = {}
  genome.received_trial = false
  return genome
end


function new_gene(the_in, the_out, the_weight, the_enable, the_innovation)
  local gene = {}
  gene.in_node = the_in
  gene.out_node = the_out
  gene.weight = the_weight
  gene.enable = the_enable
  gene.innovation = the_innovation
  return gene
end

function copy_genome(genome)
  g2 = new_genome()
  for g = 1, #genome.genes do
    table.insert(g2.genes, copy_gene(genome.genes[g]))
  end
  g2.num_neurons = genome.num_neurons
  g2.fitness = genome.fitness
  g2.shared_fitness = genome.shared_fitness
  g2.received_trial = genome.received_trial
  return g2
end

function copy_gene(gene)
  local g2 = {}
  g2.in_node = gene.in_node
  g2.out_node = gene.out_node
  g2.weight = gene.weight
  g2.enable = gene.enable
  g2.innovation = gene.innovation
  return g2
end

function new_neuron(genome)
  genome.num_neurons = genome.num_neurons + 1
  return genome.num_neurons
end

function new_innovation(n1, n2)
  -- TODO check for existing innovation
  global_innovation = global_innovation + 1
  -- print(global_innovation)
  return global_innovation
end


function mutate(genome)
  -- can mutate each weight
  if math.random() < mutate_weights_chance then
    mutate_weights(genome)
  end

  -- structure mutations
  -- can add connection
  -- if math.random() <= mutate_structure_chance then
  for i = 1, math.random(1, 2) do
    add_connection(genome)
  end
  -- end

  -- can add node
  if math.random() < add_node_chance then
    for i = 1, math.random(1,1) do
      add_node(genome)
    end
  end

  -- enable / disable
  if math.random() < 0.5 then
    mutate_enable(genome)
  end
end


function mutate_weights(genome)
  -- mutate the weights
  for i = 1, #genome.genes do
    local n = math.random(-1,1)
    while n == 0 do
      n = math.random(-1,1)
    end
    genome.genes[i].weight = (
    genome.genes[i].weight + n * math.random() * weight_perturbation
    )
  end
end

function add_connection(genome)
  -- add a new connection gene with a random weight

  -- find two random neurons to connect, only one can be an input,
  -- and they cannot be connected already
  local n1
  local n2
  n1, n2 = two_random_neurons(genome)

  -- generate a new gene with random weight, and in and out neurons
  -- TODO check for existing innovation
  local new_gene = new_gene(
  n1, n2, -- in_node, out_node
  math.random(), -- weight
  true, -- enable bit
  new_innovation(n1, n2)
  )

  for k, gene in pairs(genome.genes) do
    if (gene.in_node == new_gene.in_node and
    gene.out_node == new_gene.out_node) then
      return  -- TODO make this work better so it just tries again
    end
  end

  table.insert(genome.genes, new_gene)
end

function add_node(genome)
  if #genome.genes == 0 then
    return
  end

  -- pick a connection to split
  local old_connection = genome.genes[math.random(1, #genome.genes)]
  old_connection.enable = false
  local n1 = old_connection.in_node
  local n2 = old_connection.out_node
  local new_node_id = new_neuron(genome)

  -- create two new connections
  local new_connection_1 = new_gene(n1, new_node_id,
  1.0,
  true,
  new_innovation(n1, new_node_id)
  )
  local new_connection_2 = new_gene(new_node_id, n2,
  old_connection.weight,
  true,
  new_innovation(new_node_id, n2)
  )
  genome.num_neurons = genome.num_neurons + 1
  table.insert(genome.genes, new_connection_1)
  table.insert(genome.genes, new_connection_2)
end

function mutate_enable(genome)
  for g = 1, #genome.genes do
    if math.random() < 0.3 then
      if genome.genes[g].enable then
        genome.genes[g].enable = false
      else
        genome.genes[g].enable = true
      end
    end
  end
end

function two_random_neurons(genome)
  local n1
  local n2

  local neurons = {}
  for i = 1, num_inputs do
    neurons[i] = true
  end
  for o = 1, num_buttons do
    neurons[max_nodes + o] = true
  end
  for i = 1, #genome.genes do
    if genome.genes[i].in_node > num_inputs then
      neurons[genome.genes[i].in_node] = true
    end
    if genome.genes[i].out_node > num_inputs then
      neurons[genome.genes[i].out_node] = true
    end
  end
  local num_neurons = 0
  for _,_ in pairs(neurons) do
    num_neurons = num_neurons + 1
  end

  -- choose if n2 will be output neuron or some other neuron
  if num_neurons - 9 > num_inputs then
    local excess_neurons = num_neurons - num_inputs - 9
    local rando = math.random()
    if rando < 0.33 then
      n1 = math.random(1, 144)
      n2 = math.random(145, 145 + excess_neurons)
    elseif rando > 0.33 and rando < 0.66 then
      n1 = math.random(145, 145 + excess_neurons)
      n2 = math.random(1000001, 1000009)
    else
      n1 = math.random(1, num_neurons - 9)
      n2 = math.random(1000001, 1000009)
    end
  else -- we don't have any other neurons but outputs
    n1 = math.random(1, num_neurons - 9)
    n2 = math.random(1000001, 1000009)
  end

  return n1, n2
end

function get_neurons(genome)
  local neurons = {}
  for i = 1, num_inputs do
    neurons[i] = true
  end
  for o = 1, num_buttons do
    neurons[max_nodes + o] = true
  end
  for i = 1, #genome.genes do
    if genome.genes[i].in_node > num_inputs then
      neurons[genome.genes[i].in_node] = true
    end
    if genome.genes[i].out_node > num_inputs then
      neurons[genome.genes[i].out_node] = true
    end
  end
  return neurons
end

function speciate(baby_genome)
  local matched_a_species = false
  local s = 0
  for i = 1, #pop.species do
    local genes1 = pop.species[i].genomes[1].genes
    local genes2 = baby_genome.genes
    if #genes2 < #genes1 then -- make sure the shorter genome is first
      genes1, genes2 = genes2, genes1
    end
    cd = compatibility_distance(genes1, genes2)
    if cd < compatibility_threshold then
      table.insert(pop.species[i].genomes, baby_genome)
      matched_a_species = true
      s = i
      break
    end
  end

  if not matched_a_species then
    local unique_species = new_species()
    table.insert(unique_species.genomes, baby_genome)
    table.insert(pop.species, unique_species)
  end
  return s
end


function copy_all_species()
  local species_copy = {}
  for s = 1, #pop.species do
    local species = new_species()
    for g = 1, #pop.species[s].genomes do
      table.insert(
      species.genomes, copy_genome(pop.species[s].genomes[g])
      )
    end
    table.insert(species_copy, species)
  end
  return species_copy
end

function compatibility_distance(genes1, genes2)
  local E = excess_genes(genes1, genes2)
  local D = disjoint_genes(genes1, genes2)
  local N = math.max(#genes1, #genes2)
  if N < 20 then N = 1 end
  local W = sum_of_weight_differences(genes1, genes2) / (
  #genes1 + #genes2 - E - D
  )
  return c1*E/N + c2*D/N + c3*W
end

function excess_genes(genes1, genes2)
  local excess = 0

  local highest_1 = 0
  for i = 1, #genes1 do
    if genes1[i].innovation > highest_1 then
      highest_1 = genes1[i].innovation
    end
  end

  local highest_2 = 0
  for i = 1, #genes2 do
    if genes2[i].innovation > highest_2 then
      highest_2 = genes2[i].innovation
    end
  end

  if highest_1 > highest_2 then
    for i = 1, #genes1 do
      if genes1[i].innovation > highest_2 then
        excess = excess + 1

      end
    end
  else
    for i = 1, #genes2 do
      if genes2[i].innovation > highest_1 then
        excess = excess + 1
      end
    end
  end

  return excess
end

function disjoint_genes(genes1, genes2)
  local disjoint = 0

  for i = 1, #genes1 do
    local found = false
    for j = 1, #genes2 do
      if genes1[i].innovation == genes2[j].innovation then
        found = true
        break
      end
    end
    if not found then
      disjoint = disjoint + 1
    end
  end

  for i = 1, #genes2 do
    local found = false
    for j = 1, #genes1 do
      if genes2[i].innovation == genes2[j].innovation then
        found = true
        break
      end
    end
    if not found then
      disjoint = disjoint + 1
    end
  end

  return disjoint
end

function sum_of_weight_differences(genes1, genes2)
  local sum_of_differences = 0

  for i = 1, #genes1 do
    for j = 1, #genes1 do
      if genes1[i].innovation == genes2[j].innovation then
        sum_of_differences = sum_of_differences + math.abs(
        genes1[i].weight - genes2[j].weight
        )
      end
    end
  end

  return sum_of_differences
end


function remove_under_performers()
  for s = 1, #old_pop.species do
    table.sort(old_pop.species[s].genomes, function(a,b)
      return (a.fitness > b.fitness)
    end)
    -- retain the top 20% to be parents
    local stop = round(#old_pop.species[s].genomes * 0.2)
    if stop < 2 then stop = 2 end
    for g = #old_pop.species[s].genomes, stop, -1 do
      table.remove(old_pop.species[s].genomes)
    end
  end
end

function remove_non_improvers()
  -- drop species that haven't received an improved fitness in 4 generations
  local not_killed_off = {}

  for s = 1, #old_pop.species do
    if old_pop.species[s].fitness > old_pop.species[s].last_fitness then
      old_pop.species[s].last_fitness = old_pop.species[s].fitness
      old_pop.species[s].improvement_age = 0
    else
      old_pop.species[
      s
      ].improvement_age = old_pop.species[s].improvement_age + 1
    end

    if old_pop.species[s].improvement_age < 30 or
    old_pop.species[s].fitness >= global_max_fitness then
      table.insert(not_killed_off, old_pop.species[s])
    end
  end

  old_pop.species = not_killed_off
end

function adjust_fitnesses()
  for s = 1, #old_pop.species do
    for g = 1, #old_pop.species[s].genomes do
      local species = old_pop.species[s]
      local genome = species.genomes[g]
      genome.fitness = genome.fitness / #species.genomes
    end
  end
end

function calculate_average_fitness()
  local sum = 0
  for s = 1, #old_pop.species do
    for g = 1, #old_pop.species[s].genomes do
      sum = sum + old_pop.species[s].genomes[g].fitness
    end
  end
  return sum / population_size
end

function calculate_spawn_levels()
  local spawn_total = 0 -- debug
  local average_fitness = calculate_average_fitness()
  for s = 1, #old_pop.species do
    local species = old_pop.species[s]
    species.spawn_number = 0
    for g = 1, #old_pop.species[s].genomes do
      local genome = species.genomes[g]
      genome.spawn_number = genome.fitness / average_fitness
      species.spawn_number = species.spawn_number + genome.spawn_number
    end
    species.spawn_number = round(species.spawn_number)
    if species.spawn_number > 0 then
      print('species spawn number: '..species.spawn_number) -- debug
    end
    spawn_total = spawn_total + species.spawn_number -- debug
  end
  print('spawn total: '..spawn_total) -- debug
end

function contains_innovation(genes, i)
  for g = 1, #genes do
    if genes[g].innovation == i then return true end
  end
  return false
end

function cross_over(g1, g2)
  local baby = new_genome()
  for g = 1, #g1.genes do
    if not contains_innovation(baby.genes, g1.genes[g].innovation) then
      table.insert(baby.genes, copy_gene(g1.genes[g]))
    end
  end
  for g = 1, #g2.genes do
    if not contains_innovation(baby.genes, g2.genes[g].innovation) then
      table.insert(baby.genes, copy_gene(g2.genes[g]))
    end
  end
  baby.num_neurons = math.max(g1.num_neurons, g2.num_neurons)
  return baby
end

function current_pop_size()
  local size = 0
  for s = 1, #pop.species do
    for g = 1, #pop.species[s].genomes do
      size = size + 1
    end
  end
  return size
end

function make_babies(pop, old_pop)
  pop.species = {}

  -- put the best genome in the population without mutation
  speciate(global_best_genome)

  for s = 1, #old_pop.species do
    local chosen_best_yet = false
    local species = old_pop.species[s]

    while species.spawn_number >= 1 and current_pop_size() < population_size do

      if not chosen_best_yet then
        -- put the best genome in the new pop first for per
        -- species elitism (Ai book, page 395)
        local best_in_species = {}
        best_in_species.fitness = 0
        for i = 1, #species.genomes do
          if species.genomes[i].fitness > best_in_species.fitness then
            best_in_species = species.genomes[i]
          end
        end
        speciate(best_in_species)
        chosen_best_yet = true
      else
        -- only one genome in this species, so just mutate
        if #species.genomes == 1 then
          local baby = copy_genome(species.genomes[1])
          mutate(baby)
          baby.received_trial = false
          speciate(baby)
          -- enough genomes to have parents
        elseif #species.genomes > 1 then
          if math.random() < 0.8 then -- crossover chance
            local g1_i = math.random(1, #species.genomes)
            local g2_i = math.random(1, #species.genomes)
            local number_of_attempts = 5
            while g1_i == g2_i and number_of_attempts > 0 do
              g2_i = math.random(1, #species.genomes)
              number_of_attempts = number_of_attempts - 1
            end
            local baby = {}
            if g1_i ~= g2_i then
              local genome_1 = species.genomes[g1_i]
              local genome_2 = species.genomes[g2_i]
              baby = cross_over(genome_1, genome_2)
              mutate(baby)
              speciate(baby)
            else
              baby = species.genomes[g1_i]
              mutate(baby)
              speciate(baby)
            end -- if we have two different genomes
          end -- crossover chance
        end -- if 1 or more
      end -- if chosen best
      species.spawn_number = species.spawn_number - 1
    end -- end while
  end -- next species

  -- make sure the population is full
  -- TODO force this to choose from genomes that have a fitness above zero
  local i = 0
  while current_pop_size() < population_size do
    i = i + 1
    local k = 10
    local r_species
    local r_genome
    local winner = new_genome()
    winner.fitness = 0
    for j = 1, k do
      r_species = old_pop.species[math.random(1, #old_pop.species)]
      r_genome = copy_genome(
      r_species.genomes[math.random(1, #r_species.genomes)]
      )
      if r_genome.fitness > winner.fitness then
        winner = r_genome
      end
    end
    mutate(winner)
    winner.received_trial = false
    speciate(winner)
  end
  if i > 0 then print("fill: "..i) end
end

function new_generation(pop)
  -- print('new_generation()')
  create_backup("backup_"..state_file.."_gen_"..pop.generation..".txt", global_best_genome, pop)

  math.randomseed(os.time())

  pop.current_species = 1
  pop.member = 1
  pop.generation = pop.generation + 1

  old_pop = {}
  old_pop.species = copy_all_species(pop.species)

  remove_under_performers()
  remove_non_improvers()
  adjust_fitnesses()
  calculate_spawn_levels()
  make_babies(pop, old_pop)
end

function next_genome(pop, check_for_best)
  local genome = pop.species[pop.current_species].genomes[pop.current_genome]

  if check_for_best and genome.fitness > global_best_genome.fitness then
    global_best_genome = copy_genome(genome)
    create_backup( -- the save button is kind of obsolete when this is here
    state_file.."_"..pop.generation.."_"..pop.current_species.."_"
    ..pop.current_genome.."_best.txt", global_best_genome, pop
    )
  end

  if pop.generation > 1 and pop.member % 5 == 0 then
    create_backup(state_file.."_frequent_backup.txt", global_best_genome, pop)
  end

  -- go to next genome, species, or generation
  pop.member = pop.member + 1
  pop.current_genome = pop.current_genome + 1
  if pop.current_genome > #pop.species[pop.current_species].genomes then
    pop.current_genome = 1
    pop.current_species = pop.current_species + 1
    if pop.current_species > #pop.species then
      new_generation(pop)
    end
  end
end

function new_node()
  local node = {}
  node.connection_genes = {}
  node.value = 0.0
  return node
end

function create_network(genome)
  local network = {}
  network.nodes = {}

  -- create input nodes
  for i = 1, num_inputs do
    network.nodes[i] = new_node()
  end

  -- create output nodes
  for o = 1, num_buttons do
    network.nodes[max_nodes + o] = new_node()
  end
  -- console.clear()
  table.sort(genome.genes, function (a,b)
    return a.out_node < b.out_node
  end)
  -- create nodes from genes, if they don't exist yet
  for g = 1, #genome.genes do
    local gene = genome.genes[g]
    -- print(gene)
    if gene.enable then
      -- does this gene's out node exist?
      if network.nodes[gene.out_node] == nil then
        network.nodes[gene.out_node] = new_node()
      end
      -- put this gene into it's out_node's connection_genes table so we
      -- know the weights and the values
      local node = network.nodes[gene.out_node]
      table.insert(node.connection_genes, gene)
      -- does this gene's in_node exist?
      if network.nodes[gene.in_node] == nil then
        network.nodes[gene.in_node] = new_node()
      end
    end
  end

  return network
end

function sigmoid(x)
  return 2 / (1 + math.exp(-x))
end

function evaluate_network(current_network, inputs)
  local outputs = {}

  for i = 1, num_inputs - 1 do
    current_network.nodes[i].value = inputs[i]
  end

  for i, node in pairs(current_network.nodes) do
    local sum = 0
    for g = 1, #node.connection_genes do
      local connection = node.connection_genes[g]
      local in_value = current_network.nodes[connection.in_node].value
      sum = sum + connection.weight * in_value
    end

    if #node.connection_genes > 0 then
      node.value = sigmoid(sum)
    end
  end

  for o = 1, num_buttons do
    local button = button_input_names[o]
    if current_network.nodes[max_nodes + o].value > 1 then
      outputs[button] = true
    else
      outputs[button] = false
    end
  end

  return outputs
end


function create_backup(file_name, global_best_genome, pop)
  local file = assert(io.open(file_name, "w"))

  -- first save the best genome
  file:write(global_best_genome.fitness.." ")
  file:write(global_best_genome.num_neurons.." ")
  file:write(#global_best_genome.genes.. "\n")
  for g, gene in pairs(global_best_genome.genes) do
    file:write(gene.in_node.." ")
    file:write(gene.out_node.." ")
    file:write(gene.weight.." ")
    file:write(gene.innovation.." ")
    if gene.enable then
      file:write("1\n")
    else
      file:write("0\n")
    end
  end

  -- then save the entire population
  file:write(pop.generation.." ")
  file:write(global_max_fitness.." ")
  file:write(#pop.species.."\n")
  for s, species in pairs(pop.species) do
    file:write(species.fitness.." ")
    file:write(species.improvement_age.." ")
    file:write(#species.genomes.."\n")
    for g, genome in pairs(species.genomes) do
      file:write(genome.fitness.." ")
      file:write(genome.num_neurons.." ")
      if genome.received_trial then
        file:write("1 ")
      else
        file:write("0 ")
      end
      file:write(#genome.genes.."\n")
      for h, gene in pairs(genome.genes) do
        file:write(gene.in_node.." ")
        file:write(gene.out_node.." ")
        file:write(gene.weight.." ")
        file:write(gene.innovation.." ")
        if gene.enable then
          file:write("1\n")
        else
          file:write("0\n")
        end
      end
    end
  end

  file:close()
end

function load_backup(file_name)
  local file = assert(io.open(file_name, "r"))

  -- first read the best genome
  global_best_genome = {}
  global_best_genome = new_genome()
  local num_genes = 0
  global_best_genome.fitness,
  global_best_genome.num_neurons,
  num_genes = file:read("*number", "*number", "*number")
  for g = 1, num_genes do
    local genes = new_gene()
    table.insert(global_best_genome.genes, genes)
    genes.in_node,
    genes.out_node,
    genes.weight,
    genes.innovation,
    genes.enable = file:read(
    "*number", "*number", "*number", "*number", "*number"
    )
    if genes.enable == 1 then
      genes.enable = true
    else
      genes.enable = false
    end
  end

  -- then read the rest of the population
  pop = new_pop(population_size)
  local num_species
  pop.generation,
  global_max_fitness,
  num_species = file:read("*number", "*number", "*number")
  for s = 1, num_species do
    local species = new_species()
    table.insert(pop.species, species)
    local num_genomes
    species.fitness,
    species.improvement_age,
    num_genomes = file:read("*number", "*number", "*number")
    for g = 1, num_genomes do
      local genome = new_genome()
      table.insert(species.genomes, genome)
      local received_trial
      genome.fitness,
      genome.num_neurons,
      received_trial,
      num_genes = file:read(
      "*number", "*number", "*number", "*number"
      )
      if received_trial == 1 then
        genome.received_trial = true
      else
        genome.received_trial = false
      end
      for h = 1, num_genes do
        local gene = new_gene()
        table.insert(genome.genes, gene)
        gene.in_node,
        gene.out_node,
        gene.weight,
        gene.innovation,
        gene.enable = file:read(
        "*number", "*number", "*number", "*number", "*number"
        )
        if gene.enable == 1 then
          gene.enable = true
        else
          gene.enable = false
        end
      end -- end gene loop
    end -- end genome loop
  end -- end species loop

  file:close()

  -- we need to advance to the genome we were on when we saved this file
  pop.current_species = 1
  pop.current_genome = 1
  pop.member = 1
  local received_trial = true
  while received_trial do
    next_genome(pop,false)
    local species = pop.species[pop.current_species]
    local genome = species.genomes[pop.current_genome]
    received_trial = genome.received_trial
  end

  initialize_run(false)
end
