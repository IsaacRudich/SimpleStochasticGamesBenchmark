"""
    solve_using_nearness_to_one(game::Vector{SGNode};parentmap::Union{Nothing,Dict{Int, Vector{Int}}}=nothing)

Solve an SSG by solving prioritizing shortest paths to one. 
Return decisions::Dict{Int, Int}, values::Dict{Int, Float64}

# Arguments
- `game::Vector{SGNode}`: The SSG
- `parentmap::Union{Nothing,Dict{Int, Vector{Int}}}`: parent map for the SSG
"""
function solve_using_nearness_to_one(game::Vector{SGNode};parentmap::Union{Nothing,Dict{Int, Vector{Int}}}=nothing)
    t_one,t_zero = getterminalindexes(game)
    values = Dict{Int, Float64}()
    for i in 1:length(game)
        values[i] = 0.0
    end
    values[t_one] = 1
    
    if isnothing(parentmap)
        parentmap = get_parent_map(game)
    end

    extra_arcs = find_collapsing_clusters(game,parentmap)

    queue = falses(length(game))
    queue[t_one] = true

    decisions = Dict{Int, Int}()
    is_added = true
    average_parents = falses(length(game))
    while sum(queue) < length(game) - 1
        #phase one, add all collapsing nodes
        @inline average_parents = add_average_parents!(queue, game, parentmap)
        queue = queue .| average_parents

        is_added = true
        while is_added
            is_added = false
            #add max node clusters
            for (i,node) in enumerate(game)
                if !queue[i] && node.type==maximizer
                    if queue[node.arc_a] || queue[node.arc_b]
                        queue[i] = true
                    end
                end
            end
            #add min node clusters
            for (i,node) in enumerate(game)
                if !queue[i] && node.type==minimizer
                    if queue[node.arc_a] && queue[node.arc_b]
                        queue[i] = true
                    end
                end
            end
        end

        #phase two add looping average nodes
        average_parents .= 0
        is_added = true
        while is_added
            is_added = false
            average_parents .= false

            @inbounds for (i,node) in enumerate(game)
                if !queue[i] && node.type==average && (queue[game[i].arc_a] || queue[game[i].arc_a])
                    for parent in parentmap[i]
                        if queue[parent]
                            queue[i] = true
                            is_added = true
                            break
                        end
                    end
                end
            end

            queue = queue .| average_parents
        end

        #phase three get decisions
        empty!(decisions)
        @inbounds for (i,node) in enumerate(game)
            if queue[i]
                if node.type == maximizer
                    if queue[node.arc_a] && queue[node.arc_a]
                        if values[node.arc_a] >= values[node.arc_b]
                            decisions[i] = node.arc_a
                        else
                            decisions[i] = node.arc_b
                        end
                    elseif queue[node.arc_a]
                        decisions[i] = node.arc_a
                    elseif queue[node.arc_b]
                        decisions[i] = node.arc_b
                    end
                    if haskey(extra_arcs, i)
                        current_value = values[decisions[i]]
                        for extra_arc in extra_arcs[i]
                            if current_value < values[extra_arc]
                                decisions[i] = extra_arc
                                current_value = values[extra_arc]
                            end
                        end
                    end
                elseif node.type == minimizer
                    if queue[node.arc_a] && queue[node.arc_a]
                        if values[node.arc_a] <= values[node.arc_b]
                            decisions[i] = node.arc_a
                        else
                            decisions[i] = node.arc_b
                        end
                    end
                end
            end
        end

        #phase four Guassian Elimination
        # Initialize arrays to store row, column indices, and values for the sparse matrix
        rows = Vector{Int}()
        cols = Vector{Int}()
        vals = Vector{Float64}()
        sizehint!(rows, length(game))
        sizehint!(cols, length(game))
        sizehint!(vals, length(game))

        # Initialize a right-hand side vector
        b = zeros(length(game))

        # Loop over the nodes and build the sparse matrix based on their type
        @inbounds for (i,node) in enumerate(game)
            if queue[i]
                if node.type == average
                    push!(rows, i)
                    push!(cols, node.arc_a)
                    push!(vals, 0.5)

                    push!(rows, i)
                    push!(cols, node.arc_b)
                    push!(vals, 0.5)

                    push!(rows, i)
                    push!(cols, i)
                    push!(vals, -1.0)
                elseif node.type == maximizer || node.type == minimizer
                    push!(rows, i)
                    push!(cols, decisions[i])
                    push!(vals, 1.0)

                    push!(rows, i)
                    push!(cols, i)
                    push!(vals, -1.0)
                elseif node.type == terminal1
                    push!(rows, i)
                    push!(cols, i)
                    push!(vals, 1.0)

                    b[i] = 1
                end
            else
                push!(rows, i)
                push!(cols, i)
                push!(vals, 1.0)
            end
        end

        # Create the sparse matrix A
        A = sparse(rows, cols, vals, length(game), length(game))

        # Solve the linear system Ax = b
        x = A \ b

        for i in 1:length(game)
            if x[i] != 0
                values[i] = x[i]
            end
        end
    end
    # Print the result
    return decisions, values
end

"""
    add_average_parents!(set::BitVector, game::Vector{SGNode},parentmap::Dict{Int, Vector{Int}})

Find the parents of an average node and add them to the set
Return ::BitVector the modified set

# Arguments
- `set::BitVector`: the set being modified
- `game::Vector{SGNode}`: The SSG
- `parentmap::Dict{Int, Vector{Int}}`: parent map for the SSG
"""
function add_average_parents!(set::BitVector, game::Vector{SGNode},parentmap::Dict{Int, Vector{Int}})
    average_parents = falses(length(game))
    @inbounds for (i,e) in enumerate(set)
        if e
            for parent in parentmap[i]
                if game[parent].type == average
                    average_parents[parent] = true
                end
            end
        end
    end
    return average_parents
end

"""
    find_collapsing_clusters(game::Vector{SGNode},parentmap::Dict{Int, Vector{Int}})

Find max nodes that have guaranteed paths to average nodes
Return ::Dict{Int, Vector{Int}} where each node maps to a list of its anchor nodes

# Arguments
- `game::Vector{SGNode}`: The SSG
- `parentmap::Dict{Int, Vector{Int}}`: parent map for the SSG
"""
function find_collapsing_clusters(game::Vector{SGNode},parentmap::Dict{Int, Vector{Int}})
    extra_arcs = Dict{Int, Vector{Int}}()

    ancestor_map = Dict{Int, BitVector}()
    for (i, node) in enumerate(game)
        if node.type == average
            ancestor_map[i] = find_ancestors(i, game, parentmap)
        end
    end

    found_parent = false
    rerun_subloop = false
    for (anchor, ancestors) in ancestor_map
        #iteratively removes things from ancestors
        rerun_subloop = true
        while rerun_subloop
            rerun_subloop = false
            for (i, e) in enumerate(ancestors)
                if e && i != anchor
                    current_node =  game[i]
                    if current_node.type == average || current_node.type == minimizer
                        if !ancestors[current_node.arc_a] || !ancestors[current_node.arc_b]
                            ancestors[i] = false
                            rerun_subloop = true
                        end
                    elseif current_node.type == maximizer && !ancestors[current_node.arc_a] && !ancestors[current_node.arc_b]
                        ancestors[i] = false
                        rerun_subloop = true
                    end
                    if ancestors[i] == true
                        found_parent = false
                        for parent_id in parentmap[i]
                            if ancestors[parent_id]
                                found_parent = true
                                break
                            end
                        end
                        if !found_parent
                            ancestors[i] = false
                            rerun_subloop = true
                        end
                    end
                end
            end
        end
        #check for anchor connectedness
        found_parent = false
        for parent_id in parentmap[anchor]
            if ancestors[parent_id]
                found_parent = true
                break
            end
        end
        if found_parent
            #add third arcs
            for (i, e) in enumerate(ancestors)
                if e && game[i].type == maximizer
                    if !haskey(extra_arcs, i)
                        extra_arcs[i] = [anchor]
                    else
                        push!(extra_arcs[i],anchor)
                    end
                end
            end
        end
    end

    return extra_arcs
end

"""
    find_ancestors(node_id::Int, game::Vector{SGNode},parentmap::Dict{Int, Vector{Int}})

Get all nodes that have a path to node_id
Return ::BitVector of node ids in the set

# Arguments
- `node_id::Int`:the id of the node to find ancestors of
- `game::Vector{SGNode}`: The SSG
- `parentmap::Dict{Int, Vector{Int}}`: parent map for the SSG
"""
function find_ancestors(node_id::Int, game::Vector{SGNode},parentmap::Dict{Int, Vector{Int}})
    ancestors = falses(length(game))
    ancestors[node_id] = true

    queue = Vector{Int}()
    push!(queue, node_id)

    while !isempty(queue)
        q_id = popfirst!(queue)
        for parent_id in parentmap[q_id]
            if !ancestors[parent_id]
                ancestors[parent_id] = true
                push!(queue, parent_id)
            end
        end
    end
    return ancestors
end