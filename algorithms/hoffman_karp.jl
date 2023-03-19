"""
	hoffman_karp_switch_max_nodes(game::Vector{SGNode},max_strat::Dict{Int, Int}; optimizer::DataType = GLPK.Optimizer, logging_on::Bool=true, log_switches::Bool=false, log_values::Bool=false)	

Solve an SSG using Hoffman Karp

# Arguments
- `game::Vector{SGNode}`: The SSG
- `max_strat::Dict{Int, Int}`: the starting max strategy
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
- `log_switches::Bool`: whether or not to print switchable nodes, default is false
- `log_values::Bool`: whether or not to print the optimal values
"""
function hoffman_karp_switch_max_nodes(game::Vector{SGNode},max_strat::Dict{Int, Int}; optimizer::DataType = GLPK.Optimizer, logging_on::Bool=true, log_switches::Bool=false, log_values::Bool=false)	
	epsilon = eps()
    #strategy initialization
	min_strat = Dict{Int, Int}()

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
						if log_switches
							push!(switched_nodes, id)
						end
					elseif node_val < b_val - epsilon
						max_strat[id] = node.arc_b
						node_switched = true
						switch_counter += 1
						if log_switches
							push!(switched_nodes, id)
						end
					end
				end
			end
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
		else
			throw(ArgumentError("Hoffman-Karp Model Generation Failed"))
		end
	end
	if logging_on
		println("Hoffman Karp Iterations: $i")
	end

	return merge(max_strat, min_strat), i
end



"""
	hoffman_karp_switch_min_nodes(game::Vector{SGNode},min_strat::Dict{Int, Int}; optimizer::DataType = GLPK.Optimizer, logging_on::Bool=true, log_switches::Bool=false, log_values::Bool=false)	

Solve an SSG using Hoffman Karp

# Arguments
- `game::Vector{SGNode}`: The SSG
- `min_strat::Dict{Int, Int}`: the starting max strategy
- `optimizer::DataType`: the optimizer that JUMP should use
- `logging_on::Bool`: whether or not to log basic progress
- `log_switches::Bool`: whether or not to print switchable nodes, default is false
- `log_values::Bool`: whether or not to print the optimal values
"""
function hoffman_karp_switch_min_nodes(game::Vector{SGNode},min_strat::Dict{Int, Int}; optimizer::DataType = GLPK.Optimizer, logging_on::Bool=true, log_switches::Bool=false, log_values::Bool=false)
	epsilon = eps()
    #strategy initialization
	max_strat = Dict{Int, Int}()

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
	    empty!(max_strat)
		if termination_status(model) == MOI.OPTIMAL
			switch_counter = 0
			#check if optimal
			for (id, node) in enumerate(game)
				if node.type == maximizer
					a_val = value(v[node.arc_a])
					b_val = value(v[node.arc_b])
					if a_val >= b_val
						max_strat[id] = node.arc_a
					else
						max_strat[id] = node.arc_b
					end
				elseif node.type == minimizer
					a_val = value(v[node.arc_a])
					b_val = value(v[node.arc_b])
					node_val = value(v[id])
					if node_val > a_val + epsilon
						min_strat[id] = node.arc_a
						node_switched = true
						switch_counter += 1
						if log_switches
							push!(switched_nodes, id)
						end
					elseif node_val > b_val + epsilon
						min_strat[id] = node.arc_b
						node_switched = true
						switch_counter += 1
						if log_switches
							push!(switched_nodes, id)
						end
					end
				end
			end
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
		else
			throw(ArgumentError("Hoffman-Karp Model Generation Failed"))
		end
	end
	if logging_on
		println("Hoffman Karp Iterations: $i")
	end

	return merge(max_strat, min_strat), i
end