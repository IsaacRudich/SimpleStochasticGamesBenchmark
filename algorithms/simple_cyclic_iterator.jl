function simple_cyclic_iterator(game::Vector{SGNode})
    t_one,t_zero = getterminalindexes(game)
    values = Dict{Int, Float64}()
    strategies = Dict{Int, Int}()

    q1 = Vector{Int}()
    q2 = Vector{Int}()
    q3 = Vector{Int}()
    sizehint!(q1, length(game))
    sizehint!(q2, length(game))
    sizehint!(q3, length(game))

    processed_nodes = Vector{Int}()
    sizehint!(processed_nodes, length(game))

    node_to_proc = first(game)
    for i in 1:length(game)^2
        empty!(q1)
        empty!(q2)
        empty!(q3)
        empty!(processed_nodes)
        push!(processed_nodes, t_one)
        push!(q1, t_one)

        while !isempty(q1) || !isempty(q2) || !isempty(q3)
            if !isempty(q1)
                node_to_proc = pop!(q1)
            elseif !isempty(q2)
                node_to_proc = pop!(q2)
            elseif !isempty(q3)
                node_to_proc = pop!(q3)
            end

            if node_to_proc in processed_nodes
                continue
            end

            sci_subprocess!(strategies,game, node, values)

            push!(processed_nodes,node_to_proc)

            for child in [game[node].arc_a,game[node].arc_b]
                if child in processed_nodes
                    continue
                end
            end
        end
    end
end

function sci_subprocess!(strategies::Dict{Int, Int},game::Vector::SGNode,node_id::Int, values::Dict{Int, Float64})
    node = game[node_id]
    
    if node.type == maximizer
        if values[node.arc_a] > values[node.arc_b]
            strategies[node_id] = node.arc_a
        else
            strategies[node_id] = node.arc_b
        end
    elseif node.type == minimizer
        if values[node.arc_a] < values[node.arc_b]
            strategies[node_id] = node.arc_a
        else
            strategies[node_id] = node.arc_b
        end
    end
end