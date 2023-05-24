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

    
    # for switched_nodes in switches_history
    #     sorted_keys = sort!(collect(keys(switched_nodes)))
    #     for key in sorted_keys
    #         print(key, " => ", switched_nodes[key], " , ")
    #     end
    #     println()
    # end
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

            # for e in intersection
            #     print("\t", e[1], " => ", e[2], " , ")
            # end
            if !isempty(intersection)
                push!(intersections, intersection)
            end
        end
    end

    optimal_strat = merge(max_strat, min_strat)
    opt_vec = Vector{Tuple{Int, Int}}()

    for (key,val) in optimal_strat
        push!(opt_vec, (key,val))
    end

    for intersection in intersections
        check = intersect(opt_vec, intersection)
        println(length(check))

        if length(check)==0
            for e in intersection
                println("------------------------------")
                println("Node: ",e[1], "  Decision: ", e[2], "  Solution: ", optimal_strat[e[1]])
                println(game[e[1]])
                println(optimal_values[e[1]], " == ", optimal_values[optimal_strat[e[1]]], " is ", optimal_values[e[1]] == optimal_values[optimal_strat[e[1]]])
            end
        end
    end

	return merge(max_strat, min_strat), i
end