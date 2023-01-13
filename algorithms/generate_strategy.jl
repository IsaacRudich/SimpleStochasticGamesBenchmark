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
    generate_max_strategy_from_average_order(game::Vector{SGNode}, average_node_order::Vector{Int}, parentmap::Dict{Int, Vector{Int}})

Create a max strategy from an ordering of average nodes

# Arguments
- `game::Vector{SGNode}`: The SSG
- `average_node_order::Vector{Int}`: list of average node ids, sorted highest to lowest
- `parentmap::Dict{Int, Vector{Int}}`: map of nodes to their parents
"""
function generate_max_strategy_from_average_order(game::Vector{SGNode}, average_node_order::Vector{Int}, parentmap::Dict{Int, Vector{Int}})
    labels = Dict{Int,Int}()
    labeled = falses(length(game)-2)

    average_to_max = Dict{Int, Vector{Int}}()
    average_to_min = Dict{Int, Vector{Int}}()

    @inbounds for avg_node_id in average_node_order
        average_to_max[avg_node_id] = Vector{Int}()
        average_to_min[avg_node_id] = Vector{Int}()
        labels[avg_node_id] = avg_node_id
        labeled[avg_node_id] = true

        for parent_id in parentmap[avg_node_id]
            parent_node = game[parent_id]
            if parent_node.type == maximizer
                push!(average_to_max[avg_node_id], parent_id)
            elseif parent_node.type == minimizer
                push!(average_to_min[avg_node_id], parent_id)
            end
        end
    end

    queue = Vector{Int}()
    new_queue = Vector{Int}()
    sizehint!(queue, length(game))
    sizehint!(new_queue, length(game))

    while sum(labeled) < length(game)-2
        @inbounds for avg_node_id in average_node_order
            #setup queue from known set
            empty!(queue)
            for node_id in average_to_max[avg_node_id]
                push!(queue, node_id)
            end

            while !isempty(queue)
                for id in queue
                    if !labeled[id]
                        labels[id] = avg_node_id
                        labeled[id] = true
                        for parent_id in parentmap[id]
                            parent_node = game[parent_id]
                            if parent_node.type == maximizer && !labeled[parent_id]
                                push!(new_queue, parent_id)
                            elseif parent_node.type == minimizer && !labeled[parent_id]
                                push!(average_to_min[labels[id]], parent_id)
                            end
                        end
                    end
                end
                queue = copy(new_queue)
                empty!(new_queue)
            end #end while loop
        end
        for key in keys(average_to_max)
            average_to_max[key] = Vector{Int}()
        end

        @inbounds for avg_node_id in reverse(average_node_order)
            #setup queue from known set
            empty!(queue)
            for node_id in average_to_min[avg_node_id]
                push!(queue, node_id)
            end

            while !isempty(queue)
                for id in queue
                    if !labeled[id]
                        labels[id] = avg_node_id
                        labeled[id] = true
                        for parent_id in parentmap[id]
                            parent_node = game[parent_id]
                            if parent_node.type == minimizer && !labeled[parent_id]
                                push!(new_queue, parent_id)
                            elseif parent_node.type == maximizer && !labeled[parent_id]
                                push!(average_to_max[labels[id]], parent_id)
                            end
                        end
                    end
                end
                queue = copy(new_queue)
                empty!(new_queue)
            end #end while loop
        end
        for key in keys(average_to_min)
            average_to_min[key] = Vector{Int}()
        end
    end#end while

    max_strat = Dict{Int,Int}()

    @inbounds for (id,node) in enumerate(game)
        if node.type == maximizer
            if labels[node.arc_a] == labels[id]
                max_strat[id] = node.arc_a
            else
                max_strat[id] = node.arc_b
            end
        end
    end

    return max_strat
end