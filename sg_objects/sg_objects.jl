@enum NodeTypes terminal0=0 terminal1=1 maximizer=2 minimizer=3 average=4 
abstract type Node end

include("./SGNode.jl")
include("./MutableSGNode.jl")


"""
    getstaticgame(game::Vector{MutableSGNode})

Returns a static copy of an MutableSGNode array

# Arguments
- `game::Vector{MutableSGNode}`: the game to be copied
"""
function getstaticgame(game::Vector{MutableSGNode})
    new_game = Vector{SGNode}()
    sizehint!(new_game, length(game))
    for node in game
        push!(new_game, SGNode(node.type,node.arc_a,node.arc_b))
    end
    return new_game
end

"""
    getmutablegame(game::Vector{SGNode})

Returns a mutable copy of an SGNode array

# Arguments
- `game::Vector{SGNode}`: the game to be copied
"""
function getmutablegame(game::Vector{SGNode})
    m_game = Vector{MutableSGNode}()
    sizehint!(m_game, length(game))

    for (i,node) in enumerate(game)
        push!(m_game, MutableSGNode(i, node.type, node.arc_a, node.arc_b))
    end

    return m_game
end

"""
    getterminalindexes(game::Union{SGNode, MutableSGNode})

Returns t_one, t_zero: the indexes of the terminals

# Arguments
- `game::Union{SGNode, MutableSGNode}`: the game to get the terminals for
"""
function getterminalindexes(game::Union{Vector{SGNode}, Vector{MutableSGNode}})
    t_one = nothing
    t_zero = nothing

    for i in length(game):-1:1
        if game[i].type == terminal1
            t_one = i
        elseif game[i].type == terminal0
            t_zero = i
        end
        if !isnothing(t_one) && !isnothing(t_zero)
            break
        end
    end
    return t_one,t_zero
end