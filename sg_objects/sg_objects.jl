@enum NodeTypes terminal0=0 terminal1=1 maximizer=2 minimizer=3 average=4 
abstract type Node end

include("./SGNode.jl")
include("./MutableSGNode.jl")

function convert_mutable_to_static(game::Vector{MutableSGNode})
    new_game = Vector{SGNode}()
    sizehint!(new_game, length(game))
    for node in game
        push!(new_game, SGNode(node.type,node.arc_a,node.arc_b))
    end
    return new_game
end