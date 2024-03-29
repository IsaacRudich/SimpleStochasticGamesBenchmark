"""
    generate_JuMP_model_min_strategy(game::Vector{SGNode},max_strat::Dict{Int, Int}; optimizer::DataType = SCIP.Optimizer))

Create and return a JUMP Model (solver:SCIP) with the constraints that define the feasible polytope for the SSG

# Arguments
- `game::Vector{SGNode}`: The SSG
- `max_strat::Dict{Int, Int}`: the current min strategy
- `optimizer::DataType`: the optimizer that JUMP should use
"""
function generate_JuMP_model_min_strategy(game::Vector{SGNode},max_strat::Dict{Int, Int}; optimizer::DataType = SCIP.Optimizer)
    model = Model(optimizer)
    set_silent(model)
    
    @variable(model, v[1:length(game)])

    for (id, node) in enumerate(game)
        if node.type == maximizer || node.type == minimizer || node.type == average
            set_lower_bound(v[id], 0)
            set_upper_bound(v[id], 1)
        end
    end

    #define the feasible polytope
    objective_variables = Vector{Int}()
    sizehint!(objective_variables, length(game))
    for (id, node) in enumerate(game)
        a = node.arc_a
        b = node.arc_b
        if node.type == minimizer
            push!(objective_variables, id)
            @constraint(model, v[id] <= v[a])
            @constraint(model, v[id] <= v[b])
        elseif node.type == maximizer
            choice = max_strat[id]
            @constraint(model, v[id] == v[choice])
        elseif node.type == average
            @constraint(model, v[id] == .5v[a] + .5v[b])
        elseif node.type == terminal0
            @constraint(model, v[id] == 0)
        elseif node.type == terminal1
            @constraint(model, v[id] == 1)
        end
    end

    add_maximize_sum_objective!(model,objective_variables)
    return model
end

"""
    add_maximize_sum_objective!(model,variables)

Add an objective function to a jump model, that does not already have one, to maximize the sum of the variables
# Arguments
- `model`:a JuMP model
- `variables::Array{Int}`: a list of variable IDs
"""
function add_maximize_sum_objective!(model,variables)
    v = all_variables(model)
    ex = AffExpr(0)
    for id in variables
        add_to_expression!(ex, 1.0, v[id])
    end
    @objective(model,MOI.MAX_SENSE,ex)
end

"""
    generate_JuMP_model_max_strategy(game::Vector{SGNode},min_strat::Dict{Int, Int}; optimizer::DataType = SCIP.Optimizer))

Create and return a JUMP Model (solver:SCIP) with the constraints that define the feasible polytope for the SSG

# Arguments
- `game::Vector{SGNode}`: The SSG
- `max_strat::Dict{Int, Int}`: the current min strategy
- `optimizer::DataType`: the optimizer that JUMP should use
"""
function generate_JuMP_model_max_strategy(game::Vector{SGNode},min_strat::Dict{Int, Int}; optimizer::DataType = SCIP.Optimizer)
    model = Model(optimizer)
    set_silent(model)
    
    @variable(model, v[1:length(game)])

    for (id, node) in enumerate(game)
        if node.type == maximizer || node.type == minimizer || node.type == average
            set_lower_bound(v[id], 0)
            set_upper_bound(v[id], 1)
        end
    end

    #define the feasible polytope
    objective_variables = Vector{Int}()
    sizehint!(objective_variables, length(game))
    for (id, node) in enumerate(game)
        a = node.arc_a
        b = node.arc_b
        if node.type == maximizer
            push!(objective_variables, id)
            @constraint(model, v[id] >= v[a])
            @constraint(model, v[id] >= v[b])
        elseif node.type == minimizer
            choice = min_strat[id]
            @constraint(model, v[id] == v[choice])
        elseif node.type == average
            @constraint(model, v[id] == .5v[a] + .5v[b])
        elseif node.type == terminal0
            @constraint(model, v[id] == 0)
        elseif node.type == terminal1
            @constraint(model, v[id] == 1)
        end
    end

    add_minimize_sum_objective!(model,objective_variables)
    return model
end

"""
    add_minimize_sum_objective!(model,variables)

Add an objective function to a jump model, that does not already have one, to minimize the sum of the variables
# Arguments
- `model`:a JuMP model
- `variables::Array{Int}`: a list of variable IDs
"""
function add_minimize_sum_objective!(model,variables)
    v = all_variables(model)
    ex = AffExpr(0)
    for id in variables
        add_to_expression!(ex, 1.0, v[id])
    end
    @objective(model,MOI.MIN_SENSE,ex)
end

"""
    generate_JuMP_model_min_strategy(game::Vector{SGNode},max_strat::Dict{Int, Int}; optimizer::DataType = SCIP.Optimizer))

Create and return a JUMP Model (solver:SCIP) with the constraints that define the feasible polytope for the SSG

# Arguments
- `game::Vector{SGNode}`: The SSG
- `max_strat::Dict{Int, Int}`: the current min strategy
- `optimizer::DataType`: the optimizer that JUMP should use
"""
function generate_JuMP_model_min_strategy_rational(game::Vector{SGNode},max_strat::Dict{Int, Int})
    model = GenericModel{Rational{BigInt}}(CDDLib.Optimizer{Rational{BigInt}})
    
    @variable(model, v[1:length(game)])

    for (id, node) in enumerate(game)
        if node.type == maximizer || node.type == minimizer || node.type == average
            set_lower_bound(v[id], 0)
            set_upper_bound(v[id], 1)
        end
    end

    #define the feasible polytope
    objective_variables = Vector{Int}()
    sizehint!(objective_variables, length(game))
    for (id, node) in enumerate(game)
        a = node.arc_a
        b = node.arc_b
        if node.type == minimizer
            push!(objective_variables, id)
            @constraint(model, v[id] <= v[a])
            @constraint(model, v[id] <= v[b])
        elseif node.type == maximizer
            choice = max_strat[id]
            @constraint(model, v[id] == v[choice])
        elseif node.type == average
            @constraint(model, v[id] == .5v[a] + .5v[b])
        elseif node.type == terminal0
            @constraint(model, v[id] == 0)
        elseif node.type == terminal1
            @constraint(model, v[id] == 1)
        end
    end

    @objective(model, MOI.MAX_SENSE, sum(v))
    return model
end