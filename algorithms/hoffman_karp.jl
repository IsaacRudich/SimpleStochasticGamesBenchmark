"""
    hoffman_karp_switch_max_nodes(game::Vector{SGNode},max_strat::Dict{Int, Int}; optimizer::DataType = GLPK.Optimizer)

Solve an SSG using Hoffman Karp

# Arguments
- `game::Vector{SGNode}`: The SSG
- `max_strat::Dict{Int, Int}`: the starting max strategy
- `optimizer::DataType`: the optimizer that JUMP should use
"""
function hoffman_karp_switch_max_nodes(game::Vector{SGNode},max_strat::Dict{Int, Int}; optimizer::DataType = GLPK.Optimizer)
    #strategy initialization
	min_strat = Dict{Int, Int}()

	#main algorithm loop
	node_switched = true
	i = 0
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
					if node_val < a_val
						max_strat[id] = node.arc_a
						node_switched = true
						switch_counter += 1
					elseif node_val < b_val
						max_strat[id] = node.arc_b
						node_switched = true
						switch_counter += 1
					end
				end
			end
			println("iteration $i finished")
		else
			throw(ArgumentError("Hoffman-Karp Model Generation Failed"))
		end
	end
	println("Hoffman Karp Iterations: $i")

	return merge(max_strat, min_strat)
end
