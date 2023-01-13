"""
    get_parent_map(game::Vector{SGNode})

Get a parent map for a given game

# Arguments
- `game::Vector{SGNode}`: The SSG
"""
function get_parent_map(game::Vector{SGNode})
    parentmap = Dict{Int, Vector{Int}}()

    @inbounds for (id, node) in enumerate(game)
        parentmap[id] = Vector{Int}()
    end

    @inbounds for (id, node) in enumerate(game)
        if node.arc_a != 0
            push!(parentmap[node.arc_a], id)
            push!(parentmap[node.arc_b], id)
        end
    end

    return parentmap
end