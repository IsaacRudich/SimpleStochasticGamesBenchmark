"""
    get_most_HK_iterations(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)

A heuristic method tries some intentional, and many random, seed strtageies for Hoffman-Karp looking for the longest runtime
Returns {Int} the largest number of iterations found

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
"""
function get_most_HK_iterations(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
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