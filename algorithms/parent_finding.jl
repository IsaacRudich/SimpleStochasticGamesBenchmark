"""
    get_parent_map(game::Union{Vector{SGNode},Vector{MutableSGNode}})

Get a parent map for a given game

# Arguments
- `game::Union{Vector{SGNode},Vector{MutableSGNode}}`: The SSG
"""
function get_parent_map(game::Union{Vector{SGNode},Vector{MutableSGNode}})
    parentmap = Dict{Int, Vector{Int}}()

    @inbounds for (id, node) in enumerate(game)
        parentmap[id] = Vector{Int}()
    end

    @inbounds for (id, node) in enumerate(game)
        if node.arc_a != 0
            push!(parentmap[node.arc_a], id)
        end
        if node.arc_b != 0
            push!(parentmap[node.arc_b], id)
        end
    end

    return parentmap
end