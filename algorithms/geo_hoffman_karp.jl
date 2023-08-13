"""
	hoffman_karp_switch_max_nodes(game::Vector{SGNode},max_strat::Dict{Int, Int}; optimizer::DataType = GLPK.Optimizer, logging_on::Bool=true, log_switches::Bool=false, log_values::Bool=false)	

Solve an SSG using Hoffman Karp

# Arguments
- `game::Vector{SGNode}`: The SSG
- `max_strat::Dict{Int, Int}`: the starting max strategy
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
"""
function geometric_hoffman_karp_switch_max_nodes(game::Vector{SGNode},max_strat::Dict{Int, Int}; optimizer::DataType = GLPK.Optimizer, logging_on::Bool=true)	
	epsilon = eps()
    #strategy initialization
	min_strat = Dict{Int, Int}()

	#main algorithm loop
	node_switched = true
	i = 0
    switches_history = Vector{Dict{Int, Int}}()
    optimal_values = Dict{Int, Float64}()
	while node_switched
		i += 1
		node_switched = false
        switched_nodes = Dict{Int, Int}()
		#generate the optimal min strategy relative to the max strategy
	    model = generate_JuMP_model_min_strategy(game,max_strat, optimizer = optimizer)
	    optimize!(model)
		v = all_variables(model)
	    empty!(min_strat)
		if termination_status(model) == MOI.OPTIMAL
			switch_counter = 0
			#check if optimal
			for (id, node) in enumerate(game)
				if node.type == minimizer
					a_val = value(v[node.arc_a])
					b_val = value(v[node.arc_b])
					if a_val <= b_val
						min_strat[id] = node.arc_a
					else
						min_strat[id] = node.arc_b
					end
				elseif node.type == maximizer
					a_val = value(v[node.arc_a])
					b_val = value(v[node.arc_b])
					node_val = value(v[id])
					if node_val < a_val - epsilon
						max_strat[id] = node.arc_a
						node_switched = true
						switch_counter += 1
						switched_nodes[id] = node.arc_a
					elseif node_val < b_val - epsilon
						max_strat[id] = node.arc_b
						node_switched = true
						switch_counter += 1
						switched_nodes[id] = node.arc_b
					end
				end
			end
			if logging_on
				println("iteration $i finished, objective value: ", round(objective_value(model),digits=3))
			end
            if !isempty(switched_nodes)
                push!(switches_history, switched_nodes)
            else
                for m in 1:lastindex(game)
                    optimal_values[m] = value(v[m])
                end
            end
		else
			throw(ArgumentError("Hoffman-Karp Model Generation Failed"))
		end
	end
	if logging_on
		println("Hoffman Karp Iterations: $i")
	end

    

	return merge(max_strat, min_strat), i, switches_history, optimal_values
end

"""
    avi_analyze_switches_history(game::Vector{SGNode}, switches_history::Vector{Dict{Int, Int}},optimal_strat::Dict{Int, Int},optimal_values::Dict{Int, Float64})

Analyze accumulated data from geo-hk

# Arguments
- `game::Vector{SGNode}`: The SSG
- `switches_history::Vector{Dict{Int, Int}}`: the collected data
- `optimal_strat::Dict{Int, Int}`: the optimal decisions
- `optimal_values::Dict{Int, Float64}`: the optimal solution
"""
function avi_analyze_switches_history(game::Vector{SGNode}, switches_history::Vector{Dict{Int, Int}},optimal_strat::Dict{Int, Int},optimal_values::Dict{Int, Float64})
    opt_vec = Vector{Tuple{Int, Int}}()

    for (key,val) in optimal_strat
        push!(opt_vec, (key,val))
    end
    
    for (i,node) in enumerate(game)
        for choice in [node.arc_a, node.arc_b]
            # find all members of switches_history that contain node.child == choice
            kept_switch_iters = Vector{Vector{Tuple{Int, Int}}}()
            for switch_iter in switches_history
                if i in keys(switch_iter) && switch_iter[i] == choice
                    # put switch_iter in set to take intersection on
                    switch_vec = Vector{Tuple{Int, Int}}()
                    for (key,val) in switch_iter
                        push!(switch_vec, (key,val))
                    end
                    push!(kept_switch_iters,switch_vec)
                end
            end

            if isempty(kept_switch_iters)
                continue
            end

            # Take the intersection of everything in intersections
            intersection = Vector{Tuple{Int,Int}}()
            for (i,kept_switch_iter) in enumerate(kept_switch_iters)
                if i == 1
                    intersection = copy(kept_switch_iter)
                else
                    intersect!(intersection,kept_switch_iter)
                end
            end

            #Check that one thing left in intersections is in the optimal solution

            check = intersect(opt_vec, intersection)
    
            validity_verified = false
            verification_count = 0

            for e in intersection
                if eps_equals(optimal_values[e[2]], optimal_values[optimal_strat[e[1]]])
                    validity_verified = true
                    verification_count += 1
                end
            end
            println(length(intersection),"=>", verification_count)
    
    
            if length(check)==0
                if !validity_verified
                    for e in intersection
                        println("------------------------------")
                        println("Node: ",e[1], "  Decision: ", e[2], "  Solution: ", optimal_strat[e[1]])
                        println(game[e[1]])
                        println(optimal_values[e[2]], " == ", optimal_values[optimal_strat[e[1]]], " is ", eps_equals(optimal_values[e[2]],optimal_values[optimal_strat[e[1]]]))
                    end
                    throw("CRASH BOOM")
                end
            end
        end#our arc loop
    end#game loop
end

"""
    analyze_switches_history(game::Vector{SGNode}, switches_history::Vector{Dict{Int, Int}},optimal_strat::Dict{Int, Int},optimal_values::Dict{Int, Float64})

Analyze accumulated data from geo-hk

# Arguments
- `game::Vector{SGNode}`: The SSG
- `switches_history::Vector{Dict{Int, Int}}`: the collected data
- `optimal_strat::Dict{Int, Int}`: the optimal decisions
- `optimal_values::Dict{Int, Float64}`: the optimal solution
"""
function analyze_switches_history(game::Vector{SGNode}, switches_history::Vector{Dict{Int, Int}},optimal_strat::Dict{Int, Int},optimal_values::Dict{Int, Float64})
    println("Intersections:")
    intersections = Vector{Vector{Tuple{Int, Int}}}()
    for i in 1:lastindex(switches_history)-1
        for j in i+1:lastindex(switches_history)
            a = switches_history[i]
            b = switches_history[j]

            a_vec = Vector{Tuple{Int, Int}}()
            b_vec = Vector{Tuple{Int, Int}}()

            for (key,val) in a
                push!(a_vec, (key,val))
            end
            for (key,val) in b
                push!(b_vec, (key,val))
            end

            intersection = intersect(a_vec, b_vec)

            if !isempty(intersection)
                push!(intersections, intersection)
            end
        end
    end

    opt_vec = Vector{Tuple{Int, Int}}()

    for (key,val) in optimal_strat
        push!(opt_vec, (key,val))
    end

    for intersection in intersections
        check = intersect(opt_vec, intersection)

        validity_verified = false
        verification_count = 0

        for e in intersection
            if optimal_values[e[2]] == optimal_values[optimal_strat[e[1]]]
                validity_verified = true
                verification_count += 1
            end
        end
        println(length(intersection),"=>", verification_count)


        if length(check)==0
            if !validity_verified
                for e in intersection
                    println("------------------------------")
                    println("Node: ",e[1], "  Decision: ", e[2], "  Solution: ", optimal_strat[e[1]])
                    println(game[e[1]])
                    println(optimal_values[e[2]], " == ", optimal_values[optimal_strat[e[1]]], " is ", optimal_values[e[2]] == optimal_values[optimal_strat[e[1]]])
                end
                throw("CRASH BOOM")
            end
        end
    end
end

function test_geo_hypothesis(filename::String,data_size::Int;optimizer::DataType = CPLEX.Optimizer, logging_on::Bool=false)
    game::Vector{SGNode} = read_stopping_game(filename)

    switches_history = Vector{Dict{Int, Int}}()
    optimal_values = Dict{Int, Float64}()
    optimal_strategy = Dict{Int, Int}()
    while length(switches_history) <= data_size
        max_strat = generate_random_max_strategy(game)
        generated_optimal_strategy, iterations, new_switches_history, generated_optimal_values  = geometric_hoffman_karp_switch_max_nodes(game,max_strat, optimizer = optimizer, logging_on = logging_on)
        if isempty(optimal_values)
            optimal_values = generated_optimal_values
            optimal_strategy = generated_optimal_strategy
        end
        append!(switches_history, new_switches_history)
        println("Current Data Size: ", length(switches_history))
    end

    analyze_switches_history(game, switches_history,optimal_strategy,optimal_values)
    #avi_analyze_switches_history(game, switches_history,optimal_strategy,optimal_values)
end