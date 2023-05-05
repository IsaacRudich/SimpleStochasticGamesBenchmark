using StatsBase
using JuMP
using GLPK
using CPLEX
using Random
using Dates

using Revise

include("sg_objects/sg_objects.jl")
include("io/io.jl")
include("algorithms/algorithms_main.jl")
include("generator/generator.jl")
include("main/main.jl")

#generate_worst_games(128, 128, 64, 10, 100, 100, "128_128_64", optimizer = CPLEX.Optimizer, logging_on=false)