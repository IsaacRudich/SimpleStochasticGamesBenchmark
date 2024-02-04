"""
    get_most_HK_iterations_max(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false)

A heuristic method tries some intentional, and many random, seed strtageies for Hoffman-Karp looking for the longest runtime
Returns {Int} the largest number of iterations found

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
"""
function get_most_HK_iterations_max(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false)
    max_strat = generate_upwards_max_strategy(game)
    optimal_strategy, iterations = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer, logging_on = false)
    longest_so_far = iterations

    max_strat = generate_downwards_max_strategy(game)
    optimal_strategy, iterations  = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer, logging_on =false)
    longest_so_far = max(iterations,longest_so_far)

    max_strat = generate_inverse_max_strategy(game, optimal_strategy)
    optimal_strategy, iterations  = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer, logging_on = false)
    longest_so_far = max(iterations,longest_so_far)

    longest, avg, med, stdev,avg_time = get_random_HK_iterations_max(game, attempts = attempts, optimizer = optimizer, logging_on = logging_on)
    longest_so_far = max(longest, longest_so_far)
    return longest_so_far, avg, med, stdev, avg_time
end 

"""
    get_random_HK_iterations_max(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false, sublogging_on::Bool = false))

Tries many random seed strtageies for Hoffman-Karp looking for the longest runtime and average runtime
Returns {Int}, {Int} the largest number of iterations,the average number of iteration, 

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
- `sublogging_on::Bool`: whether or not to log optimizer progress
"""
function get_random_HK_iterations_max(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false, sublogging_on::Bool = false)
    itr_tracker = Vector{Int}()
    time_tracker = Vector{Float64}()
    longest_so_far = 0
    for i in 1:attempts
        failure_check = true
        while failure_check
            if logging_on && i%5 == 0
                println("iteration: $i")
            end
            max_strat = generate_random_max_strategy(game)

            elapsed_time = @elapsed begin
                hk_solution = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer, logging_on = sublogging_on, auto_terminate = true)
            end
            if !isnothing(hk_solution)
                optimal_strategy, iterations = hk_solution
                push!(itr_tracker, iterations)
                push!(time_tracker, elapsed_time)
                longest_so_far = max(iterations,longest_so_far)
                failure_check = false
            else
                println("Numerical Instability, Retrying Iteration $i")
            end
        end
    end
    return longest_so_far, mean(itr_tracker), median(itr_tracker), std(itr_tracker), mean(time_tracker)
end

"""
    get_most_HK_iterations_min(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false)

A heuristic method tries some intentional, and many random, seed strtageies for Hoffman-Karp looking for the longest runtime
Returns {Int} the largest number of iterations found

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
"""
function get_most_HK_iterations_min(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false)
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
    get_most_mod_HK_iterations_max(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false)

A heuristic method tries many random seed strtageies for Mod Hoffman-Karp looking for the longest runtime
Returns {Int} the largest number of iterations found

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
"""
function get_most_mod_HK_iterations_max(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false)
    longest_so_far = 0

    for i in 1:attempts
        avg_node_order = generate_random_average_nodes_order(game)
        optimal_strategy, iterations = mod_hoffman_karp_switch_max_nodes(game, avg_node_order, optimizer=optimizer, logging_on=logging_on)
        longest_so_far = max(iterations,longest_so_far)
    end

    return longest_so_far
end 

"""
    get_most_mod_HK_iterations_min(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false)

A heuristic method tries many random seed strtageies for Mod Hoffman-Karp looking for the longest runtime
Returns {Int} the largest number of iterations found

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
"""
function get_most_mod_HK_iterations_min(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false)
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
    compare_HK_iterations(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false)

Tries many random seed strtageies for Hoffman-Karp and compares the run time of HK to Mod-HK
Returns {Int} the largest number of iterations found

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
"""
function compare_HK_iterations(game::Vector{SGNode}; attempts::Int=100,optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false)
    parentmap = get_parent_map(game)
	
    for i in 1:attempts
        avg_node_order = generate_random_average_nodes_order(game)
        #avg_node_order = generate_true_random_average_nodes_order(game)
        max_strat = generate_max_strategy_from_average_order(game, avg_node_order, parentmap)
        optimal_strategy, iterations  = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer, logging_on = logging_on)
        mod_optimal_strategy, mod_iterations = mod_hoffman_karp_switch_max_nodes(game,avg_node_order, optimizer = optimizer, logging_on = logging_on)
    
        tag = " n"

        if iterations < mod_iterations
            tag = " HK Wins!!!"
        end


        println("   HK:", iterations,  "   Mod-HK:",mod_iterations, tag)
    end

end

"""
    get_random_mod_HK_iterations_max(game::Vector{SGNode};attempts::Int = 100, optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false, sublogging_on::Bool = false))

Tries many random seed strtageies for Mod-Hoffman-Karp looking for the longest runtime and average runtime
Returns {Int}, {Int} the largest number of iterations,the average number of iteration, 

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
- `sublogging_on::Bool`: whether or not to log optimizer progress
"""
function get_random_mod_HK_iterations_max(game::Vector{SGNode};attempts::Int = 100, optimizer::DataType = SCIP.Optimizer, logging_on::Bool=false, sublogging_on::Bool = false)
    itr_tracker = Vector{Int}()
    time_tracker = Vector{Float64}()
    longest_so_far = 0
    for i in 1:attempts
        failure_check = true
        while failure_check
            if logging_on && i%5 == 0
                println("iteration: $i")
            end
            avg_node_order = generate_random_average_nodes_order(game)
            elapsed_time = @elapsed begin
                mod_hk_solution = mod_hoffman_karp_switch_max_nodes(game, avg_node_order, optimizer=optimizer, logging_on=sublogging_on, auto_terminate = true)
            end
            if !isnothing(mod_hk_solution)
                optimal_strategy, iterations = mod_hk_solution
                push!(itr_tracker, iterations)
                push!(time_tracker, elapsed_time)
                longest_so_far = max(iterations,longest_so_far)
                failure_check = false
            else
                println("Numerical Instability, Retrying Iteration $i")
            end
        end
    end
    return longest_so_far, mean(itr_tracker),median(itr_tracker),std(itr_tracker), mean(time_tracker)
end

"""
    analyze_benchmark_set(folder_name::String = "balanced_4096"; optimizer::DataType = SCIP.Optimizer, attempts::Int = 100, start::Int = 1, sublogging_on::Bool = true)

Tries many random seed strtageies for Hoffman-Karp and Mod-Hoffman-Karp looking for the longest runtime and average runtime
Writes the results to a file

# Arguments
- `game::Vector{SGNode}`: The SSG
- `attempts::Int`: The number of random strategies to try
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
- `sublogging_on::Bool`: turns on iteration prints
"""
function analyze_benchmark_set(folder_name::String = "balanced_4096"; optimizer::DataType = SCIP.Optimizer, attempts::Int = 100, start::Int = 1, sublogging_on::Bool = true)
    folder_path = string("instances/benchmark/$folder_name")
    
    # Get a list of files in the folder
    files = readdir(folder_path)
    # Iterate over the files
    for file_index in start:lastindex(files)
        file = files[file_index]
        println("Processing: ",file)
        game = read_stopping_game(string("benchmark/",folder_name,"/",file))
        println("\nRunning Hoffman-Karp")
        longest, avg, med, stdev, avg_time = get_random_HK_iterations_max(game, optimizer = optimizer, attempts = attempts, logging_on = sublogging_on, sublogging_on = false)
        println("Longest: ", longest, " Average: ", avg, " Median: ",med," St. Dev: ",round(stdev, digits = 2)," Average Run Time: ", round(avg_time, digits = 2))

        println("\nRunning Mod-Hoffman-Karp")
        longest_mod, avg_mod, med_mod, stdev_mod, avg_time_mod = get_random_mod_HK_iterations_max(game, optimizer = optimizer, attempts = attempts, logging_on = sublogging_on, sublogging_on = false)
        println("Longest_Mod: ", longest_mod, " Average_Mod: ", avg_mod, " Median Mod: ",med_mod," St. Dev Mod: ",round(stdev_mod, digits = 2)," Average Run Time Mod: ", round(avg_time_mod, digits = 2))
        println("\nSpeedup: ",round(avg_time/avg_time_mod,digits = 2))
        write_analysis("$folder_name", file, longest, avg, med, stdev, avg_time, longest_mod, avg_mod, med_mod, stdev_mod, avg_time_mod)
    end
end