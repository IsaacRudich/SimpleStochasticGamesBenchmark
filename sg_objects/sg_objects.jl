@enum NodeTypes terminal0=0 terminal1=1 maximizer=2 minimizer=3 average=4 
abstract type Node end

include("./SGNode.jl")
include("./MutableSGNode.jl")