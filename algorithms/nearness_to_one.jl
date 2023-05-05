function solve_using_nearness_to_one(game::Vector{SGNode};parentmap::Union{Nothing,Dict{Int, Vector{Int}}}=nothing)
    t_one,t_zero = getterminalindexes(game)
    
    if isnothing(parentmap)
        parentmap = get_parent_map(game)
    end

    queue = falses(length(game))
    queue[t_one] = true

    #phase one, add all collapsing nodes
    @inline add_average_parents!(queue, game, parentmap)
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
    average_parents = falses(length(game))
    is_added = true
    while is_added
        is_added = false
        average_parents .= false

        for (i,node) in enumerate(game)
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
    decision = Dict{Int, Int}()
    for (i,node) in enumerate(game)

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
    set = set .| average_parents
end