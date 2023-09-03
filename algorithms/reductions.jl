"""
    find_ones_or_zeros(find_ones::Bool, game::Vector{SGNode}, parentmap::Dict{Int, Vector{Int}})

A method thhat find all of the nodes in a game that collapse to a value of 1

# Arguments
- `find_ones::Bool`: if true, finds the ones, else finds the zeros
- `game::Union{Vector{SGNode},Vector{MutableSGNode}}`: The SSG
- `parentmap::Dict{Int, Vector{Int}}`: Map to the parents of the nodes
"""
function find_ones_or_zeros(find_ones::Bool, game::Union{Vector{SGNode},Vector{MutableSGNode}}, parentmap::Dict{Int, Vector{Int}})
    collapsing_cluster = trues(length(game))
    queue = Vector{Int}()

    for index in Iterators.reverse(1:length(game))
        if find_ones && game[index].type == terminal0
            collapsing_cluster[index] = false
            push!(queue, index)
            break
        elseif !find_ones && game[index].type == terminal1
            collapsing_cluster[index] = false
            push!(queue, index)
            break
        end
    end

    

    while !isempty(queue)
        currrent_index = pop!(queue)
        for parent in parentmap[currrent_index]
            if collapsing_cluster[parent]
                if find_ones
                    if game[parent].type==minimizer || game[parent].type==average
                        collapsing_cluster[parent] = false
                        push!(queue,parent)
                    elseif game[parent].type==maximizer && !collapsing_cluster[game[parent].arc_a] && !collapsing_cluster[game[parent].arc_b]
                        collapsing_cluster[parent] = false
                        push!(queue,parent)
                    end
                else
                    if game[parent].type==maximizer || game[parent].type==average
                        collapsing_cluster[parent] = false
                        push!(queue,parent)
                    elseif game[parent].type==minimizer && !collapsing_cluster[game[parent].arc_a] && !collapsing_cluster[game[parent].arc_b]
                        collapsing_cluster[parent] = false
                        push!(queue,parent)
                    end
                end
            end
        end
    end

    for node in 1:lastindex(game)-2
        if find_ones && collapsing_cluster[node]
            if (!collapsing_cluster[game[node].arc_a] || !collapsing_cluster[game[node].arc_b]) && (game[node].type == average || game[node].type == minimizer)
                println(node.type," ", node)
            elseif game[node].type == maximizer && (!collapsing_cluster[game[node].arc_a] && !collapsing_cluster[game[node].arc_b])
                println("Max: ", node)
            end
        end
    end

    return collapsing_cluster
end

"""
    remove_ones_and_zeros(game::Vector{SGNode}, parentmap::Dict{Int, Vector{Int}})

A method that removes all the zeros and ones from a game and returns a game without those nodes

# Arguments
- `game::Union{Vector{SGNode},Vector{MutableSGNode}}`: The SSG
- `parentmap::Dict{Int, Vector{Int}}`: Map to the parents of the nodes
"""
function remove_ones_and_zeros(game::Union{Vector{SGNode},Vector{MutableSGNode}}, parentmap::Dict{Int, Vector{Int}})
    ones_vector = find_ones_or_zeros(true, game, parentmap)
    zeros_vector = find_ones_or_zeros(false, game, parentmap)

    #shift the arcs to the terminals
    if game isa Vector{SGNode}
        m_game = getmutablegame(game)
    else
        m_game = game
    end
    t_one,t_zero = getterminalindexes(game)
    for node in m_game
        if node.arc_a>0 && ones_vector[node.arc_a]
            node.arc_a = t_one
        elseif node.arc_a>0 && zeros_vector[node.arc_a]
            node.arc_a = t_zero
        end
        if node.arc_b>0 && ones_vector[node.arc_b]
            node.arc_b = t_one
        elseif node.arc_b>0 && zeros_vector[node.arc_b]
            node.arc_b = t_zero
        end
    end

    #delete the non terminal ones and zeros
    removables = Vector{Int}()
    sizehint!(removables, sum(ones_vector)+sum(zeros_vector)-2)
    for i in 1:lastindex(ones_vector)
        if (ones_vector[i] || zeros_vector[i]) && i!=t_one && i !=t_zero
            push!(removables, i)
        end
    end

    deleteat!(m_game, removables)

    #reindex the remaining nodes
    indexmap = Dict{Int, Int}(0 => 0)
    for (i,node) in enumerate(m_game)
        indexmap[node.label] = i
    end

    for node in m_game
        node.label = indexmap[node.label]
        node.arc_a = indexmap[node.arc_a]
        node.arc_b = indexmap[node.arc_b]
    end

    return getstaticgame(m_game)
end

"""
    sort_into_sccs(game::Vector{SGNode})

A method that sorts the game into a tree of sccs

# Arguments
- `game::Vector{SGNode}`: The SSG
"""
function sort_into_sccs(game::Vector{SGNode})
    nodestoconsider = trues(length(game))
    stack = Vector{Int}()
    sizehint!(stack, length(game))
    vindex = zeros(Int,length(game))
    vlowlink = zeros(Int,length(game))
    vonstack = falses(length(game))
    sccs = Vector{Vector{Int}}()

    tarjans_strongly_connected_components!(game,nodestoconsider, stack, vindex,vlowlink, vonstack,sccs)

    t_one,t_zero = getterminalindexes(game)
    orderedsccs = Vector{Vector{Int}}()
    endpoints = falses(length(game))

    #get the terminals
    endpoints[t_one] = true
    endpoints[t_zero] = true
    for (i,scc) in enumerate(sccs)
        if scc == [t_one]
            push!(orderedsccs, scc)
            deleteat!(sccs,i)
            break
        end
    end
    for (i,scc) in enumerate(sccs)
        if scc == [t_zero]
            push!(orderedsccs, scc)
            deleteat!(sccs,i)
            break
        end
    end

    #get the rest 
    isendpoint = true
    removables = Vector{Int}()
    while !isempty(sccs)
        empty!(removables)
        for (i,scc) in enumerate(sccs)
            isendpoint = true
            for e in scc
                if (!endpoints[game[e].arc_a] && !(game[e].arc_a in scc))|| (!endpoints[game[e].arc_b]  && !(game[e].arc_b in scc))
                    isendpoint = false
                    break
                end
            end
            if isendpoint
                for e in scc
                    endpoints[e] = true
                end
                push!(removables,i)
                push!(orderedsccs,scc)
            end
        end
        deleteat!(sccs, removables)
    end

    reverse!(orderedsccs)
    return orderedsccs
end

"""
    reindex_by_sccs(game::Vector{SGNode},orderedsccs::Vector{Vector{Int}})

A method that reindexes an SSG based on an ordered list of SCCs

# Arguments
- `game::Vector{SGNode}`: The SSG
- `orderedsccs::Vector{Vector{Int}}`: the sccs
"""
function reindex_by_sccs(game::Vector{SGNode},orderedsccs::Vector{Vector{Int}})
    #reindex the remaining nodes
    indexmap = Dict{Int, Int}(0 => 0)
    counter = 1
    for scc in orderedsccs
        for e in scc
            indexmap[e] = counter
            counter += 1
        end
    end

    m_game = getmutablegame(game)

    for node in m_game
        node.label = indexmap[node.label]
        node.arc_a = indexmap[node.arc_a]
        node.arc_b = indexmap[node.arc_b]
    end

    sort!(m_game, by = x -> x.label)
    return getstaticgame(m_game)
end

"""
    remove_single_arc_nodes(reducedgame::Vector{SGNode})

Reduces and reindexes a SSG so that it is has no one arc nodes
Return (Vector{SGNode}) the reduced game

# Arguments
- `reducedgame::Vector{SGNode}`: The SSG
"""
function remove_single_arc_nodes(reducedgame::Vector{SGNode})
    parentmap = get_parent_map(reducedgame)
    t_one,t_zero = getterminalindexes(reducedgame)
    reducedgame = getmutablegame(reducedgame)
    unchanged = false
    while !unchanged
        unchanged = true
        for (i,node) in enumerate(reducedgame)
            if node.type == maximizer && (node.arc_a==t_zero || node.arc_b==t_zero)
                if node.arc_a == t_zero
                    endpoint = node.arc_b
                else 
                    endpoint = node.arc_a
                end
                for parent in parentmap[i]
                    if reducedgame[parent].arc_a == i
                        reducedgame[parent].arc_a = endpoint
                    else
                        reducedgame[parent].arc_b = endpoint
                    end
                end
                deleteat!(reducedgame,i)
                unchanged = false
                break
            elseif node.type == minimizer && (node.arc_a==t_one || node.arc_b==t_one)
                if node.arc_a == t_one
                    endpoint = node.arc_b
                else 
                    endpoint = node.arc_a
                end
                for parent in parentmap[i]
                    if reducedgame[parent].arc_a == i
                        reducedgame[parent].arc_a = endpoint
                    else
                        reducedgame[parent].arc_b = endpoint
                    end
                end
                deleteat!(reducedgame,i)
                unchanged = false
                break
            end
        end
        #reindex
        if !unchanged
            indexmap = Dict{Int, Int}(0 => 0)
            for (i,node) in enumerate(reducedgame)
                indexmap[node.label] = i
            end
            for node in reducedgame
                node.label = indexmap[node.label]
                node.arc_a = indexmap[node.arc_a]
                node.arc_b = indexmap[node.arc_b]
            end
            parentmap = get_parent_map(reducedgame)
            t_one,t_zero = getterminalindexes(reducedgame)
        end
    end
    return getstaticgame(reducedgame)
end

"""
    reduce_game(game::Vector{SGNode}, parentmap::Dict{Int, Vector{Int}})

Reduces a reindexes a SSG so that it is sorted by its SCCs
Return (Vector{SGNode}, Vector{Vector{Int}}) the reduced game and the scc associated with it

# Arguments
- `game::Union{Vector{SGNode},Vector{MutableSGNode}}`: The SSG
- `parentmap::Dict{Int, Vector{Int}}`: Map to the parents of the nodes
"""
function reduce_game(game::Union{Vector{SGNode},Vector{MutableSGNode}}, parentmap::Dict{Int, Vector{Int}})
    reducedgame = remove_ones_and_zeros(game, parentmap)
    reducedgame = remove_single_arc_nodes(reducedgame::Vector{SGNode})
    orderedsccs = sort_into_sccs(reducedgame)
    reducedgame = reindex_by_sccs(reducedgame,orderedsccs)

    orderedsccs = sort_into_sccs(reducedgame)
    
    return reducedgame, orderedsccs
end