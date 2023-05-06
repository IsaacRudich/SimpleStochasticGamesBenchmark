"""
    get_most_HK_iterations_max(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)

A heuristic method tries some intentional, and many random, seed strtageies for Hoffman-Karp looking for the longest runtime
Returns {Int} the largest number of iterations found

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
"""
function get_most_HK_iterations_max(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
    max_strat = generate_upwards_max_strategy(game)
    optimal_strategy, iterations = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer, logging_on = logging_on)
    longest_so_far = iterations

    max_strat = generate_downwards_max_strategy(game)
    optimal_strategy, iterations  = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer, logging_on = logging_on)
    longest_so_far = max(iterations,longest_so_far)

    max_strat = generate_inverse_max_strategy(game, optimal_strategy)
    optimal_strategy, iterations  = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer, logging_on = logging_on)
    longest_so_far = max(iterations,longest_so_far)

    for i in 1:attempts
        max_strat = generate_random_max_strategy(game)
        optimal_strategy, iterations  = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer, logging_on = logging_on)
        longest_so_far = max(iterations,longest_so_far)
    end

    return longest_so_far
end 

"""
    get_most_HK_iterations_min(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)

A heuristic method tries some intentional, and many random, seed strtageies for Hoffman-Karp looking for the longest runtime
Returns {Int} the largest number of iterations found

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
"""
function get_most_HK_iterations_min(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
    min_strat = generate_upwards_min_strategy(game)
    optimal_strategy, iterations = hoffman_karp_switch_min_nodes(game,min_strat, optimizer = optimizer, logging_on = logging_on)
    longest_so_far = iterations

    min_strat = generate_downwards_min_strategy(game)
    optimal_strategy, iterations  = hoffman_karp_switch_min_nodes(game,min_strat, optimizer = optimizer, logging_on = logging_on)
    longest_so_far = max(iterations,longest_so_far)

    min_strat = generate_inverse_min_strategy(game, optimal_strategy)
    optimal_strategy, iterations  = hoffman_karp_switch_min_nodes(game,min_strat, optimizer = optimizer, logging_on = logging_on)
    longest_so_far = max(iterations,longest_so_far)

    for i in 1:attempts
        min_strat = generate_random_min_strategy(game)
        optimal_strategy, iterations  = hoffman_karp_switch_min_nodes(game,min_strat, optimizer = optimizer, logging_on = logging_on)
        longest_so_far = max(iterations,longest_so_far)
    end

    return longest_so_far
end 

"""
    get_most_mod_HK_iterations_max(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)

A heuristic method tries many random seed strtageies for Mod Hoffman-Karp looking for the longest runtime
Returns {Int} the largest number of iterations found

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
"""
function get_most_mod_HK_iterations_max(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
    longest_so_far = 0

    for i in 1:attempts
        avg_node_order = generate_random_average_nodes_order(game)
        optimal_strategy, iterations = mod_hoffman_karp_switch_max_nodes(game, avg_node_order, optimizer=optimizer, logging_on=logging_on)
        longest_so_far = max(iterations,longest_so_far)
    end

    return longest_so_far
end 

"""
    get_most_mod_HK_iterations_min(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)

A heuristic method tries many random seed strtageies for Mod Hoffman-Karp looking for the longest runtime
Returns {Int} the largest number of iterations found

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
"""
function get_most_mod_HK_iterations_min(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
    longest_so_far = 0

    for i in 1:attempts
        avg_node_order = generate_random_average_nodes_order(game)
        optimal_strategy, iterations = mod_hoffman_karp_switch_min_nodes(game, avg_node_order, optimizer=optimizer, logging_on=logging_on)
        longest_so_far = max(iterations,longest_so_far)
    end

    return longest_so_far
end 

"""
    analyze_longest_paths(filename::String)

Does a BFS to find the longest paths to all of the max nodes in a graph, prints the results

# Arguments
- `filename::String`: The file name of the instance to read
"""
function analyze_longest_paths(filename::String)
    game = read_stopping_game(filename)

    max = 0
    min = 0
    avg = 0
    for node in game
        if node.type == minimizer
            min += 1
        elseif node.type == maximizer
            max += 1
        elseif node.type == average 
            avg += 1
        end
    end
    println("max:$max min:$min avg:$avg")

    longest_path_values = get_longest_acyclic_paths_to_max_nodes_recursive(game)

    for key in keys(longest_path_values)
        println("ID: ",key," => Length: ", longest_path_values[key])
    end
end


"""
    compare_HK_iterations(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)

Tries many random seed strtageies for Hoffman-Karp and compares the run time of HK to Mod-HK
Returns {Int} the largest number of iterations found

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
"""
function compare_HK_iterations(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
    parentmap = get_parent_map(game)
	
    for i in 1:attempts
        avg_node_order = generate_random_average_nodes_order(game)
        #avg_node_order = generate_true_random_average_nodes_order(game)
        max_strat = generate_max_strategy_from_average_order(game, avg_node_order, parentmap)
        optimal_strategy, iterations  = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer, logging_on = logging_on)
        mod_optimal_strategy, mod_iterations = mod_hoffman_karp_switch_max_nodes(game,avg_node_order, optimizer = optimizer, logging_on = logging_on)
        
        useless, check  = hoffman_karp_switch_max_nodes(game,mod_optimal_strategy, optimizer = optimizer, logging_on = logging_on)
    
        tag = " n"

        if iterations < mod_iterations
            tag = " HK Wins!!!"
        end

        print("   Should be 1:",check)
        println("   HK:", iterations,  "   Mod-HK:",mod_iterations, tag)
    end

end 














function run_HK_comparison(filename::String; attempts::Int=100)
    compare_HK_iterations(read_stopping_game(filename),attempts=attempts)
end


function test_ones(filename::String = "64_64_32/64_64_32_1.ssg",optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false, log_values = true)
    game::Vector{SGNode} = read_stopping_game(filename)
    parentmap = get_parent_map(game)

    ones_vector = find_ones_or_zeros(true, game, parentmap)
    zeros_vector = find_ones_or_zeros(false, game, parentmap)
    print("Ones: ")
    for i in 1:lastindex(ones_vector)
        if ones_vector[i]
            print(i," ")
        end
    end
    println("\n")
    print("Zeros: ")
    for i in 1:lastindex(ones_vector)
        if zeros_vector[i]
            print(i," ")
        end
    end
    println("\n\n")

    
    avg_node_order = generate_random_average_nodes_order(game)
    max_strat = generate_max_strategy_from_average_order(game, avg_node_order, parentmap)
    optimal_strategy, iterations  = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer, logging_on = logging_on,log_values=log_values)
    # mod_optimal_strategy, mod_iterations = mod_hoffman_karp_switch_max_nodes(game,avg_node_order, optimizer = optimizer, logging_on = logging_on, log_values=log_values)
end

function run_mod_hk(game::String;optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
    game = read_stopping_game(game)
    avg_node_order = generate_random_average_nodes_order(game)
    optimal_strategy, iterations = mod_hoffman_karp_switch_min_nodes(game, avg_node_order, optimizer=optimizer, logging_on=logging_on, log_analysis=true)
    println("iterations: $iterations")
end










function run_nearness_to_one(filename::String = "64_64_64_r/64_64_64_r_1.ssg",optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false, log_values = false)
    game::Vector{SGNode} = read_stopping_game(filename)
    parentmap = get_parent_map(game)

    decisions, values = solve_using_nearness_to_one(game, parentmap=parentmap)

    avg_node_order = generate_random_average_nodes_order(game)
    max_strat = generate_max_strategy_from_average_order(game, avg_node_order, parentmap)
    optimal_strategy, iterations  = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer, logging_on = logging_on,log_values=log_values)
    
    optimal_values = retrive_solution_values(game, optimal_strategy)

    compare_solution_values(values,optimal_values)
    compare_solutions(decisions,optimal_strategy)
end