"""
    generate_fully_reduced_stopping_game_lazy(nmax::Int, nmin::Int, navg::Int)

Generate a stopping game without trivially solvable nodes, including 0s and 1s. This will most likely have fewer nodes than the input parameters
Returns::Vector{MutableSGNode}

# Arguments
- `nmax::Int`: the number of max nodes in the stopping game
- `nmin::Int`: the number of min nodes in the stopping game
- `navg::Int`: the number of avg nodes in the stopping game
- ``: whether or not to print progress
"""
function generate_fully_reduced_stopping_game(nmax::Int, nmin::Int, navg::Int; logging_on::Bool=false)
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
    candidatelist =  trues(length(game)-2)
    processqueue = Vector{Int}()
    newprocessqueue = Vector{Int}()
    sizehint!(processqueue, length(game)-2)
    sizehint!(newprocessqueue, length(game)-2)
    averagecounter = Dict{Int, Int}()
    for node in game
        if node.type == average            averagecounter[node.label] = 0
        end
    end
    finalcandidates = Vector{Int}()

    #get an order for assigning arcs to the remaining nodes
    randomorder = sample(mtracker, length(mtracker), replace = false)

    for nodeindex in randomorder
        #get the arcs that can be potential children of the current node
        get_arc_availability!(game, parentmap,nodeindex,candidatelist,processqueue,newprocessqueue, averagecounter)
        candidates = findall(x -> x, candidatelist)
        empty!(finalcandidates)

        #if there are inzeronodes get the intersection of the two lists
        if !isempty(inzeronodes)
            finalcandidates = intersect(inzeronodes, candidates)
        end
        #if there is no intersection then revert to the entire candidate list
        if isempty(finalcandidates)
            finalcandidates = copy(candidates)
        end

        #if there is a candidate assign the arc
        if !isempty(finalcandidates)
            assignsecondmaxminarc!(game,  parentmap, inzeronodes, rand(finalcandidates))
        end
    end

    return game
end

############################
#       Subroutines        #
############################

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
    assignsecondmaxminarc!(game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, candidatelist::BitVector, assignment::Int)

Assigns a second arc to a max or min node
Several parameters are only there so that they are pre-allocated for performance.
All paramaters except 'assignment' may be modified

# Arguments
- `game::Vector{MutableSGNode}`: The partially generated Stopping Game
- `parentmap::Dict{Int, Vector{Int}},`: A map from nodes to a list of their parents
- `inzeronodes::Vector{Int}`: nodes with in-degree zero
- `assignment::Int`: The node getting a second arc
"""
function assignsecondmaxminarc!(game::Vector{MutableSGNode},  parentmap::Dict{Int, Vector{Int}}, inzeronodes::Vector{Int}, assignment::Int)
    game[assignment].arc_b = assignment
    push!(parentmap[assignment], assignment)
    removefromsortedlist!(assignment, inzeronodes)
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
    get_arc_availability!(game::Vector{MutableSGNode}, parentmap::Dict{Int, Vector{Int}},nodeindex::Int,candidatelist::BitVector,processqueue::Vector{Int},newprocessqueue::Vector{Int}, averagecounter::Dict{Int,Int})

Modify candidatelist to be a list of all arcs that the given node can add an arc to without creating a bad subgraph

# Arguments
- `game::Vector{MutableSGNode}`: The SSG
- `parentmap::Dict{Int, Vector{Int}}`: a map of nodeindexes to parentindexes
- `nodeindex::Int`: the index of the node being considered
- `candidatelist::BitVector`: a pre-allocated bitvector to be modified that contains all potential out arcs for the given node
- `processqueue::Vector{Int}`: an empty but pre-allocated list of nodes
- `newprocessqueue::Vector{Int}`: an empty but pre-allocated list of nodes
- `averagecounter::Dict{Int,Int}`: A dictionary with a pre-allocated key for each average node index
"""
function get_arc_availability!(game::Vector{MutableSGNode}, parentmap::Dict{Int, Vector{Int}},nodeindex::Int,candidatelist::BitVector,processqueue::Vector{Int},newprocessqueue::Vector{Int}, averagecounter::Dict{Int,Int})
    #initialize pre-allocated variables
    candidatelist .= true
    candidatelist[nodeindex] = false
    empty!(processqueue)
    empty!(newprocessqueue)
    push!(processqueue,nodeindex)
    for key in keys(averagecounter)
        averagecounter[key] = 0
    end

    while !isempty(processqueue)
        for index in processqueue
            for parentindex in parentmap[index]
                if candidatelist[parentindex]
                    currentnode = game[parentindex]
                    if currentnode.type == average
                        if averagecounter[parentindex] == 0
                            averagecounter[parentindex] = 1
                        elseif averagecounter[parentindex] == 1
                            averagecounter[parentindex] = 2
                            candidatelist[parentindex] = false
                            push!(newprocessqueue)
                        end
                    else
                        candidatelist[parentindex] = false
                        push!(newprocessqueue)
                    end
                end
            end
        end
        processqueue = copy(newprocessqueue)
        empty!(newprocessqueue)
    end
end