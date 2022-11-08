using Revise
using BenchmarkTools

using StatsBase
using JuMP
using CPLEX

using TimerOutputs
const to = TimerOutput()

include("sg_objects/sg_objects.jl")
include("io/io.jl")
include("algorithms/algorithms_main.jl")
include("generator/generator.jl")


function test(nmax::Int, nmin::Int, navg::Int)
    @timeit to "total" game, parentmap = generate_reduced_stopping_game_efficient(nmax,nmin,navg)
    #println(game)
    #=for (key, value) in parentmap
        print("$key => $value     ")
    end
    println()=#
    println(to)
    reset_timer!(to)
    return nothing
    #return game
end 

