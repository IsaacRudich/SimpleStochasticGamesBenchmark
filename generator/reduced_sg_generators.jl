"""
    generate_reduced_stopping_game(nmax::Int, nmin::Int, navg::Int)

Generate a stopping game without trivially solvable nodes, simple but slow
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
    generate_reduced_stopping_game_efficient(nmax::Int, nmin::Int, navg::Int)

Generate a stopping game without trivially solvable nodes
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
    generate_fully_reduced_stopping_game_lazy(nmax::Int, nmin::Int, navg::Int)

Generate a stopping game without trivially solvable nodes, including 0s and 1s. This will have fewer nodes than the input parameters
Returns::Vector{MutableSGNode}

# Arguments
- `nmax::Int`: the number of max nodes in the stopping game
- `nmin::Int`: the number of min nodes in the stopping game
- `navg::Int`: the number of avg nodes in the stopping game
- ``: whether or not to print progress
"""
function generate_fully_reduced_stopping_game_lazy(nmax::Int, nmin::Int, navg::Int; logging_on::Bool=false)
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

    while !isempty(mtracker)
        #memory allocation for max/min node second candidate list
        candidatelist =  falses(length(game)-2)

        #get an order for assigning arcs to the remaining nodes
        randomorder = sample(mtracker, length(mtracker), replace = false)
        run_main_loop_to_assign_second_arcs_no_checks!(game, parentmap, inzeronodes, candidatelist, randomorder)

        if logging_on
            println("Renewed attempt at second arc assignments finished")
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
        

        if logging_on
            println("Bad subgraphs removed during renewed iteration: ",length(mtracker), "\n   In-zeros: ", length(inzeronodes))
        end

        #get an order for assigning arcs to the remaining nodes
        new_mtracker = Vector{Int}()
        sizehint!(new_mtracker, length(mtracker))
        pre_missing_arc_count = length(mtracker)
        post_missing_arc_count =  0
        repeat_count = 0
        repeat_cap = max(floor(Int,log(2,length(game))/16),2)

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

        #instead of the above, just delete them
        remove_nodes(game, mtracker)

        #regenerate a parent map
        parentmap = get_parent_map(game)

        #regenerate inzero nodes and mtracker
        inzeronodes = Vector{Int}()
        empty!(mtracker)
        for i in 1:lastindex(game)-2
            if isempty(parentmap[i])
                push!(inzeronodes,i)
            end
            if game[i].arc_a == 0
                if game[i].arc_b == 0
                    game[i].arc_a = rand(i+1:length(game)-2)
                else
                    game[i].arc_a = game[i].arc_b
                    game[i].arc_b = 0
                end
            end
            if game[i].arc_b == 0
                push!(mtracker,i)
            end
        end

        if logging_on
            println("in-zeros after bad nodes deleted:  ",length(inzeronodes))
        end
    end


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

    #debug check
    parentmap = get_parent_map(game)
    check_for_bad_subgraphs(game)
    find_bugs(game, parentmap, inzeronodes)

    #reduce game
    game, orderedsccs = reduce_game(game, parentmap)

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

    return game, parentmap, orderedsccs
end