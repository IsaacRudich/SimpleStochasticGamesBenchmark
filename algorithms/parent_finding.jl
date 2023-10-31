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

"""
    get_min_parents(game::Union{Vector{SGNode},Vector{MutableSGNode}}, parentmap::Dict{Int, Vector{Int}})

Get a subset of parent map of only min nodes
Returns: Dict{Int, Vector{Int}}

# Arguments
- `game::Union{Vector{SGNode},Vector{MutableSGNode}}`: The SSG
- `parentmap::Dict{Int, Vector{Int}}`: A full parent map
"""
function get_min_parents(game::Union{Vector{SGNode},Vector{MutableSGNode}}, parentmap::Dict{Int, Vector{Int}})
    minparentmap = Dict{Int, Vector{Int}}()
    
    @inbounds for (i, node) in enumerate(game)
        parents = Vector{Int}()
        for p_id in parentmap[i]
            if game[p_id].type == minimizer
                push!(parents,p_id)
            end
        end
        minparentmap[i] = parents
    end

    return minparentmap
end

"""
    get_max_parents(game::Union{Vector{SGNode},Vector{MutableSGNode}}, parentmap::Dict{Int, Vector{Int}})

Get a subset of parent map of only max nodes
Returns: Dict{Int, Vector{Int}}

# Arguments
- `game::Union{Vector{SGNode},Vector{MutableSGNode}}`: The SSG
- `parentmap::Dict{Int, Vector{Int}}`: A full parent map
"""
function get_max_parents(game::Union{Vector{SGNode},Vector{MutableSGNode}}, parentmap::Dict{Int, Vector{Int}})
    maxparentmap = Dict{Int, Vector{Int}}()
    
    @inbounds for (i, node) in enumerate(game)
        parents = Vector{Int}()
        for p_id in parentmap[i]
            if game[p_id].type == maximizer
                push!(parents,p_id)
            end
        end
        maxparentmap[i] = parents
    end

    return maxparentmap
end