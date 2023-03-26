"""
    count_average_switches(average_node_orders::Vector{Vector{Int}})

Prints useful info about the average nodes

# Arguments
- `average_node_orders::Vector{Vector{Int}}`: The average node order over time
"""
function count_average_switches(average_node_orders::Vector{Vector{Int}})
    println("Average Node Orders")
    for order in average_node_orders
        println(order)
    end
    pos_map = Dict{Int, Vector{Int}}()

    #initalize lists

    for e in first(average_node_orders)
        pos_map[e] = Vector{Int}()
        sizehint!(pos_map[e],length(average_node_orders))
    end
    average_nodes = copy(first(average_node_orders))

    #maps each node to its position over time
    for order in average_node_orders
        for (i,e) in enumerate(order)
            push!(pos_map[e], i)
        end
    end


    #track changes to order, when the neighborhood changes
    left_neighbor_switches = Dict{Int, Int}()
    right_neighbor_switches = Dict{Int, Int}()
    for node in average_nodes
        left_neighbor_switches[node] = 0
        right_neighbor_switches[node] = 0
    end
    neighbor = 0
    next_node_pos = 0
    next_neighbor_pos = 0
    for itr in 1:lastindex(average_node_orders)-1
        order = average_node_orders[itr]
        for (i,node_index) in enumerate(order)
            next_node_pos = pos_map[node_index][itr+1]
            #handle left neighbor
            if i>1
                neighbor = order[i-1]
                next_neighbor_pos = pos_map[neighbor][itr+1]
                if next_neighbor_pos > next_node_pos
                    left_neighbor_switches[node_index] += 1
                end
            end
            #handle right neighbor
            if i<length(order)
                neighbor = order[i+1]
                next_neighbor_pos = pos_map[neighbor][itr+1]
                if next_neighbor_pos < next_node_pos
                    right_neighbor_switches[node_index] += 1
                end
            end
        end
    end

    for node in average_nodes
        println("$node -> {",left_neighbor_switches[node],",",right_neighbor_switches[node],"}  ", pos_map[node])
    end
end