using StatsBase
using JuMP
# using CPLEX
using GLPK
using SCIP #need a solver that uses rational numbers for numerical stability
using Random
using Dates

using SparseArrays
using LinearAlgebra

using Revise

include("utilities/basic_utilities.jl")
include("sg_objects/sg_objects.jl")
include("io/io.jl")
include("algorithms/algorithms_main.jl")
include("generator/generator.jl")
include("main/main.jl")

#generate_worst_games(128, 128, 64, 10, 100, 100, "128_128_64", optimizer = SCIP.Optimizer, logging_on=false)