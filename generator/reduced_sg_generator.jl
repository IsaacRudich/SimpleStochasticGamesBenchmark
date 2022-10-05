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
        throw("reduced stopping games must have at least 2 average nodes")
    end

    game = Vector{MutableSGNode}(undef,nmax+nmin+navg+2)
    parentmap = Dict{Int, Vector{Int}}()
    sizehint!(parentmap, length(game))

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
        elseif i<=nmax+nmin
            game[assignment] = MutableSGNode(assignment, minimizer, 0, 0)
        else
            game[assignment] = MutableSGNode(assignment, average, 0, 0)
        end
    end

    #setup the parent map
    for node in eachindex(game)
        parentmap[node] = Vector{Int}()
    end
    push!(parentmap[length(game)-1], length(game)-2)
    push!(parentmap[length(game)], length(game)-3)

    #randomly assign the first arc for each nodes
    inzeronodes = Vector{Int}(1:length(game)-2)
    @timeit to "first arcs" @inbounds for i in 1:length(game)-4
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

    #memory allocation for max/min node second candidate list
    candidatelist =  falses(length(game)-2)
    #initialize average node second candidate list
    nodelist = Vector{Int}(1:length(game))
    #memory pre-allocation for the bad subgraph checker
    reachablenodes = falses(length(game)-2)
    queue = Vector{Int}()
    queuetwo = Vector{Int}()
    sizehint!(queue, length(game)-2)
    sizehint!(queuetwo, length(game)-2)
    verybadnodes = falses(length(game)-2)

    #get an order for assigning arcs to the remaining nodes
    randomorder = sample(1:length(game)-2, length(game)-2, replace = false)
    @timeit to "second arcs" run_main_loop_to_assign_second_arcs!(game, parentmap, inzeronodes,  nodelist, candidatelist, reachablenodes, queue, queuetwo, verybadnodes, randomorder)
    
    println("in-zeros:  ",length(inzeronodes))
    println("very bad nodes ", sum(verybadnodes))

    return game, parentmap
end

"""
    


# Arguments
- `game::Vector{MutableSGNode}`: The partially generated Stopping Game
- `parentmap::Dict{Int, Vector{Int}}`: A map from nodes to a list of their parents
- `inzeronodes::Vector{Int}`: nodes with in-degree zero
- `nodelist::Vector{Int}`:: equal to Vector{Int}(1:length(game)), pre-allocated for performance
- `candidatelist::BitVector`: A bit vector such that length(candidatelist) == length(game)-2 containing valid candidates for the destination of the arc
- `reachablenodes::BitVector`: A bit vector such that length(reachablenodes) == length(game)-2 
- `queue::Vector{Int}`:: A list of integers, preferred empty
- `queuetwo::Vector{Int}`: A list of integers, preferred empty
- `verybadnodes::BitVector`: A list of nodes that could not receive a second arc without becoming no good dirty rotten criminals
- `assignmentorder::Vector{Int}`: The order to assign arcs in
"""
function run_main_loop_to_assign_second_arcs!(game::Vector{MutableSGNode}, parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int},  nodelist::Vector{Int}, candidatelist::BitVector, reachablenodes::BitVector, queue::Vector{Int}, queuetwo::Vector{Int}, verybadnodes::BitVector, assignmentorder::Vector{Int})
    #add the second arcs
    @inbounds for assignment in assignmentorder
        #if there are no in-zero nodes
        if isempty(inzeronodes)
            #no in-zero nodes AND is an average node
            if game[assignment].type==average
                @timeit to "second avg arcs" assignsecondaveragearc!(game,  parentmap, inzeronodes, nodelist, assignment)
            #no in-zero nodes AND is NOT an average node
            else
                #reset the list
                candidatelist.=true
                #add the two starting forbidden elements
                candidatelist[assignment] = false
                candidatelist[game[assignment].arc_a] = false
                @timeit to "second maxmin arcs" newarcdestination = assignsecondmaxminarc!(game,  parentmap, inzeronodes, candidatelist, reachablenodes, queue, queuetwo, verybadnodes, assignment)
                if newarcdestination == -1
                    #no second arc found add to rerun queue
                    verybadnodes[assignment] = true
                end
            end
        #if there are in-zero nodes
        else
            if game[assignment].type==average
                @timeit to "second avg arcs" if assignsecondaveragearc!(game,  parentmap, inzeronodes, inzeronodes, assignment) == -1
                    assignsecondaveragearc!(game,  parentmap, inzeronodes, nodelist, assignment)
                end
            #no in-zero nodes AND is NOT an average node
            else
                #reset the list
                candidatelist.=false
                for node in inzeronodes
                    candidatelist[node] = true
                end
                #add the two starting forbidden elements
                candidatelist[assignment] = false
                candidatelist[game[assignment].arc_a] = false
                @timeit to "second maxmin arcs" newarcdestination = assignsecondmaxminarc!(game,  parentmap, inzeronodes, candidatelist, reachablenodes, queue, queuetwo, verybadnodes, assignment)
                if newarcdestination == -1
                    #reset the list to run without in-zeros
                    candidatelist.=true
                    #add the two starting forbidden elements
                    candidatelist[assignment] = false
                    candidatelist[game[assignment].arc_a] = false
                    @timeit to "second maxmin arcs" newarcdestination = assignsecondmaxminarc!(game,  parentmap, inzeronodes, candidatelist, reachablenodes, queue, queuetwo, verybadnodes, assignment)
                    if newarcdestination == -1
                        #no second arc found add to rerun queue
                        verybadnodes[assignment] = true
                    end
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
        game[origin].arc_b = getothernode(origin, game[origin].arc_a, nodelist)
        push!(parentmap[game[origin].arc_b],origin)
        removefromsortedlist!(game[origin].arc_b, inzeronodes)
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
        @timeit to "badsubgraph check" if isbadsubgraph!(reachablenodes, queue, queuetwo, game,  parentmap, assignment, newnode)
            game[assignment].arc_b = 0
            pop!(parentmap[newnode])
            candidatelist[newnode] = false
            newnode = getothernode(candidatelist)
        else
            removefromsortedlist!(game[assignment].arc_b, inzeronodes)
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

    #find reachable nodes
    while !isempty(queue)
        for node in queue
            if node != origin
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
                    if (game[i].arc_a > length(game)-2 || !reachablenodes[game[i].arc_a]) || (game[i].arc_b > 0 && game[i].arc_b < length(game)-1 && !reachablenodes[game[i].arc_b])
                        reachablenodes[i] = false
                        noderemoved = true
                    end
                end
                #if the previous if statment did not trigger, try remove due to no out arcs
                if reachablenodes[i]
                    #if neither arc points to a reachable node, accounting for possible nonexistent second arcs
                    if (game[i].arc_a > length(game)-2 || !reachablenodes[game[i].arc_a]) && (game[i].arc_b > 0 && game[i].arc_b < length(game)-1 && !reachablenodes[game[i].arc_b])
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
                if (i == origin || i == destination) && !reachablenodes[origin] || !reachablenodes[destination]
                    return false
                end
            end
        end
    end
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