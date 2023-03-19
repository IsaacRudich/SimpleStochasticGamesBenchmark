"""
    generate_new_game(nmax::Int, nmin::Int, navg::Int)

Generate a new SSGG
Returns {Int} the SSG

# Arguments
- `nmax::Int`: number of max nodes
- `nmin::Int`: number of min nodes
- `navg::Int`: number of average nodes
"""
function generate_new_game(nmax::Int, nmin::Int, navg::Int)
    game, parentmap = generate_reduced_stopping_game_efficient(nmax,nmin,navg)
    game = getstaticgame(game)
    
    return game, parentmap
end 

"""
    generate_worst_games_max(nmax::Int, nmin::Int, navg::Int, num_to_write::Int, num_to_generate::Int, num_strategy_attempts::Int, filename::String; optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)

Generate hard to solve SSGs, and writes them to a files. Hard here assumes you are the max player

# Arguments
- `nmax::Int`: number of max nodes
- `nmin::Int`: number of min nodes
- `navg::Int`: number of average nodes
- `num_to_write::Int`: the number of games to write to memory
- `num_to_generate::Int`: the number of games to create
- `num_strategy_attempts::Int`: the number of attempts made to solve each game
- `filename::String`: the name of the file to write the games
- `optimizer::DataType`: the solver to use for HK
- `logging_on::Bool`: turns on debug statements
"""
function generate_worst_games_max(nmax::Int, nmin::Int, navg::Int, num_to_write::Int, num_to_generate::Int, num_strategy_attempts::Int, filename::String; optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
    worst_games = Vector{Vector{SGNode}}()
    matching_iterations = Vector{Int}()
    sizehint!(worst_games, num_to_write+1)
    sizehint!(matching_iterations, num_to_write+1)

    for i in 1:num_to_generate
        println("Starting Generation: $i")
        game,parentmap = generate_new_game(nmax, nmin, navg)

        write_stopping_game(game, string(filename, "_working.ssg"), max_iterations = 1)

        if check_for_bad_subgraphs(game)
            println("BAD SUBGRAPH")
            return
        end

        iterations = get_most_HK_iterations_max(game, attempts=num_strategy_attempts,optimizer = optimizer, logging_on=false)
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
        write_stopping_game(game, string(filename,"_",i,".ssg"), max_iterations = matching_iterations[i])
    end
end

"""
    generate_worst_games_min(nmax::Int, nmin::Int, navg::Int, num_to_write::Int, num_to_generate::Int, num_strategy_attempts::Int, filename::String; optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)

Generate hard to solve SSGs, and writes them to a files. Hard here assumes you are the min player

# Arguments
- `nmax::Int`: number of max nodes
- `nmin::Int`: number of min nodes
- `navg::Int`: number of average nodes
- `num_to_write::Int`: the number of games to write to memory
- `num_to_generate::Int`: the number of games to create
- `num_strategy_attempts::Int`: the number of attempts made to solve each game
- `filename::String`: the name of the file to write the games
- `optimizer::DataType`: the solver to use for HK
- `logging_on::Bool`: turns on debug statements
"""
function generate_worst_games_min(nmax::Int, nmin::Int, navg::Int, num_to_write::Int, num_to_generate::Int, num_strategy_attempts::Int, filename::String; optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
    worst_games = Vector{Vector{SGNode}}()
    matching_iterations = Vector{Int}()
    sizehint!(worst_games, num_to_write+1)
    sizehint!(matching_iterations, num_to_write+1)

    for i in 1:num_to_generate
        println("Starting Generation: $i")
        game,parentmap = generate_new_game(nmax, nmin, navg)

        write_stopping_game(game, string(filename, "_working.ssg"), min_iterations = 1)

        if check_for_bad_subgraphs(game)
            println("BAD SUBGRAPH")
            return
        end

        iterations = get_most_HK_iterations_min(game, attempts=num_strategy_attempts,optimizer = optimizer, logging_on=false)
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
        write_stopping_game(game, string(filename,"_",i,".ssg"), min_iterations = matching_iterations[i])
    end
end


"""
    generate_worst_reduced_games(nmax::Int, nmin::Int, navg::Int, num_to_write::Int, num_to_generate::Int, num_strategy_attempts::Int, filename::String; optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)

Generate hard to solve reduced SSGs, and writes them to a files. 

# Arguments
- `nmax::Int`: number of max nodes
- `nmin::Int`: number of min nodes
- `navg::Int`: number of average nodes
- `num_to_write::Int`: the number of games to write to memory
- `num_to_generate::Int`: the number of games to create
- `num_strategy_attempts::Int`: the number of attempts made to solve each game
- `filename::String`: the name of the file to write the games
- `optimizer::DataType`: the solver to use for HK
- `logging_on::Bool`: turns on debug statements
"""
function generate_worst_reduced_games(nmax::Int=4, nmin::Int=4, navg::Int=4, num_to_write::Int=10, num_to_generate::Int=100, num_strategy_attempts::Int=250, filename::String="4_4_4_r"; optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
    worst_games = Vector{Vector{SGNode}}()
    matching_iterations = Vector{Int}()
    matching_max_iterations = Vector{Int}()
    matching_min_iterations = Vector{Int}()
    scc_storage = Vector{Vector{Vector{Int}}}()
    sizehint!(worst_games, num_to_write+1)
    sizehint!(matching_iterations, num_to_write+1)

    for i in 1:num_to_generate
        println("Starting Generation: $i")
        game,parentmap = generate_new_game(nmax, nmin, navg)

        println("Reducing Game")
        game, orderedsccs = reduce_game(game, parentmap)
        write_stopping_game(game, string(filename, "_working.ssg"),sccs=orderedsccs)

        println("Sanity Check for Bad Subgraphs")
        if check_for_bad_subgraphs(game)
            println("BAD SUBGRAPH")
            return
        end

        println("Running HK Strategies for Max")
        iterations_max = get_most_HK_iterations_max(game, attempts=num_strategy_attempts,optimizer = optimizer, logging_on=false)
        println("Running HK Strategies for Min")
        iterations_min = get_most_HK_iterations_min(game, attempts=num_strategy_attempts,optimizer = optimizer, logging_on=false)
        println("Checking Results")
        iterations = min(iterations_max,iterations_min)
        placement = searchsortedfirst(matching_iterations, iterations)
        insert!(matching_iterations, placement, iterations)
        insert!(matching_max_iterations, placement, iterations_max)
        insert!(matching_min_iterations, placement, iterations_max)
        insert!(worst_games, placement, game)
        insert!(scc_storage, placement, orderedsccs)
        if length(matching_iterations)>num_to_write
            popfirst!(matching_max_iterations)
            popfirst!(matching_min_iterations)
            popfirst!(matching_iterations)
            popfirst!(worst_games)
            popfirst!(scc_storage)
        end
        println("     num iterations: $iterations    worst: $matching_iterations \n")
    end

    for (i,game) in enumerate(worst_games)
        write_stopping_game(game, string(filename,"_",i,".ssg"), max_iterations = matching_max_iterations[i],min_iterations = matching_min_iterations[i],sccs=scc_storage[i])
    end
end