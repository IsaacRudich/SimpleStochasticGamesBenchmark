include("StoppingGames.jl")

function generate_new_game(nmax::Int, nmin::Int, navg::Int, filename::String; optimizer::DataType = CPLEX.Optimizer)

    @timeit to "total game generation time" begin
        game, parentmap = generate_reduced_stopping_game_efficient(nmax,nmin,navg)
        @timeit to "convert to static" game = convert_mutable_to_static(game)
    end
    println(to)
    reset_timer!(to)

    write_stopping_game(game, string(filename,".ssg"))

    println()

    println("Using Upwards Strategy")
    max_strat = generate_upwards_max_strategy(game)
    optimal_strategy = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer)

    println()
    
    println("Using Downwards Strategy")
    max_strat = generate_downwards_max_strategy(game)
    optimal_strategy = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer)

    println()

    for i in 1:10
        println("Using Random Strategy")
        max_strat = generate_random_max_strategy(game)
        optimal_strategy = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer)
    end

    println()

    println("Using Inverse Optimal Strategy")
    max_strat = generate_inverse_max_strategy(game, optimal_strategy)
    optimal_strategy = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer)

    return game, optimal_strategy
end 

function solve_game(filename::String; optimizer::DataType = CPLEX.Optimizer)

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

    println("Using Upwards Strategy")
    max_strat = generate_upwards_max_strategy(game)
    optimal_strategy = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer)

    println()
    
    # println("Using Downwards Strategy")
    # max_strat = generate_downwards_max_strategy(game)
    # optimal_strategy = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer)

    # println()

    # println("Using Random Strategy")
    # max_strat = generate_random_max_strategy(game)
    # optimal_strategy = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer)

    # println()

    println("Using Inverse Optimal Strategy")
    max_strat = generate_inverse_max_strategy(game, optimal_strategy)
    optimal_strategy = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer)

    return game, optimal_strategy
end 

function analyze_game(filename::String; optimizer::DataType = CPLEX.Optimizer)
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