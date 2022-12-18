using StatsBase
using JuMP
using GLPK
using CPLEX

using Dates

include("sg_objects/sg_objects.jl")
include("io/io.jl")
include("algorithms/algorithms_main.jl")
include("generator/generator.jl")
include("main/main.jl")

generate_worst_games(128, 128, 256, 10, 100, 100, "128_128_256/128_128_256", optimizer = CPLEX.Optimizer, logging_on=false)