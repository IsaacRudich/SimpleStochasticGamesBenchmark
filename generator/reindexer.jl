"""
    remove_nodes(game::Vector{MutableSGNode}, removables::Vector{Int})

A method that removes all the indicated nodes from a game and returns a game without those nodes, points those arcs at 0

# Arguments
- `game::Vector{SGNode}`: The SSG
- `removables::Vector{Int}`: The nodes to remove
"""
function remove_nodes(game::Vector{MutableSGNode}, removables::Vector{Int})
    sort!(removables, rev=false)
    deleteat!(game, removables)

    #reindex the remaining nodes
    indexmap = Dict{Int, Int}(0 => 0)
    for (i,node) in enumerate(game)
        indexmap[node.label] = i
    end
    for r in removables
        indexmap[r] = 0
    end

    for node in game
        node.label = indexmap[node.label]
        node.arc_a = indexmap[node.arc_a]
        node.arc_b = indexmap[node.arc_b]
    end

    return game
end
