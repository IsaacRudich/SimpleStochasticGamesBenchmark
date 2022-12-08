include("StoppingGames.jl")

function generate_new_game(nmax::Int, nmin::Int, navg::Int, filename::String; optimizer::DataType = CPLEX.Optimizer)

    @timeit to "total game generation time" begin
        game, parentmap = generate_reduced_stopping_game_efficient(nmax,nmin,navg)
        @timeit to "convert to static" game = convert_mutable_to_static(game)
    end
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

    println("Using Random Strategy")
    max_strat = generate_random_max_strategy(game)
    optimal_strategy = hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer)

    println()

    return game, optimal_strategy
end 