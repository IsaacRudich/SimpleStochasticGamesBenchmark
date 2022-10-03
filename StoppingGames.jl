using Revise
using BenchmarkTools

using StatsBase
using JuMP
using CPLEX

include("sg_objects/sg_objects.jl")
include("io/io.jl")
include("generator/generator.jl")
#include("algorithms/algorithms.jl")

function test(nmax::Int, nmin::Int, navg::Int)
    generate_reduced_stopping_game(nmax,nmin,navg)
end 

