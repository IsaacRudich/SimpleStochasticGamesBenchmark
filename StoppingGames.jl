using Revise
using BenchmarkTools

using StatsBase
using JuMP
using CPLEX

using TimerOutputs
const to = TimerOutput()

include("sg_objects/sg_objects.jl")
include("io/io.jl")
include("generator/generator.jl")
#include("algorithms/algorithms.jl")

function test(nmax::Int, nmin::Int, navg::Int)
    game, parentmap = generate_reduced_stopping_game(nmax,nmin,navg)
    println(game)
    #=for (key, value) in parentmap
        print("$key => $value     ")
    end
    println()=#
    println(to)
end 

