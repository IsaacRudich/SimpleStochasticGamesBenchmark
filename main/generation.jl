function generate_new_game(nmax::Int, nmin::Int, navg::Int)
    game, parentmap = generate_reduced_stopping_game_efficient(nmax,nmin,navg)
    game = convert_mutable_to_static(game)
    
    return game
end 

function generate_worst_games(nmax::Int, nmin::Int, navg::Int, num_to_write::Int, num_to_generate::Int, num_strategy_attempts::Int, filename::String; optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
    worst_games = Vector{Vector{SGNode}}()
    matching_iterations = Vector{Int}()
    sizehint!(worst_games, num_to_write+1)
    sizehint!(matching_iterations, num_to_write+1)

    for i in 1:num_to_generate
        println("Starting Generation: $i")
        game = generate_new_game(nmax, nmin, navg)

        write_stopping_game(game, string(filename, "_working.ssg"), num_iterations = 1)

        iterations = get_most_HK_iterations(game, attempts=num_strategy_attempts,optimizer = optimizer, logging_on=false)
        placement = searchsortedfirst(matching_iterations, iterations)
        insert!(matching_iterations, placement, iterations)
        insert!(worst_games, placement, game)
        if length(matching_iterations)>num_to_write
            popfirst!(matching_iterations)
            popfirst!(worst_games)
        end
        println("     num iterations: $iterations    worst: $matching_iterations \n")
    end

    for (i,game) in enumerate(worst_games)
        write_stopping_game(game, string(filename,"_",i,".ssg"), num_iterations = matching_iterations[i])
    end
end