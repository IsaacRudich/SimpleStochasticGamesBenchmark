"""
    generate_upwards_max_strategy(game::Vector{SGNode})

Create a max node strategy that always points to the highest indexed node

# Arguments
- `game::Vector{SGNode}`: The SSG
"""
function generate_upwards_max_strategy(game::Vector{SGNode})
    max_strat = Dict{Int,Int}()
    for (id, node) in enumerate(game)
        if node.type == maximizer
            if node.arc_a > node.arc_b
                max_strat[id] = node.arc_a
            else
                max_strat[id] = node.arc_b
            end
        end
    end
    return max_strat
end

"""
    generate_downwards_max_strategy(game::Vector{SGNode})

Create a max node strategy that always points to the lowest indexed node

# Arguments
- `game::Vector{SGNode}`: The SSG
"""
function generate_downwards_max_strategy(game::Vector{SGNode})
    max_strat = Dict{Int,Int}()
    for (id, node) in enumerate(game)
        if node.type == maximizer
            if node.arc_a > node.arc_b
                max_strat[id] = node.arc_b
            else
                max_strat[id] = node.arc_a
            end
        end
    end
    return max_strat
end

"""
    generate_random_max_strategy(game::Vector{SGNode})

Create a max node strategy that is random

# Arguments
- `game::Vector{SGNode}`: The SSG
"""
function generate_random_max_strategy(game::Vector{SGNode})
    max_strat = Dict{Int,Int}()
    for (id, node) in enumerate(game)
        if node.type == maximizer
            choice = rand([0,1])
            if choice == 0
                max_strat[id] = node.arc_b
            else
                max_strat[id] = node.arc_a
            end
        end
    end
    return max_strat
end

"""
    generate_inverse_max_strategy(game::Vector{SGNode}, strat::Dict{Int,Int})

Create a max node strategy that inverses an existing strategy

# Arguments
- `game::Vector{SGNode}`: The SSG
- `strat::Dict{Int,Int}`: the strategy to inverse
"""
function generate_inverse_max_strategy(game::Vector{SGNode}, strat::Dict{Int,Int})
    max_strat = Dict{Int,Int}()
    for (id, node) in enumerate(game)
        if node.type == maximizer
            if node.arc_a == strat[id]
                max_strat[id] = node.arc_b
            else
                max_strat[id] = node.arc_a
            end
        end
    end
    return max_strat
end

"""
    generate_random_average_nodes_order(game::Vector{SGNode})

Create a random ordering of average nodes (that repsects the values implied by the terminals).
The order is highest to lowest
# Arguments
- `game::Vector{SGNode}`: The SSG
"""
function generate_random_average_nodes_order(game::Vector{SGNode})
    average_nodes_toone = Vector{Int}()
    average_nodes_tomiddle = Vector{Int}()
    average_nodes_tozero = Vector{Int}()
    @inbounds for (id,node) in enumerate(game)
        if node.type == average
            arc_a_type = game[node.arc_a].type
            arc_b_type = game[node.arc_b].type
            if arc_a_type == terminal1 || arc_b_type == terminal1
                if arc_a_type != terminal0 && arc_b_type != terminal0
                    push!(average_nodes_toone, id)
                else
                    push!(average_nodes_tomiddle, id)
                end
            elseif arc_a_type == terminal0 || arc_b_type == terminal0
                push!(average_nodes_tozero, id)
            else
                push!(average_nodes_tomiddle, id)
            end
        end
    end
    shuffle!(average_nodes_toone)
    shuffle!(average_nodes_tomiddle)
    shuffle!(average_nodes_tozero)
    return vcat(average_nodes_toone, average_nodes_tomiddle,average_nodes_tozero)
end

"""
    generate_true_random_average_nodes_order(game::Vector{SGNode})

Create a random ordering of average nodes
The order is highest to lowest
# Arguments
- `game::Vector{SGNode}`: The SSG
"""
function generate_true_random_average_nodes_order(game::Vector{SGNode})
    average_nodes = Vector{Int}()
    @inbounds for (id,node) in enumerate(game)
        if node.type == average
            push!(average_nodes, id)
        end
    end
    shuffle!(average_nodes)
    return average_nodes
end

"""
    generate_max_strategy_from_average_order(game::Vector{SGNode}, average_node_order::Vector{Int}, parentmap::Dict{Int, Vector{Int}})

Create a max strategy from an ordering of average nodes

# Arguments
- `game::Vector{SGNode}`: The SSG
- `average_node_order::Vector{Int}`: list of average node ids, sorted highest to lowest
- `parentmap::Dict{Int, Vector{Int}}`: map of nodes to their parents
"""
function generate_max_strategy_from_average_order(game::Vector{SGNode}, average_node_order::Vector{Int}, parentmap::Dict{Int, Vector{Int}})
    labeled = zeros(length(game)-2)

    @inbounds for avg_node_id in average_node_order
        labeled[avg_node_id] = true
    end

    queue = Vector{Int}()
    sizehint!(queue, length(game))

    @inbounds for avg_node_id in average_node_order
        push!(queue, avg_node_id)
        while !isempty(queue)
            current_node_id = pop!(queue)
            
            for parent_id in parentmap[current_node_id]
                parent_node = game[parent_id]
                if labeled[parent_id]==0
                    if parent_node.type == maximizer 
                        if parent_node.arc_a == current_node_id
                            labeled[parent_id] = 1
                        elseif parent_node.arc_b == current_node_id
                            labeled[parent_id] = 2
                        else
                            throw(error("SOMETHING HAS GONE WRONG"))
                        end
                        push!(queue, parent_id)
                    elseif parent_node.type == minimizer
                        if parent_node.arc_a == current_node_id
                            labeled[parent_id] = 2
                        elseif parent_node.arc_b == current_node_id
                            labeled[parent_id] = 1
                        else
                            throw(error("SOMETHING HAS GONE WRONG"))
                        end
                    end
                elseif parent_node.type == minimizer
                    if labeled[parent_id] == 1 && parent_node.arc_a == current_node_id
                        push!(queue, parent_id)
                    elseif labeled[parent_id] == 2 && parent_node.arc_b == current_node_id
                        push!(queue, parent_id)
                    end
                end
            end
        end
    end

    max_strat = Dict{Int,Int}()

    @inbounds for (id,node) in enumerate(game)
        if node.type == maximizer
            if labeled[id] == 1
                max_strat[id] = node.arc_a
            elseif labeled[id] == 2
                max_strat[id] = node.arc_b
            else
                throw(error("SOMETHING HAS GONE WRONG"))
            end
        end
    end

    return max_strat
end

"""
    generate_min_strategy_from_average_order(game::Vector{SGNode}, average_node_order::Vector{Int}, parentmap::Dict{Int, Vector{Int}})

Create a min strategy from an ordering of average nodes

# Arguments
- `game::Vector{SGNode}`: The SSG
- `average_node_order::Vector{Int}`: list of average node ids, sorted highest to lowest
- `parentmap::Dict{Int, Vector{Int}}`: map of nodes to their parents
"""
function generate_min_strategy_from_average_order(game::Vector{SGNode}, average_node_order::Vector{Int}, parentmap::Dict{Int, Vector{Int}})
    reverse!(average_node_order)
    labeled = zeros(length(game)-2)

    @inbounds for avg_node_id in average_node_order
        labeled[avg_node_id] = true
    end

    queue = Vector{Int}()
    sizehint!(queue, length(game))

    @inbounds for avg_node_id in average_node_order
        push!(queue, avg_node_id)
        while !isempty(queue)
            current_node_id = pop!(queue)
            
            for parent_id in parentmap[current_node_id]
                parent_node = game[parent_id]
                if labeled[parent_id]==0
                    if parent_node.type == minimizer
                        if parent_node.arc_a == current_node_id
                            labeled[parent_id] = 1
                        elseif parent_node.arc_b == current_node_id
                            labeled[parent_id] = 2
                        else
                            throw(error("SOMETHING HAS GONE WRONG"))
                        end
                        push!(queue, parent_id)
                    elseif parent_node.type == maximizer
                        if parent_node.arc_a == current_node_id
                            labeled[parent_id] = 2
                        elseif parent_node.arc_b == current_node_id
                            labeled[parent_id] = 1
                        else
                            throw(error("SOMETHING HAS GONE WRONG"))
                        end
                    end
                elseif parent_node.type == maximizer
                    if labeled[parent_id] == 1 && parent_node.arc_a == current_node_id
                        push!(queue, parent_id)
                    elseif labeled[parent_id] == 2 && parent_node.arc_b == current_node_id
                        push!(queue, parent_id)
                    end
                end
            end
        end
    end

    min_strat = Dict{Int,Int}()

    @inbounds for (id,node) in enumerate(game)
        if node.type == minimizer
            if labeled[id] == 1
                min_strat[id] = node.arc_a
            elseif labeled[id] == 2
                min_strat[id] = node.arc_b
            else
                throw(error("SOMETHING HAS GONE WRONG"))
            end
        end
    end

    return min_strat
end