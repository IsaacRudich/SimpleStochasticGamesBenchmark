"""
    check_for_bad_subgraphs(game::Union{Vector{SGNode},Vector{MutableSGNode}})

Debug function to verify games are valid

# Arguments
- `game::Vector{T}`: the SSG to consider
"""
function check_for_bad_subgraphs(game::Union{Vector{SGNode},Vector{MutableSGNode}})
    reachablenodes = falses(length(game)-2)
    queue = Vector{Int}()
    queuetwo = Vector{Int}()
    sizehint!(queue, length(game)-2)
    sizehint!(queuetwo, length(game)-2)

    m_game = Vector{MutableSGNode}()
    sizehint!(m_game, length(game))

    parentmap = Dict{Int,Vector{Int}}()

    for (i,node) in enumerate(game)
        parentmap[i] = Vector{Int}()
    end

    for (i,node) in enumerate(game)
        push!(m_game, MutableSGNode(i, node.type, node.arc_a, node.arc_b))
        if node.arc_a > 0
            push!(parentmap[node.arc_a], i)
        end
        if node.arc_b > 0
            push!(parentmap[node.arc_b], i)
        end
    end

    for (node_index, node) in enumerate(m_game)
        if node.type!=average && node_index < length(game)-1 && node.arc_b > 0 && node.arc_b < length(game)-1
            if isbadsubgraph!(reachablenodes, queue, queuetwo, m_game,  parentmap, node_index, node.arc_b)
                println("BAD SUBGRAPH FOUND!")
                println("Parent of Subgraph: ",node_index)
                # println(node)
                return true
            end
        end
    end

    println("No Bad Subgraphs")
    return false
end

"""
    isbadsubgraph!(reachablenodes::BitVector, queue::Vector{Int}, newqueue::Vector{Int}, game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, origin::Int, destination::Int)

Checks if a partially generated Stopping Game would contain a bad subgraph is the provided arc was added
The first three parameters do not need to contain accurate information, they are pre-allocated for performance purposes
Returns::Bool

# Arguments
- `reachablenodes::BitVector`: A bit vector such that length(reachablenodes) == length(game)-2 
- `queue::Vector{Int}`:: A list of integers, preferred empty
- `newqueue::Vector{Int}`: A list of integers, preferred empty
- `game::Vector{MutableSGNode}`: The partially generated Stopping Game
- `parentmap::Dict{Int, Vector{Int}},`: A map from nodes to a list of their parents
- `origin::Int`: The origin of the arc being added
- `destination::Int`: The destination of the arc being added
"""
function isbadsubgraph!(reachablenodes::BitVector, queue::Vector{Int}, newqueue::Vector{Int}, game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, origin::Int, destination::Int)
    #setup reachable nodes list and queue
    reachablenodes .= false
    reachablenodes[destination] = true
    empty!(queue)
    empty!(newqueue)
    push!(queue, destination)

    #finds all reachable nodes in breadth first search
    #excludes the last 4 search
    while !isempty(queue)
        for node in queue
            if node != origin || game[node].type == average
                if game[node].arc_a < length(game)-3 && !reachablenodes[game[node].arc_a]
                    reachablenodes[game[node].arc_a] = true
                    push!(newqueue, game[node].arc_a)
                end
                if game[node].arc_b < length(game)-3 && game[node].arc_b > 0 && !reachablenodes[game[node].arc_b]
                    reachablenodes[game[node].arc_b] = true
                    push!(newqueue, game[node].arc_b)
                end
            end
        end
        queue = copy(newqueue)
        empty!(newqueue)
    end

    #if the origin of the added arc is not reachable, no bad subgraph was created
    if !reachablenodes[origin]
        return false
    end

    #iteratively remove nodes until graph is provably good or bad
    noderemoved = true
    while noderemoved
        noderemoved = false
        for i in eachindex(reachablenodes)
            if reachablenodes[i]
                if game[i].type == average
                    #if either arc of an average node points somewhere not reachable
                    if (game[i].arc_a > length(game)-2 || !reachablenodes[game[i].arc_a]) || game[i].arc_b > length(game)-2  || (game[i].arc_b > 0 && !reachablenodes[game[i].arc_b])
                        reachablenodes[i] = false
                        noderemoved = true
                    end
                end
                #if the previous if statment did not trigger, try remove due to no out arcs
                if reachablenodes[i]
                    #if neither arc points to a reachable node, accounting for possible nonexistent second arcs
                    if (game[i].arc_a > length(game)-2 || !reachablenodes[game[i].arc_a]) && (game[i].arc_b > length(game)-2 || (game[i].arc_b > 0 && !reachablenodes[game[i].arc_b]) || game[i].arc_b <= 0)
                        reachablenodes[i] = false
                        noderemoved = true
                    end
                end
                #if the previous if statment did not trigger, try remove due to no in arcs
                if reachablenodes[i]
                    noparent = true
                    for p in parentmap[i]
                        if reachablenodes[p]
                            noparent = false
                            break
                        end
                    end
                    if noparent
                        reachablenodes[i] = false
                        noderemoved = true
                    end
                end

                #check if proof achieved
                if (i == origin && !reachablenodes[origin]) || (i == destination && !reachablenodes[destination])
                    return false
                end
            end
        end
    end
    # print("Bad Subgraph in: ")
    # for (i,val) in enumerate(reachablenodes)
    #     if val
    #         print(i," ")
    #     end
    # end
    # println()
    return true
end