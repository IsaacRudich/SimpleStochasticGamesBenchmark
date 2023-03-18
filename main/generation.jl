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
    
    return game
end 

"""
    generate_worst_games(nmax::Int, nmin::Int, navg::Int, num_to_write::Int, num_to_generate::Int, num_strategy_attempts::Int, filename::String; optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)

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
function generate_worst_games(nmax::Int, nmin::Int, navg::Int, num_to_write::Int, num_to_generate::Int, num_strategy_attempts::Int, filename::String; optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
    worst_games = Vector{Vector{SGNode}}()
    matching_iterations = Vector{Int}()
    sizehint!(worst_games, num_to_write+1)
    sizehint!(matching_iterations, num_to_write+1)

    for i in 1:num_to_generate
        println("Starting Generation: $i")
        game = generate_new_game(nmax, nmin, navg)

        write_stopping_game(game, string(filename, "_working.ssg"), num_iterations = 1)

        if check_for_bad_subgraphs(game)
            println("BAD SUBGRAPHH")
            return
        end

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

"""
    generate_backwards_worst_games(nmax::Int, nmin::Int, navg::Int, num_to_write::Int, num_to_generate::Int, num_strategy_attempts::Int, filename::String; optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)

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
function generate_backwards_worst_games(nmax::Int, nmin::Int, navg::Int, num_to_write::Int, num_to_generate::Int, num_strategy_attempts::Int, filename::String; optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
    worst_games = Vector{Vector{SGNode}}()
    matching_iterations = Vector{Int}()
    sizehint!(worst_games, num_to_write+1)
    sizehint!(matching_iterations, num_to_write+1)

    for i in 1:num_to_generate
        println("Starting Generation: $i")
        game = generate_new_game(nmax, nmin, navg)

        write_stopping_game(game, string(filename, "_working.ssg"), num_iterations = 1)

        if check_for_bad_subgraphs(game)
            println("BAD SUBGRAPHH")
            return
        end

        iterations = get_most_HK_iterations_backwards(game, attempts=num_strategy_attempts,optimizer = optimizer, logging_on=false)
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

function reduce_game(filename::String = "64_64_32/64_64_32_10.ssg")
    game::Vector{SGNode} = read_stopping_game(filename)
    parentmap = get_parent_map(game)

    reducedgame = remove_ones_and_zeros(game, parentmap)
    orderedsccs = sort_into_sccs(reducedgame)
    reducedgame = reindex_by_sccs(reducedgame,orderedsccs)
    write_stopping_game(reducedgame, string(filename,"_r.ssg"))

    orderedsccs = sort_into_sccs(reducedgame)
    
    for scc in orderedsccs
        for e in scc
            print(e, " ")
        end
        println()
    end
end