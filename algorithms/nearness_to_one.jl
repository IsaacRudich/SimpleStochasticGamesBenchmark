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
    for i in 1:length(game)
        println(i, " => ", round(values[i],digits = 4))
    end
end

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