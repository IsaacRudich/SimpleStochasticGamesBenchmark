"""
	mod_hoffman_karp_switch_max_nodes(game::Vector{SGNode},average_node_order::Vector{Int}; optimizer::DataType = GLPK.Optimizer, logging_on::Bool=true, log_switches::Bool=false,log_values::Bool=false)	

Solve an SSG using a Modified Hoffman Karp that skips iterations by jumping to the strategy implied by each average node order

# Arguments
- `game::Vector{SGNode}`: The SSG
- `average_node_order::Vector{Int}`: the starting average node order strategy
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
- `log_switches::Bool`: whether or not to print switchable nodes, default is false
- `log_values::Bool`: whether or not to print the optimal values
"""
function mod_hoffman_karp_switch_max_nodes(game::Vector{SGNode},average_node_order::Vector{Int}; optimizer::DataType = GLPK.Optimizer, logging_on::Bool=true, log_switches::Bool=false,log_values::Bool=false)	
	epsilon = eps()
    #strategy initialization
	parentmap = get_parent_map(game)
	max_strat = generate_max_strategy_from_average_order(game, average_node_order, parentmap)

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
	mod_hoffman_karp_switch_min_nodes(game::Vector{SGNode},average_node_order::Vector{Int}; optimizer::DataType = GLPK.Optimizer, logging_on::Bool=true, log_switches::Bool=false,log_values::Bool=false)	

Solve an SSG using a Modified Hoffman Karp that skips iterations by jumping to the strategy implied by each average node order

# Arguments
- `game::Vector{SGNode}`: The SSG
- `average_node_order::Vector{Int}`: the starting average node order strategy
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
- `log_switches::Bool`: whether or not to print switchable nodes, default is false
- `log_values::Bool`: whether or not to print the optimal values
- `log_analysis::Bool`: whether or not to print an analysis of the solve
"""
function mod_hoffman_karp_switch_min_nodes(game::Vector{SGNode},average_node_order::Vector{Int}; optimizer::DataType = GLPK.Optimizer, logging_on::Bool=true, log_switches::Bool=false,log_values::Bool=false, log_analysis::Bool=false)	
	if log_analysis
		average_node_orders = Vector{Vector{Int}}()
		push!(average_node_orders, copy(average_node_order))
	end
	epsilon = eps()
    #strategy initialization
	parentmap = get_parent_map(game)
	min_strat = generate_min_strategy_from_average_order(game, average_node_order, parentmap)

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