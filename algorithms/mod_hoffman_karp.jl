"""
	mod_hoffman_karp_switch_max_nodes_slow(game::Vector{SGNode},average_node_order::Vector{Int}; optimizer::DataType = SCIP.Optimizer, logging_on::Bool=true, log_switches::Bool=false,log_values::Bool=false, auto_terminate::Bool=false)	

Solve an SSG using a Modified Hoffman Karp that skips iterations by jumping to the strategy implied by each average node order

# Arguments
- `game::Vector{SGNode}`: The SSG
- `average_node_order::Vector{Int}`: the starting average node order strategy
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
- `log_switches::Bool`: whether or not to print switchable nodes, default is false
- `log_values::Bool`: whether or not to print the optimal values
- `auto_terminate::Bool`: if the solver suspects it is caught in an infinite loop, it stops and returns nothing
"""
function mod_hoffman_karp_switch_max_nodes_slow(game::Vector{SGNode},average_node_order::Vector{Int}; optimizer::DataType = SCIP.Optimizer, logging_on::Bool=true, log_switches::Bool=false,log_values::Bool=false, auto_terminate::Bool=false)	
	epsilon = eps()
    #strategy initialization
	parentmap = get_parent_map(game)
	max_strat = generate_max_strategy_from_average_order(game, average_node_order, parentmap)

	if auto_terminate
		obj_vals = fill(-1.0, 5)
	end

	#main algorithm loop
	node_switched = true
	i = 0
	switched_nodes = Vector{Int}()
	sizehint!(switched_nodes, length(keys(max_strat)))
	while node_switched
		i += 1
		node_switched = false
		#generate the optimal min strategy relative to the max strategy
	    model = generate_JuMP_model_min_strategy(game,max_strat, optimizer = optimizer)
	    optimize!(model)
		v = all_variables(model)
		if termination_status(model) == MOI.OPTIMAL
			switch_counter = 0
			#check if optimal

			sort!(average_node_order, by = x -> value(v[x]), rev = true)
			new_max_strat = generate_max_strategy_from_average_order(game, average_node_order, parentmap)

			for key in keys(max_strat)
				if max_strat[key] != new_max_strat[key]
					if value(v[max_strat[key]]) < value(v[new_max_strat[key]]) - epsilon
						node_switched = true
						switch_counter += 1
					end
				end
			end

			max_strat = new_max_strat

			if logging_on
				println("iteration $i finished, objective value: ", round(objective_value(model),digits=3))
			end
			if log_switches
				sort!(switched_nodes)
				print("Switched Nodes:")
				for e in switched_nodes
					print(" ",e)
				end
				println()
			end
		else
			throw(ArgumentError("Hoffman-Karp Model Generation Failed"))
		end
		if auto_terminate
			if obj_vals[1] == objective_value(model)
				return nothing
			else
				popfirst!(obj_vals)
				push!(obj_vals,objective_value(model))
			end
		end
		if !node_switched && log_values
			println("Zeros:")
			for (id,node) in enumerate(game)
				if value(v[id]) == 0
					print(id," ")
				end
			end
			println()
			println("Ones:")
			for (id,node) in enumerate(game)
				if value(v[id]) == 1
					print(id," ")
				end
			end
			println()
			println("Other:")
			for (id,node) in enumerate(game)
				if value(v[id]) != 0 && value(v[id]) != 1
					print("$id->",value(v[id])," ")
				end
			end
			println("\n\n")
		end
	end
	if logging_on
		println("Hoffman Karp Iterations: $i")
	end

	return max_strat, i
end

"""
	mod_hoffman_karp_switch_min_nodes_slow(game::Vector{SGNode},average_node_order::Vector{Int}; optimizer::DataType = SCIP.Optimizer, logging_on::Bool=true, log_switches::Bool=false,log_values::Bool=false, auto_terminate::Bool=false)	

Solve an SSG using a Modified Hoffman Karp that skips iterations by jumping to the strategy implied by each average node order

# Arguments
- `game::Vector{SGNode}`: The SSG
- `average_node_order::Vector{Int}`: the starting average node order strategy
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
- `log_switches::Bool`: whether or not to print switchable nodes, default is false
- `log_values::Bool`: whether or not to print the optimal values
- `log_analysis::Bool`: whether or not to print an analysis of the solve
- `auto_terminate::Bool=`: if the solver suspects it is caught in an infinite loop, it stops and returns nothing
"""
function mod_hoffman_karp_switch_min_nodes_slow(game::Vector{SGNode},average_node_order::Vector{Int}; optimizer::DataType = SCIP.Optimizer, logging_on::Bool=true, log_switches::Bool=false,log_values::Bool=false, log_analysis::Bool=false, auto_terminate::Bool=false)	
	if log_analysis
		average_node_orders = Vector{Vector{Int}}()
		push!(average_node_orders, copy(average_node_order))
	end
	epsilon = eps()
    #strategy initialization
	parentmap = get_parent_map(game)
	min_strat = generate_min_strategy_from_average_order(game, average_node_order, parentmap)

	if auto_terminate
		obj_vals = fill(-1.0, 5)
	end

	#main algorithm loop
	node_switched = true
	i = 0
	switched_nodes = Vector{Int}()
	sizehint!(switched_nodes, length(keys(min_strat)))
	while node_switched
		i += 1
		node_switched = false
		#generate the optimal min strategy relative to the max strategy
	    model = generate_JuMP_model_max_strategy(game,min_strat, optimizer = optimizer)
	    optimize!(model)
		v = all_variables(model)
		if termination_status(model) == MOI.OPTIMAL
			switch_counter = 0
			#check if optimal

			sort!(average_node_order, by = x -> value(v[x]), rev = true)
			if log_analysis
				push!(average_node_orders, copy(average_node_order))
			end
			new_min_strat = generate_min_strategy_from_average_order(game, average_node_order, parentmap)

			for key in keys(min_strat)
				if min_strat[key] != new_min_strat[key]
					if value(v[min_strat[key]]) > value(v[new_min_strat[key]]) + epsilon
						node_switched = true
						switch_counter += 1
					end
				end
			end

			min_strat = new_min_strat

			if logging_on
				println("iteration $i finished, objective value: ", round(objective_value(model),digits=3))
			end
			if log_switches
				sort!(switched_nodes)
				print("Switched Nodes:")
				for e in switched_nodes
					print(" ",e)
				end
				println()
			end
		else
			throw(ArgumentError("Hoffman-Karp Model Generation Failed"))
		end
		if auto_terminate
			if obj_vals[1] == objective_value(model)
				return nothing
			else
				popfirst!(obj_vals)
				push!(obj_vals,objective_value(model))
			end
		end
		if !node_switched && log_values
			println("Zeros:")
			for (id,node) in enumerate(game)
				if value(v[id]) == 0
					print(id," ")
				end
			end
			println()
			println("Ones:")
			for (id,node) in enumerate(game)
				if value(v[id]) == 1
					print(id," ")
				end
			end
			println()
			println("Other:")
			for (id,node) in enumerate(game)
				if value(v[id]) != 0 && value(v[id]) != 1
					print("$id->",value(v[id])," ")
				end
			end
			println("\n\n")
		end
	end
	if logging_on
		println("Hoffman Karp Iterations: $i")
	end

	if log_analysis
		count_average_switches(average_node_orders)
	end
	return min_strat, i
end

"""
	mod_hoffman_karp_switch_max_nodes(game::Vector{SGNode},average_node_order::Vector{Int}; optimizer::DataType = SCIP.Optimizer, logging_on::Bool=true, log_switches::Bool=false,log_values::Bool=false, auto_terminate::Bool=false)	

Solve an SSG using a Modified Hoffman Karp that skips iterations by jumping to the strategy implied by each average node order

# Arguments
- `game::Vector{SGNode}`: The SSG
- `average_node_order::Vector{Int}`: the starting average node order strategy
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
- `log_switches::Bool`: whether or not to print switchable nodes, default is false
- `log_values::Bool`: whether or not to print the optimal values
- `auto_terminate::Bool=`: if the solver suspects it is caught in an infinite loop, it stops and returns nothing
"""
function mod_hoffman_karp_switch_max_nodes(game::Vector{SGNode},average_node_order::Vector{Int}; optimizer::DataType = SCIP.Optimizer, logging_on::Bool=true, log_switches::Bool=false,log_values::Bool=false, auto_terminate::Bool=false)	
	epsilon = eps()

	#memory allocation
	labeled = zeros(Int, length(game)-2)
    queue = Vector{Int}()
    sizehint!(queue, length(game))

	if auto_terminate
		obj_vals = fill(-1.0, 5)
	end

    #strategy initialization
	parentmap = get_parent_map(game)
	min_parent_map = get_min_parents(game, parentmap)
	max_tails = get_max_tails(game, parentmap)
	max_strat = generate_max_strategy_from_average_order(game, average_node_order, max_tails, min_parent_map, labeled, queue)

	#main algorithm loop
	node_switched = true
	i = 0
	switched_nodes = Vector{Int}()
	sizehint!(switched_nodes, length(keys(max_strat)))
	while node_switched
		i += 1
		node_switched = false
		#generate the optimal min strategy relative to the max strategy
	    model = generate_JuMP_model_min_strategy(game,max_strat, optimizer = optimizer)
	    optimize!(model)
		v = all_variables(model)
		if termination_status(model) == MOI.OPTIMAL
			switch_counter = 0
			#check if optimal

			sort!(average_node_order, by = x -> value(v[x]), rev = true)
			new_max_strat = generate_max_strategy_from_average_order(game, average_node_order, max_tails, min_parent_map, labeled, queue)

			for key in keys(max_strat)
				if max_strat[key] != new_max_strat[key]
					if value(v[max_strat[key]]) < value(v[new_max_strat[key]]) - epsilon
						node_switched = true
						switch_counter += 1
					end
				end
			end

			max_strat = new_max_strat

			if logging_on
				println("iteration $i finished, objective value: ", round(objective_value(model),digits=3))
			end
			if log_switches
				sort!(switched_nodes)
				print("Switched Nodes:")
				for e in switched_nodes
					print(" ",e)
				end
				println()
			end
		else
			throw(ArgumentError("Hoffman-Karp Model Generation Failed"))
		end
		if auto_terminate
			if obj_vals[1] == objective_value(model)
				return nothing
			else
				popfirst!(obj_vals)
				push!(obj_vals,objective_value(model))
			end
		end
		if !node_switched && log_values
			println("Zeros:")
			for (id,node) in enumerate(game)
				if value(v[id]) == 0
					print(id," ")
				end
			end
			println()
			println("Ones:")
			for (id,node) in enumerate(game)
				if value(v[id]) == 1
					print(id," ")
				end
			end
			println()
			println("Other:")
			for (id,node) in enumerate(game)
				if value(v[id]) != 0 && value(v[id]) != 1
					print("$id->",value(v[id])," ")
				end
			end
			println("\n\n")
		end
	end
	if logging_on
		println("Hoffman Karp Iterations: $i")
	end

	return max_strat, i
end

"""
	mod_hoffman_karp_switch_min_nodes(game::Vector{SGNode},average_node_order::Vector{Int}; optimizer::DataType = SCIP.Optimizer, logging_on::Bool=true, log_switches::Bool=false,log_values::Bool=false, auto_terminate::Bool=false)

Solve an SSG using a Modified Hoffman Karp that skips iterations by jumping to the strategy implied by each average node order

# Arguments
- `game::Vector{SGNode}`: The SSG
- `average_node_order::Vector{Int}`: the starting average node order strategy
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
- `log_switches::Bool`: whether or not to print switchable nodes, default is false
- `log_values::Bool`: whether or not to print the optimal values
- `log_analysis::Bool`: whether or not to print an analysis of the solve
- `auto_terminate::Bool=`: if the solver suspects it is caught in an infinite loop, it stops and returns nothing
"""
function mod_hoffman_karp_switch_min_nodes(game::Vector{SGNode},average_node_order::Vector{Int}; optimizer::DataType = SCIP.Optimizer, logging_on::Bool=true, log_switches::Bool=false,log_values::Bool=false, log_analysis::Bool=false, auto_terminate::Bool=false)
	if log_analysis
		average_node_orders = Vector{Vector{Int}}()
		push!(average_node_orders, copy(average_node_order))
	end
	epsilon = eps()

	#memory allocation
	labeled = zeros(Int, length(game)-2)
    queue = Vector{Int}()
    sizehint!(queue, length(game))

	if auto_terminate
		obj_vals = fill(-1.0, 5)
	end

    #strategy initialization
	parentmap = get_parent_map(game)
	min_parent_map = get_min_parents(game, parentmap)
	max_tails = get_max_tails(game, parentmap)
	min_strat = generate_min_strategy_from_average_order(game, average_node_order, max_tails, min_parent_map, labeled, queue)

	#main algorithm loop
	node_switched = true
	i = 0
	switched_nodes = Vector{Int}()
	sizehint!(switched_nodes, length(keys(min_strat)))
	while node_switched
		i += 1
		node_switched = false
		#generate the optimal min strategy relative to the max strategy
	    model = generate_JuMP_model_max_strategy(game,min_strat, optimizer = optimizer)
	    optimize!(model)
		v = all_variables(model)
		if termination_status(model) == MOI.OPTIMAL
			switch_counter = 0
			#check if optimal

			sort!(average_node_order, by = x -> value(v[x]), rev = true)
			if log_analysis
				push!(average_node_orders, copy(average_node_order))
			end
			new_min_strat = generate_min_strategy_from_average_order(game, average_node_order, max_tails, min_parent_map, labeled, queue)

			for key in keys(min_strat)
				if min_strat[key] != new_min_strat[key]
					if value(v[min_strat[key]]) > value(v[new_min_strat[key]]) + epsilon
						node_switched = true
						switch_counter += 1
					end
				end
			end

			min_strat = new_min_strat

			if logging_on
				println("iteration $i finished, objective value: ", round(objective_value(model),digits=3))
			end
			if log_switches
				sort!(switched_nodes)
				print("Switched Nodes:")
				for e in switched_nodes
					print(" ",e)
				end
				println()
			end
		else
			throw(ArgumentError("Hoffman-Karp Model Generation Failed"))
		end
		if auto_terminate
			if obj_vals[1] == objective_value(model)
				return nothing
			else
				popfirst!(obj_vals)
				push!(obj_vals,objective_value(model))
			end
		end
		if !node_switched && log_values
			println("Zeros:")
			for (id,node) in enumerate(game)
				if value(v[id]) == 0
					print(id," ")
				end
			end
			println()
			println("Ones:")
			for (id,node) in enumerate(game)
				if value(v[id]) == 1
					print(id," ")
				end
			end
			println()
			println("Other:")
			for (id,node) in enumerate(game)
				if value(v[id]) != 0 && value(v[id]) != 1
					print("$id->",value(v[id])," ")
				end
			end
			println("\n\n")
		end
	end
	if logging_on
		println("Hoffman Karp Iterations: $i")
	end

	if log_analysis
		count_average_switches(average_node_orders)
	end
	return min_strat, i
end

"""
	get_max_tails(game::Vector{SGNode}, parentmap::Dict{Int, Vector{Int}})

Get a subset of parent map of only min nodes
Returns: Dict{Int, Vector{Tuple{Int, Bool}}} a map from an id to a list of max nodes in its tail, the Bool is true if arc a was used, false if arc b was used

# Arguments
- `game::Vector{SGNode}`: The SSG
- `parentmap::Dict{Int, Vector{Int}}`: A full parent map
"""
function get_max_tails(game::Vector{SGNode}, parentmap::Dict{Int, Vector{Int}})
	max_tails = Dict{Int, Vector{Tuple{Int, Bool}}}()
	assigned = falses(length(game))

	queue = Vector{Int}()
	sizehint!(queue, length(game))

	@inbounds for (i,node) in enumerate(game)
		if node.type == average || node.type == minimizer
			tail = Vector{Tuple{Int,Bool}}()
			sizehint!(tail, length(game))
			assigned .= false
			assigned[i] = true
			for p_id in parentmap[i]
				if game[p_id].type == maximizer && !assigned[p_id]
					push!(queue, p_id)
					assigned[p_id] = true
				end
			end
			
			while !isempty(queue)
				current_id = pop!(queue)
				
				if assigned[game[current_id].arc_a]
					push!(tail, (current_id,true))
				else
					push!(tail, (current_id,false))
				end
				
				for p_id in parentmap[current_id]
					if game[p_id].type == maximizer && !assigned[p_id]
						push!(queue, p_id)
						assigned[p_id] = true
					end
				end
			end

			max_tails[i] = tail
		end
	end

	return max_tails
end