"""
    generate_reduced_stopping_game(nmax::Int, nmin::Int, navg::Int)

Generate a stopping game without trivially solvable nodes
Returns::Vector{MutableSGNode}

# Arguments
- `nmax::Int`: the number of max nodes in the stopping game
- `nmin::Int`: the number of min nodes in the stopping game
- `navg::Int`: the number of avg nodes in the stopping game
"""
function generate_reduced_stopping_game(nmax::Int, nmin::Int, navg::Int)
    if navg<2
        println("Reduced stopping games must have at least 2 average nodes")
        return Vector{MutableSGNode}()
    end

    game = Vector{MutableSGNode}(undef,nmax+nmin+navg+2)
    parentmap = Dict{Int, Vector{Int}}()
    avgtracker = Vector{Int}()
    mtracker = Vector{Int}()
    sizehint!(avgtracker, navg)
    sizehint!(mtracker, nmax+nmin)

    #set terminals
    game[length(game)] = MutableSGNode(length(game), terminal1, 0, 0)
    game[length(game)-1] = MutableSGNode(length(game)-1, terminal0, 0, 0)

    #set the last two average nodes
    game[length(game)-2] = MutableSGNode(length(game)-2, average, length(game)-1, 0)
    game[length(game)-3] = MutableSGNode(length(game)-3, average, length(game), 0)

    #randomly assign the types of the remaining nodes
    randomorder = sample(1:length(game)-4, length(game)-4, replace = false)

    @inbounds for (i, assignment) in enumerate(randomorder)
        if i<=nmax
            game[assignment] = MutableSGNode(assignment, maximizer, 0, 0)
            push!(mtracker, assignment)
        elseif i<=nmax+nmin
            game[assignment] = MutableSGNode(assignment, minimizer, 0, 0)
            push!(mtracker, assignment)
        else
            game[assignment] = MutableSGNode(assignment, average, 0, 0)
            push!(avgtracker, assignment)
        end
    end
    push!(avgtracker, length(game)-2)
    push!(avgtracker, length(game)-3)

    #setup the parent map
    for node in eachindex(game)
        parentmap[node] = Vector{Int}()
    end
    push!(parentmap[length(game)-1], length(game)-2)
    push!(parentmap[length(game)], length(game)-3)

    #randomly assign the first arc for each nodes
    inzeronodes = Vector{Int}(1:length(game)-2)
    @inbounds for i in 1:length(game)-4
        if game[i].type == average
            game[i].arc_a = rand(i+1:length(game))
        else
            game[i].arc_a = rand(i+1:length(game)-2)
        end
        push!(parentmap[game[i].arc_a],i)
        if insorted(game[i].arc_a, inzeronodes)
            deleteat!(inzeronodes,searchsortedfirst(inzeronodes,game[i].arc_a))
        end
    end

    #pick a random number of average nodes to assign to in-zero nodes
    r = rand(max(length(inzeronodes)-(nmax+nmin),0):min(navg,length(inzeronodes)))

    #initialize average node second candidate list
    nodelist = Vector{Int}(1:length(game))

    #assign r average nodes to inzero nodes
    if r != 0
        @inbounds for i in 1:r
            currentnode = rand(avgtracker)
            removefromsortedlist!(currentnode, avgtracker)
            if assignsecondaveragearc!(game,  parentmap, inzeronodes, inzeronodes, currentnode) == -1
                i -= 1
                @inline assignsecondaveragearc!(game,  parentmap, inzeronodes, nodelist, currentnode)
            end
        end
    end
    #assign the remaining average arcs
    @inbounds for currentnode in avgtracker
        @inline assignsecondaveragearc!(game,  parentmap, inzeronodes, nodelist, currentnode)
    end

    #memory allocation for max/min node second candidate list
    candidatelist =  falses(length(game)-2)
    #memory pre-allocation for the bad subgraph checker
    reachablenodes = falses(length(game)-2)
    queue = Vector{Int}()
    queuetwo = Vector{Int}()
    sizehint!(queue, length(game)-2)
    sizehint!(queuetwo, length(game)-2)
    verybadnodes = falses(length(game)-2)

    #get an order for assigning arcs to the remaining nodes
    randomorder = sample(mtracker, length(mtracker), replace = false)
    run_main_loop_to_assign_second_arcs!(game, parentmap, inzeronodes, candidatelist, reachablenodes, queue, queuetwo, verybadnodes, randomorder)
    
    println("in-zeros:  ",length(inzeronodes))
    println("very bad nodes ", sum(verybadnodes))

    return game, parentmap
end

"""
    
    run_main_loop_to_assign_second_arcs!(game::Vector{MutableSGNode}, parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, candidatelist::BitVector, reachablenodes::BitVector, queue::Vector{Int}, queuetwo::Vector{Int}, verybadnodes::BitVector, assignmentorder::Vector{Int})

# Arguments
- `game::Vector{MutableSGNode}`: The partially generated Stopping Game
- `parentmap::Dict{Int, Vector{Int}}`: A map from nodes to a list of their parents
- `inzeronodes::Vector{Int}`: nodes with in-degree zero
- `candidatelist::BitVector`: A bit vector such that length(candidatelist) == length(game)-2 containing valid candidates for the destination of the arc
- `reachablenodes::BitVector`: A bit vector such that length(reachablenodes) == length(game)-2 
- `queue::Vector{Int}`:: A list of integers, preferred empty
- `queuetwo::Vector{Int}`: A list of integers, preferred empty
- `verybadnodes::BitVector`: A list of nodes that could not receive a second arc without becoming no good dirty rotten criminals
- `assignmentorder::Vector{Int}`: The order to assign arcs in
"""
function run_main_loop_to_assign_second_arcs!(game::Vector{MutableSGNode}, parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, candidatelist::BitVector, reachablenodes::BitVector, queue::Vector{Int}, queuetwo::Vector{Int}, verybadnodes::BitVector, assignmentorder::Vector{Int})
    #add the second arcs
    @inbounds for assignment in assignmentorder
        #if there are no in-zero nodes
        if isempty(inzeronodes)
            #reset the list
            candidatelist.=true
            #add the two starting forbidden elements
            candidatelist[assignment] = false
            candidatelist[game[assignment].arc_a] = false
            if assignsecondmaxminarc!(game,  parentmap, inzeronodes, candidatelist, reachablenodes, queue, queuetwo, verybadnodes, assignment) == -1
                #no second arc found add to rerun queue
                #should never happen
                verybadnodes[assignment] = true
            end
        #if there are in-zero nodes
        else
            #reset the list
            candidatelist.=false
            for node in inzeronodes
                candidatelist[node] = true
            end
            #add the two starting forbidden elements
            candidatelist[assignment] = false
            candidatelist[game[assignment].arc_a] = false
            if assignsecondmaxminarc!(game,  parentmap, inzeronodes, candidatelist, reachablenodes, queue, queuetwo, verybadnodes, assignment) == -1
                #reset the list to run without in-zeros
                candidatelist.=true
                #add the two starting forbidden elements
                candidatelist[assignment] = false
                candidatelist[game[assignment].arc_a] = false
                if assignsecondmaxminarc!(game,  parentmap, inzeronodes, candidatelist, reachablenodes, queue, queuetwo, verybadnodes, assignment) == -1 
                    #no second arc found add to rerun queue
                    #should never happen
                    verybadnodes[assignment] = true
                end
            end
        end
    end
end

"""
    assignsecondaveragearc!(game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, nodelist::Vector{Int}, origin::Int)

Assigns a second arc to an average node
Several parameters are only there so that they are pre-allocated for performance.
All paramaters except 'assignment' may be modified
Returns ::Int the node the arc is assigned to

# Arguments
- `game::Vector{MutableSGNode}`: The partially generated Stopping Game
- `parentmap::Dict{Int, Vector{Int}},`: A map from nodes to a list of their parents
- `inzeronodes::Vector{Int}`: nodes with in-degree zero
- `nodelist::Vector{Int}`:: equal to Vector{Int}(1:length(game)), pre-allocated for performance
- `origin::Int`: The node getting a second arc
"""
function assignsecondaveragearc!(game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, nodelist::Vector{Int}, origin::Int)
    newnode = getothernode(origin, game[origin].arc_a, nodelist)
    if newnode != -1
        game[origin].arc_b = newnode
        push!(parentmap[newnode],origin)
        removefromsortedlist!(newnode, inzeronodes)
        return newnode
    end
    return newnode
end

"""
    assignsecondmaxminarc!(game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, candidatelist::BitVector, reachablenodes::BitVector, queue::Vector{Int}, queuetwo::Vector{Int}, verybadnodes::BitVector, assignment::Int)

Assigns a second arc to a max or min node
Several parameters are only there so that they are pre-allocated for performance.
All paramaters except 'assignment' may be modified
Returns::Int the destination of the new arc

# Arguments
- `game::Vector{MutableSGNode}`: The partially generated Stopping Game
- `parentmap::Dict{Int, Vector{Int}},`: A map from nodes to a list of their parents
- `inzeronodes::Vector{Int}`: nodes with in-degree zero
- `candidatelist::BitVector`: A bit vector such that length(candidatelist) == length(game)-2 containing valid candidates for the destination of the arc
- `reachablenodes::BitVector`: A bit vector such that length(reachablenodes) == length(game)-2 
- `queue::Vector{Int}`:: A list of integers, preferred empty
- `queuetwo::Vector{Int}`: A list of integers, preferred empty
- `verybadnodes::BitVector`: A list of nodes that could not receive a second arc without becoming no good dirty rotten criminals
- `assignment::Int`: The node getting a second arc
"""
function assignsecondmaxminarc!(game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, candidatelist::BitVector, reachablenodes::BitVector, queue::Vector{Int}, queuetwo::Vector{Int}, verybadnodes::BitVector, assignment::Int)
    #get a new item
    newnode = getothernode(candidatelist)
    while newnode != -1
        game[assignment].arc_b = newnode
        push!(parentmap[newnode], assignment)
        if isbadsubgraph!(reachablenodes, queue, queuetwo, game,  parentmap, assignment, newnode)
            game[assignment].arc_b = 0
            pop!(parentmap[newnode])
            candidatelist[newnode] = false
            newnode = getothernode(candidatelist)
        else
            removefromsortedlist!(newnode, inzeronodes)
            break
        end
    end

    return newnode
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

"""
    getothernode(a::Int, b::Int, candidatelist::Vector{Int})

Returns::Int from candidatelist that is neither a nor b. If that is not possible, it returns -1

# Arguments
- `a::Int`: a forbidden value
- `b::Int`: a forbidden value
- `candidatelist::Vector{Int}`: the allowable values
"""
function getothernode(a::Int, b::Int, candidatelist::Vector{Int})
    if length(candidatelist)==1
        if first(candidatelist) == a || first(candidatelist)==b
            return -1 
        else
            return first(candidatelist)
        end
    elseif (length(candidatelist)==2 && a in candidatelist && b in candidatelist)
        return -1
    else
        num = rand(candidatelist)
        while num == a || num ==b
            num = rand(candidatelist)
        end
        return num
    end
end

"""
    getothernode(candidatelist::BitVector)

Returns::Int such that the value is the index of a true value in candidatelist. If that is not possible, it returns -1

# Arguments
- `candidatelist::BitVector`: allowable values
"""
function getothernode(candidatelist::BitVector)
    if isnothing(findfirst(candidatelist))
        return -1
    else
        return rand(findall(candidatelist))
    end
end

"""
    removefromsortedlist!(num::Int, list::Vector{Int})

Removes an Int from a sorted list, does nothing if the element is not present

# Arguments
- `num::Int`: The number to remove
- `list::Vector{Int}`:: The list to remove the number from
"""
function removefromsortedlist!(num::Int, list::Vector{Int})
    if insorted(num, list)
        deleteat!(list,searchsortedfirst(list,num))
    end
end








"""
    assignsecondmaxminarcnocheck!(game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, candidatelist::BitVector, assignment::Int)

Assigns a second arc to a max or min node
Several parameters are only there so that they are pre-allocated for performance.
All paramaters except 'assignment' may be modified
Returns::Int the destination of the new arc

# Arguments
- `game::Vector{MutableSGNode}`: The partially generated Stopping Game
- `parentmap::Dict{Int, Vector{Int}},`: A map from nodes to a list of their parents
- `inzeronodes::Vector{Int}`: nodes with in-degree zero
- `candidatelist::BitVector`: A bit vector such that length(candidatelist) == length(game)-2 containing valid candidates for the destination of the arc
- `assignment::Int`: The node getting a second arc
"""
function assignsecondmaxminarcnocheck!(game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, candidatelist::BitVector, assignment::Int)
    newnode = getothernode(candidatelist)
    if newnode == -1
        return -1
    end
    game[assignment].arc_b = newnode
    push!(parentmap[newnode], assignment)
    removefromsortedlist!(newnode, inzeronodes)
    return newnode
end

"""
    
    run_main_loop_to_assign_second_arcs_no_checks!(game::Vector{MutableSGNode}, parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, candidatelist::BitVector, assignmentorder::Vector{Int})

# Arguments
- `game::Vector{MutableSGNode}`: The partially generated Stopping Game
- `parentmap::Dict{Int, Vector{Int}}`: A map from nodes to a list of their parents
- `inzeronodes::Vector{Int}`: nodes with in-degree zero
- `candidatelist::BitVector`: A bit vector such that length(candidatelist) == length(game)-2 containing valid candidates for the destination of the arc
- `assignmentorder::Vector{Int}`: The order to assign arcs in
"""
function run_main_loop_to_assign_second_arcs_no_checks!(game::Vector{MutableSGNode}, parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, candidatelist::BitVector, assignmentorder::Vector{Int})
    #add the second arcs
    @inbounds for assignment in assignmentorder
        #if there are no in-zero nodes
        if isempty(inzeronodes)
            #reset the list
            candidatelist.=true
            #add the two starting forbidden elements
            candidatelist[assignment] = false
            candidatelist[game[assignment].arc_a] = false
            assignsecondmaxminarcnocheck!(game,  parentmap, inzeronodes, candidatelist, assignment)
        #if there are in-zero nodes
        else
            #reset the list
            candidatelist.=false
            for node in inzeronodes
                candidatelist[node] = true
            end
            #add the two starting forbidden elements
            candidatelist[assignment] = false
            candidatelist[game[assignment].arc_a] = false
            if assignsecondmaxminarcnocheck!(game,  parentmap, inzeronodes, candidatelist, assignment) == -1
                #reset the list to run without in-zeros
                candidatelist.=true
                #add the two starting forbidden elements
                candidatelist[assignment] = false
                candidatelist[game[assignment].arc_a] = false
                assignsecondmaxminarcnocheck!(game,  parentmap, inzeronodes, candidatelist, assignment)
            end
        end
    end
end

"""

    unmark_average_parents!(badnodes::BitVector, queue::Vector{Int},game::Vector{T},parentmap::Dict{Int, Vector{Int}})where{T<:Node}

Iteratively unmark average nodes pointing to unmarked nodes

# Arguments
- `badnodes::BitVector`: the marked nodes
- `queue::Vector{Int}`: the nodes to unmark
- `game::Vector{T}`: the stopping game
- `parentmap::Dict{Int, Vector{Int}`: map of nodes (indexes) to parents 
"""
function unmark_average_parents!(badnodes::BitVector, queue::Vector{Int},game::Vector{T},parentmap::Dict{Int, Vector{Int}})where{T<:Node}
    while !isempty(queue)
        i = pop!(queue)
        if badnodes[i]
            badnodes[i] = false
            @inbounds for parent in parentmap[i]
                if badnodes[parent] && game[parent].type == average
                    push!(queue,parent)
                end
            end
        end
    end
end

"""
    isbadsubgraphwithscc!(reachablenodes::BitVector, queue::Vector{Int}, newqueue::Vector{Int}, game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, origin::Int, destination::Int)

Checks if a partially generated Stopping Game would contain a bad subgraph if the provided arc was added
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
function isbadsubgraphwithscc!(reachablenodes::BitVector, queue::Vector{Int}, newqueue::Vector{Int}, game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, origin::Int, destination::Int, scc::Vector{Int})
    #setup reachable nodes list and queue
    reachablenodes .= false
    reachablenodes[destination] = true
    empty!(queue)
    empty!(newqueue)
    push!(queue, destination)

    #find reachable nodes
    @inbounds @simd for i in eachindex(reachablenodes)
        reachablenodes[i] = insorted(i,scc)
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
    return true
end

"""
    stabilize_tarjans!(unmarkqueue::Vector{Int},sccs::Vector{Vector{Int}}, game::Vector{T},parentmap::Dict{Int, Vector{Int}},badnodes::BitVector, stack::Vector{Int}, vindex::Vector{Int},vlowlink::Vector{Int}, vonstack::BitVector)where{T<:Node}
    
Iteratively runs tarjans and unmarks nodes until there are no changes

# Arguments
- `unmarkqueue::Vector{Int}`: nodes that have been unmarked
- `sccs::Vector{Vector{Int}}`: pre-allocated for performance
- `game::Vector{T}`: the SSG to consider
- `parentmap::Dict{Int, Vector{Int}}`: map off node (indexes) to parent (indexes)
- `badnodes::BitVector`: nodes that can be included
- `stack::Vector{Int}`: pre-allocated for performance
- `vindex::Vector{Int}`: pre-allocated for performance
- `vlowlink::Vector{Int}`: pre-allocated for performance
- `vonstack::BitVector`: pre-allocated for performance

"""
function stabilize_tarjans!(unmarkqueue::Vector{Int},sccs::Vector{Vector{Int}}, game::Vector{T},parentmap::Dict{Int, Vector{Int}},badnodes::BitVector, stack::Vector{Int}, vindex::Vector{Int},vlowlink::Vector{Int}, vonstack::BitVector)where{T<:Node}
    unstable = true
    while unstable
        unstable = false
        tarjans_strongly_connected_components!(game,badnodes,stack, vindex, vlowlink, vonstack,sccs)
      
        @inbounds for scc in sccs
            #if the components only has one node there is no loop
            if length(scc) == 1
                push!(unmarkqueue,first(scc))
            end
        end
        if !isempty(unmarkqueue)
            unstable = true 
            unmark_average_parents!(badnodes, unmarkqueue,game,parentmap)
        end
    end

    for scc in sccs
        sort!(scc)
    end
end

"""
    remove_bad_subgraphs_using_sccs!(mtracker::Vector{Int},inzeronodes::Vector{Int},reachablenodes::BitVector,queue::Vector{Int}, queuetwo::Vector{Int}, unmarkqueue::Vector{Int},sccs::Vector{Vector{Int}}, game::Vector{T},parentmap::Dict{Int, Vector{Int}},badnodes::BitVector, stack::Vector{Int}, vindex::Vector{Int},vlowlink::Vector{Int}, vonstack::BitVector)where{T<:Node}

Remove all bad subgraphs from the graph by iterating over the second arcs and removing any that are contained in a bad subgraph

# Arguments
- `mtracker::Vector{Int}`: the list of nodes removed by this function, pre-allocated for performance
- `inzeronodes::Vector{Int}`: list of nodes with in degree zero
- `reachablenodes::BitVector`: A bit vector such that length(reachablenodes) == length(game)-2, pre-allocated for performance
- `queue::Vector{Int}`:: A list of integers, preferred empty
- `queuetwo::Vector{Int}`: A list of integers, preferred empty
- `unmarkqueue::Vector{Int}`: nodes that have been unmarked
- `sccs::Vector{Vector{Int}}`: pre-allocated for performance
- `game::Vector{T}`: the SSG to consider
- `parentmap::Dict{Int, Vector{Int}}`: map off node (indexes) to parent (indexes)
- `badnodes::BitVector`: nodes that can be included
- `stack::Vector{Int}`: pre-allocated for performance
- `vindex::Vector{Int}`: pre-allocated for performance
- `vlowlink::Vector{Int}`: pre-allocated for performance
- `vonstack::BitVector`: pre-allocated for performance
"""
function remove_bad_subgraphs_using_sccs!(mtracker::Vector{Int},inzeronodes::Vector{Int},reachablenodes::BitVector,queue::Vector{Int}, queuetwo::Vector{Int}, unmarkqueue::Vector{Int},sccs::Vector{Vector{Int}}, game::Vector{T},parentmap::Dict{Int, Vector{Int}},badnodes::BitVector, stack::Vector{Int}, vindex::Vector{Int},vlowlink::Vector{Int}, vonstack::BitVector)where{T<:Node}
    empty!(mtracker)
    last_index_checked = length(badnodes)

    while last_index_checked-1>0 && !isnothing(findlast(badnodes[1:last_index_checked-1]))
        currentnode = findlast(badnodes[1:last_index_checked-1])
        last_index_checked = currentnode
        @inbounds for scc in sccs
            if insorted(currentnode, scc)
                if isbadsubgraphwithscc!(reachablenodes, queue, queuetwo, game,  parentmap, currentnode, game[currentnode].arc_b, scc)
                    deleteat!(parentmap[game[currentnode].arc_b],findfirst(x -> x==currentnode,parentmap[game[currentnode].arc_b]))
                    if isempty(parentmap[game[currentnode].arc_b])
                        insert!(inzeronodes,searchsortedfirst(inzeronodes,game[currentnode].arc_b),game[currentnode].arc_b)
                    end
                    game[currentnode].arc_b = 0
                    push!(mtracker, currentnode)
                    # unmark_average_parents!(badnodes, [currentnode],game,parentmap)
                    stabilize_tarjans!(unmarkqueue,sccs, game,parentmap,badnodes, stack, vindex,vlowlink, vonstack)
                end
                #println("num badnodes: ", sum(badnodes), "(bad subgraph checks)")
                break
            end
        end
    end
end

"""
    remove_specific_bad_subgraphs_using_sccs!(mtracker::Vector{Int}, process_queue::Vector{Int},inzeronodes::Vector{Int},reachablenodes::BitVector,queue::Vector{Int}, queuetwo::Vector{Int}, unmarkqueue::Vector{Int},sccs::Vector{Vector{Int}}, game::Vector{T},parentmap::Dict{Int, Vector{Int}},badnodes::BitVector, stack::Vector{Int}, vindex::Vector{Int},vlowlink::Vector{Int}, vonstack::BitVector)where{T<:Node}

Remove bad subgraphs from the graph by iterating over the second arcs from a node list and removing any that are contained in a bad subgraph

# Arguments
- `mtracker::Vector{Int}`: the list of nodes removed by this function, pre-allocated for performance
- `process_queue::Vector{Int}`: the list of nodes to consider, empty at the end
- `inzeronodes::Vector{Int}`: list of nodes with in degree zero
- `reachablenodes::BitVector`: A bit vector such that length(reachablenodes) == length(game)-2, pre-allocated for performance
- `queue::Vector{Int}`:: A list of integers, preferred empty
- `queuetwo::Vector{Int}`: A list of integers, preferred empty
- `unmarkqueue::Vector{Int}`: nodes that have been unmarked
- `sccs::Vector{Vector{Int}}`: pre-allocated for performance
- `game::Vector{T}`: the SSG to consider
- `parentmap::Dict{Int, Vector{Int}}`: map off node (indexes) to parent (indexes)
- `badnodes::BitVector`: nodes that can be included
- `stack::Vector{Int}`: pre-allocated for performance
- `vindex::Vector{Int}`: pre-allocated for performance
- `vlowlink::Vector{Int}`: pre-allocated for performance
- `vonstack::BitVector`: pre-allocated for performance
"""
function remove_specific_bad_subgraphs_using_sccs!(mtracker::Vector{Int}, process_queue::Vector{Int},inzeronodes::Vector{Int},reachablenodes::BitVector,queue::Vector{Int}, queuetwo::Vector{Int}, unmarkqueue::Vector{Int},sccs::Vector{Vector{Int}}, game::Vector{T},parentmap::Dict{Int, Vector{Int}},badnodes::BitVector, stack::Vector{Int}, vindex::Vector{Int},vlowlink::Vector{Int}, vonstack::BitVector)where{T<:Node}
    reverse!(process_queue)
    while !isempty(process_queue)
        currentnode = pop!(process_queue)
        @inbounds for scc in sccs
            if insorted(currentnode, scc)
                if isbadsubgraphwithscc!(reachablenodes, queue, queuetwo, game,  parentmap, currentnode, game[currentnode].arc_b, scc)
                    deleteat!(parentmap[game[currentnode].arc_b],findfirst(x -> x==currentnode,parentmap[game[currentnode].arc_b]))
                    if isempty(parentmap[game[currentnode].arc_b])
                        insert!(inzeronodes,searchsortedfirst(inzeronodes,game[currentnode].arc_b),game[currentnode].arc_b)
                    end
                    game[currentnode].arc_b = 0
                    push!(mtracker, currentnode)
                    stabilize_tarjans!(unmarkqueue,sccs, game,parentmap,badnodes, stack, vindex,vlowlink, vonstack)
                end
                #unmark_average_parents!(badnodes, [currentnode],game,parentmap)
                #println("num badnodes: ", sum(badnodes), "(bad subgraph checks)")
                break
            end
        end
    end
end

"""
    
    run_fallback_to_assign_second_arcs!(game::Vector{MutableSGNode}, parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, candidatelist::BitVector, reachablenodes::BitVector, queue::Vector{Int}, queuetwo::Vector{Int}, assignmentorder::Vector{Int})

# Arguments
- `game::Vector{MutableSGNode}`: The partially generated Stopping Game
- `parentmap::Dict{Int, Vector{Int}}`: A map from nodes to a list of their parents
- `inzeronodes::Vector{Int}`: nodes with in-degree zero
- `candidatelist::BitVector`: A bit vector such that length(candidatelist) == length(game)-2 containing valid candidates for the destination of the arc
- `reachablenodes::BitVector`: A bit vector such that length(reachablenodes) == length(game)-2 
- `queue::Vector{Int}`:: A list of integers, preferred empty
- `queuetwo::Vector{Int}`: A list of integers, preferred empty
- `assignmentorder::Vector{Int}`: The order to assign arcs in
"""
function run_fallback_to_assign_second_arcs!(game::Vector{MutableSGNode}, parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, candidatelist::BitVector, reachablenodes::BitVector, queue::Vector{Int}, queuetwo::Vector{Int}, assignmentorder::Vector{Int})
    #add the second arcs
    counter = 0
    @inbounds for assignment in assignmentorder
        counter += 1
        #println("assigning arc ",counter, "/",length(assignmentorder))
        #if there are no in-zero nodes
        if isempty(inzeronodes)
            #reset the list
            candidatelist.=true
            #add the two starting forbidden elements
            candidatelist[assignment] = false
            candidatelist[game[assignment].arc_a] = false
            assignsecondmaxminarc!(game,  parentmap, inzeronodes, candidatelist, reachablenodes, queue, queuetwo, assignment)
        #if there are in-zero nodes
        else
            #reset the list
            candidatelist.=false
            for node in inzeronodes
                candidatelist[node] = true
            end
            #add the two starting forbidden elements
            candidatelist[assignment] = false
            candidatelist[game[assignment].arc_a] = false
            if assignsecondmaxminarc!(game,  parentmap, inzeronodes, candidatelist, reachablenodes, queue, queuetwo, assignment) == -1
                #reset the list to run without in-zeros
                candidatelist.=true
                #add the two starting forbidden elements
                candidatelist[assignment] = false
                candidatelist[game[assignment].arc_a] = false
                assignsecondmaxminarc!(game,  parentmap, inzeronodes, candidatelist, reachablenodes, queue, queuetwo, assignment)
            end
        end
    end
end

"""
    assignsecondmaxminarc!(game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, candidatelist::BitVector, reachablenodes::BitVector, queue::Vector{Int}, queuetwo::Vector{Int}, assignment::Int)

Assigns a second arc to a max or min node
Several parameters are only there so that they are pre-allocated for performance.
All paramaters except 'assignment' may be modified
Returns::Int the destination of the new arc

# Arguments
- `game::Vector{MutableSGNode}`: The partially generated Stopping Game
- `parentmap::Dict{Int, Vector{Int}},`: A map from nodes to a list of their parents
- `inzeronodes::Vector{Int}`: nodes with in-degree zero
- `candidatelist::BitVector`: A bit vector such that length(candidatelist) == length(game)-2 containing valid candidates for the destination of the arc
- `reachablenodes::BitVector`: A bit vector such that length(reachablenodes) == length(game)-2 
- `queue::Vector{Int}`:: A list of integers, preferred empty
- `queuetwo::Vector{Int}`: A list of integers, preferred empty
- `assignment::Int`: The node getting a second arc
"""
function assignsecondmaxminarc!(game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, candidatelist::BitVector, reachablenodes::BitVector, queue::Vector{Int}, queuetwo::Vector{Int}, assignment::Int)
    #get a new item
    newnode = getothernode(candidatelist)
    while newnode != -1
        game[assignment].arc_b = newnode
        push!(parentmap[newnode], assignment)
        if isbadsubgraph!(reachablenodes, queue, queuetwo, game,  parentmap, assignment, newnode)
            game[assignment].arc_b = 0
            pop!(parentmap[newnode])
            candidatelist[newnode] = false
            newnode = getothernode(candidatelist)
        else
            removefromsortedlist!(newnode, inzeronodes)
            break
        end
    end

    return newnode
end

"""
    generate_reduced_stopping_game_efficient(nmax::Int, nmin::Int, navg::Int)

Generate a stopping game without trivially solvable nodes
This function has a bug somehwere that causes certain bad subgraphs to be missed
Returns::Vector{MutableSGNode}

# Arguments
- `nmax::Int`: the number of max nodes in the stopping game
- `nmin::Int`: the number of min nodes in the stopping game
- `navg::Int`: the number of avg nodes in the stopping game
- ``: whether or not to print progress
"""
function generate_reduced_stopping_game_efficient(nmax::Int, nmin::Int, navg::Int; logging_on::Bool=false)
    if navg<2
        println("Reduced stopping games must have at least 2 average nodes")
        return Vector{MutableSGNode}()
    end

    game = Vector{MutableSGNode}(undef,nmax+nmin+navg+2)
    parentmap = Dict{Int, Vector{Int}}()
    sizehint!(parentmap, length(game))
    avgtracker = Vector{Int}()
    mtracker = Vector{Int}()
    sizehint!(avgtracker, navg)
    sizehint!(mtracker, nmax+nmin)

    #set terminals
    game[length(game)] = MutableSGNode(length(game), terminal1, 0, 0)
    game[length(game)-1] = MutableSGNode(length(game)-1, terminal0, 0, 0)

    #set the last two average nodes
    game[length(game)-2] = MutableSGNode(length(game)-2, average, length(game)-1, 0)
    game[length(game)-3] = MutableSGNode(length(game)-3, average, length(game), 0)

    #randomly assign the types of the remaining nodes
    randomorder = sample(1:length(game)-4, length(game)-4, replace = false)

    @inbounds for (i, assignment) in enumerate(randomorder)
        if i<=nmax
            game[assignment] = MutableSGNode(assignment, maximizer, 0, 0)
            push!(mtracker, assignment)
        elseif i<=nmax+nmin
            game[assignment] = MutableSGNode(assignment, minimizer, 0, 0)
            push!(mtracker, assignment)
        else
            game[assignment] = MutableSGNode(assignment, average, 0, 0)
            push!(avgtracker, assignment)
        end
    end
    push!(avgtracker, length(game)-2)
    push!(avgtracker, length(game)-3)

    sort!(avgtracker)

    if logging_on
        println("Node types assigned")
    end

    #setup the parent map
    @inbounds for node in eachindex(game)
        parentmap[node] = Vector{Int}()
    end
    push!(parentmap[length(game)-1], length(game)-2)
    push!(parentmap[length(game)], length(game)-3)

    #randomly assign the first arc for each nodes
    inzeronodes = Vector{Int}(1:length(game)-2)
    @inbounds for i in 1:length(game)-4
        if game[i].type == average
            game[i].arc_a = rand(i+1:length(game))
        else
            game[i].arc_a = rand(i+1:length(game)-2)
        end
        push!(parentmap[game[i].arc_a],i)
        if insorted(game[i].arc_a, inzeronodes)
            deleteat!(inzeronodes,searchsortedfirst(inzeronodes,game[i].arc_a))
        end
    end
    
    if logging_on
        println("All first arcs assigned")
    end

    #pick a random number of average nodes to assign to in-zero nodes
    r = rand(max(length(inzeronodes)-(nmax+nmin),0):min(navg,length(inzeronodes)))

    #initialize average node second candidate list
    nodelist = Vector{Int}(1:length(game))
    
    #assign r average nodes to inzero nodes
    if r != 0
        @inbounds for i in 1:r
            currentnode = rand(avgtracker)
            removefromsortedlist!(currentnode, avgtracker)
            if assignsecondaveragearc!(game,  parentmap, inzeronodes, inzeronodes, currentnode) == -1
                i -= 1
                @inline assignsecondaveragearc!(game,  parentmap, inzeronodes, nodelist, currentnode)
            end
        end
    end
    #assign the remaining average arcs
    @inbounds for currentnode in avgtracker
        @inline assignsecondaveragearc!(game,  parentmap, inzeronodes, nodelist, currentnode)
    end

    if logging_on
        println("Second average arcs assigned")
    end

    #memory allocation for max/min node second candidate list
    candidatelist =  falses(length(game)-2)

    #get an order for assigning arcs to the remaining nodes
    randomorder = sample(mtracker, length(mtracker), replace = false)
    run_main_loop_to_assign_second_arcs_no_checks!(game, parentmap, inzeronodes, candidatelist, randomorder)  

    if logging_on
        println("First attempt at second arc assignments finished")
    end

    badnodes = trues(length(game))
    unmarkqueue = Vector{Int}(length(game)-1:length(game))
    sizehint!(unmarkqueue, length(game))
    unmark_average_parents!(badnodes, unmarkqueue,game,parentmap)
    badnodes_quick_start = copy(badnodes)
    #find the strongly connected components
    stack = Vector{Int}()
    sizehint!(stack, length(game))
    vindex = zeros(Int,length(game))
    vlowlink = zeros(Int,length(game))
    vonstack = falses(length(game))
    sccs = Vector{Vector{Int}}()
    sizehint!(sccs, length(game))
    stabilize_tarjans!(unmarkqueue,sccs, game,parentmap,badnodes, stack, vindex,vlowlink, vonstack)

    if logging_on
        println("Tarjans stabilized: first iteration")
        print("    connected component sizes: ")
        for scc in sccs
            print(length(scc),"  ")
        end
        println()
    end

    #memory pre-allocation for the bad subgraph checker
    reachablenodes = falses(length(game)-2)
    queue = Vector{Int}()
    queuetwo = Vector{Int}()
    sizehint!(queue, length(game)-2)
    sizehint!(queuetwo, length(game)-2)

    #now that sccs is stable start from the end and check for badsubgraphs
    mtracker = Vector{Int}()
    sizehint!(mtracker, length(badnodes))
    remove_bad_subgraphs_using_sccs!(mtracker,inzeronodes,reachablenodes,queue, queuetwo, unmarkqueue,sccs, game,parentmap,badnodes, stack, vindex,vlowlink, vonstack)
    
    # check_for_bad_subgraphs(game)
    # println("Checked")

    if logging_on
        println("Bad subgraphs removed during first iteration: ",length(mtracker), "\n   In-zeros: ", length(inzeronodes))
        println()
    end

    #get an order for assigning arcs to the remaining nodes
    new_mtracker = Vector{Int}()
    sizehint!(new_mtracker, length(mtracker))
    pre_missing_arc_count = length(mtracker)
    post_missing_arc_count =  0
    repeat_count = 0
    repeat_cap = max(floor(Int,log(2,length(game))/2),2)

    while !isempty(mtracker) && (pre_missing_arc_count != post_missing_arc_count ||  repeat_count <= repeat_cap)
        if pre_missing_arc_count == post_missing_arc_count
            repeat_count += 1
        elseif repeat_count != 0
            repeat_count = 0
        end

        pre_missing_arc_count = length(mtracker)
        randomorder = sample(mtracker, length(mtracker), replace = false)
        run_main_loop_to_assign_second_arcs_no_checks!(game, parentmap, inzeronodes, candidatelist, randomorder)  
        badnodes .= badnodes_quick_start
        stabilize_tarjans!(unmarkqueue,sccs, game,parentmap,badnodes, stack, vindex,vlowlink, vonstack)
        remove_specific_bad_subgraphs_using_sccs!(new_mtracker,mtracker,inzeronodes,reachablenodes,queue, queuetwo, unmarkqueue,sccs, game,parentmap,badnodes, stack, vindex,vlowlink, vonstack)
        mtracker = copy(new_mtracker)
        empty!(new_mtracker)
        post_missing_arc_count = length(mtracker)
        if logging_on
            println("Bad subgraphs removed during iteration: ",length(mtracker), "\n   In-zeros: ", length(inzeronodes))
        end
    end

    # check_for_bad_subgraphs(game)
    # println("Checked2")

    if logging_on
        println("in-zeros after iterative random assignment:  ",length(inzeronodes))
    end

    #get an order for assigning arcs to the remaining nodes
    randomorder = sample(mtracker, length(mtracker), replace = false)
    run_fallback_to_assign_second_arcs!(game, parentmap, inzeronodes, candidatelist, reachablenodes, queue, queuetwo, randomorder)

    # check_for_bad_subgraphs(game)
    # println("Checked3")


    if logging_on
        println("in-zeros after all arcs assigned:  ",length(inzeronodes))
    end

    potential_parents = copy(inzeronodes)
    for i in inzeronodes
        #can't use nodes that have only one out arc as parents
        if length(parentmap[game[i].arc_b]) == 1
            deleteat!(potential_parents,searchsortedfirst(potential_parents,i))
        end
    end
    while length(inzeronodes) > 1 && length(potential_parents) > 1
        new_parent = rand(potential_parents)
        new_child = rand(inzeronodes)
        if new_parent == new_child && length(inzeronodes) == 1 && length(potential_parents) == 1
            break
        end
        while new_parent == new_child
            if length(inzeronodes) == 1
                new_parent = rand(potential_parents)
            else
                new_child = rand(inzeronodes)
            end
        end
        deleteat!(
            parentmap[game[new_parent].arc_b],
            findfirst(
                x -> x==new_parent,
                parentmap[game[new_parent].arc_b]
            )
        )
        game[new_parent].arc_b = new_child
        push!(parentmap[new_child], new_parent)
        deleteat!(inzeronodes,searchsortedfirst(inzeronodes,new_child))
        deleteat!(potential_parents,searchsortedfirst(potential_parents,new_parent))
        if new_child in potential_parents
            deleteat!(
                potential_parents,
                findfirst(x -> x==new_child,potential_parents)
            )
        end
    end

    if logging_on
        println("number of in-zeros reduced to:  ",length(inzeronodes))
    end

    # check_for_bad_subgraphs(game)
    # println("Checked4")

    while !isempty(inzeronodes)
        last_in_zero = first(inzeronodes)
        trial_order = sample(1:length(game)-4, length(game)-4, replace = false)
        deleteat!(trial_order, findfirst(x -> x==last_in_zero,trial_order))
        for node_index in trial_order
            old_child = game[node_index].arc_b
            #if the node being considered is a single parent to its arc_b node, skip it
            if length(parentmap[old_child])>1
                game[node_index].arc_b = last_in_zero
                push!(parentmap[last_in_zero], node_index)
                deleteat!(parentmap[old_child],findfirst(x -> x==node_index,parentmap[old_child]))
                if isbadsubgraph!(reachablenodes, queue, queuetwo, game,  parentmap, node_index, last_in_zero)
                    game[node_index].arc_b = old_child
                    pop!(parentmap[last_in_zero])
                    push!(parentmap[old_child], node_index)
                else
                    deleteat!(inzeronodes, 1)
                    break
                end
            end
        end
    end

    # check_for_bad_subgraphs(game)
    # println("Checked End")

    # find_bugs(game, parentmap, inzeronodes)

    if isempty(inzeronodes)
        if logging_on
            println("Game successfully created!")
        end
    else
        if logging_on
            println("Heuristic failed, Trying again.")
        end
        return generate_reduced_stopping_game_efficient(nmax, nmin, navg, logging_on=logging_on)
    end

    return game, parentmap
end

"""
    remove_bad_subgraphs_slow!(mtracker::Vector{Int},inzeronodes::Vector{Int},reachablenodes::BitVector,queue::Vector{Int}, queuetwo::Vector{Int}, game::Vector{T},parentmap::Dict{Int, Vector{Int}},badnodes::BitVector)where{T<:Node}

Remove all bad subgraphs from the graph by iterating over the b arcs and removing any that are contained in a bad subgraph

# Arguments
- `mtracker::Vector{Int}`: the list of nodes removed by this function, pre-allocated for performance
- `inzeronodes::Vector{Int}`: list of nodes with in degree zero
- `reachablenodes::BitVector`: A bit vector such that length(reachablenodes) == length(game)-2, pre-allocated for performance
- `queue::Vector{Int}`:: A list of integers, preferred empty
- `queuetwo::Vector{Int}`: A list of integers, preferred empty
- `game::Vector{T}`: the SSG to consider
- `parentmap::Dict{Int, Vector{Int}}`: map off node (indexes) to parent (indexes)
- `badnodes::BitVector`: nodes that can be included
"""
function remove_bad_subgraphs_slow!(mtracker::Vector{Int},inzeronodes::Vector{Int},reachablenodes::BitVector,queue::Vector{Int}, queuetwo::Vector{Int}, game::Vector{T},parentmap::Dict{Int, Vector{Int}},badnodes::BitVector)where{T<:Node}
    empty!(mtracker)
    for (currentnode, isbad) in enumerate(badnodes)
        if isbad && isbadsubgraph!(reachablenodes, queue, queuetwo, game,  parentmap, currentnode, game[currentnode].arc_b)
            deleteat!(parentmap[game[currentnode].arc_b],findfirst(x -> x==currentnode,parentmap[game[currentnode].arc_b]))
            if isempty(parentmap[game[currentnode].arc_b])
                insert!(inzeronodes,searchsortedfirst(inzeronodes,game[currentnode].arc_b),game[currentnode].arc_b)
            end
            game[currentnode].arc_b = 0
            push!(mtracker, currentnode)
        end
    end
end








function find_bugs(game, parentmap, inzeronodes)
     #debug check
     for node in game 
        parents = parentmap[node.label]
        if isempty(parents) && !(node.label in inzeronodes)
            println("Bug Type 1: ", node.label)
        end
        for parent in parents
            if game[parent].arc_a != node.label && game[parent].arc_b != node.label
                println("Bug Type 2: ", node.label)
            end
        end
        if node.label != length(game) && node.label != length(game)-1
            if !(node.label in parentmap[node.arc_a]) || !(node.label in parentmap[node.arc_b])
                println("Bug Type 3: ", node.label)
            end
        end
    end
end


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


function find_stupid(d,b,c)
    while true
        a, parentmap = generate_reduced_stopping_game_efficient(d, b, c; logging_on=false)
        if check_for_bad_subgraphs(a)
            return a
        end
    end
end