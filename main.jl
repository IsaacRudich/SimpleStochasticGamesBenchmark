include("StoppingGames.jl")

function generate_new_game(nmax::Int, nmin::Int, navg::Int, filename::String)
    @timeit to "total game generation time" begin
        game, parentmap = generate_reduced_stopping_game_efficient(nmax,nmin,navg)
        @timeit to "convert to static" game = convert_mutable_to_static(game)
    end
    println(to)
    reset_timer!(to)

    write_stopping_game(game, string(filename,".ssg"))

    return game
end 