test_game = read_stopping_game("benchmark/balanced_4096/1-4_1820_1820_455_97.ssg")


function read_stupid_dict()
    file_name = "my_dict.txt"
    max_strat = Dict{Int, Int}()
    open(file_name, "r") do file
        for line in eachline(file)
            # Split each line into key and value using the '=' delimiter
            parts = split(line, '=')
            if length(parts) == 2
                key, value = parse(Int,parts[1]), parse(Int,parts[2])
                max_strat[key] = value
            end
        end
    end
    return max_strat
end

function write_stupid_dict(the_dict)
    file_name = "my_dict.txt"

    # Open the file for writing
    open(file_name, "w") do file
        for (key, value) in the_dict
            # Write each key-value pair as a line in the file
            println(file, "$key=$value")
        end
    end
end

function trial_and_error(solver_choice::Int=1)
    if solver_choice == 1
        optimizer = SCIP.Optimizer
    elseif solver_choice == 2
        optimizer = CPLEX.Optimizer
    else
        optimizer = GLPK.Optimizer
    end
    model = generate_JuMP_model_min_strategy(test_game, read_stupid_dict(), optimizer = optimizer)
    # if use_CPLEX
    #     #probably does nothing
    #     #set_attribute(model, "CPXPARAM_Simplex_Tolerances_Feasibility", 1e-9)
    #     #set_attribute(model, "CPXPARAM_Emphasis_Numerical", true)

    #     set_attribute(model, "CPXPARAM_Simplex_Tolerances_Optimality", 1e-9)
        
    # end
    optimize!(model)
    return model
end

function compare_stuff()
    scipmodel = trial_and_error(1)
    cplexmodel = trial_and_error(2)
    glpkmodel = trial_and_error(3)

    max_strat_cplex = Dict{Int,Int}()
    max_strat_glpk = Dict{Int,Int}()

    min_strat_cplex = Dict{Int, Int}()
    min_strat_glpk = Dict{Int, Int}()

    vcip = all_variables(scipmodel)
    vplex = all_variables(cplexmodel)
    vlpk = all_variables(glpkmodel)

    get_implied_strategy!(vplex, max_strat_cplex, min_strat_cplex)
    get_implied_strategy!(vlpk, max_strat_glpk, min_strat_glpk)

    keys_with_different_values = Set{Int}()
    for key in keys(max_strat_cplex)
        if max_strat_cplex[key] != max_strat_glpk[key]
            push!(keys_with_different_values, key)
        end
    end
    println("Difference in implied max strategy: ", keys_with_different_values)

    empty!(keys_with_different_values)
    for key in keys(min_strat_cplex)
        if min_strat_cplex[key] != min_strat_glpk[key]
            push!(keys_with_different_values, key)
        end
    end
    println("Difference in implied min strategy: ", keys_with_different_values)

    empty!(keys_with_different_values)
    not_even_close = Set{Int}()
    for (id, node) in enumerate(test_game)
        if value(vplex[id]) != value(vlpk[id])
            push!(keys_with_different_values, id)
        end

        if abs(value(vplex[id]) - value(vlpk[id])) > .0000000009325
            push!(not_even_close,id)
        end
    end
    #println("Difference in CPLEX and GLPK: ", keys_with_different_values)
    println("Not close in CPLEX and GLPK: ", not_even_close)

    empty!(keys_with_different_values)
    not_even_close = Set{Int}()
    for (id, node) in enumerate(test_game)
        if abs(value(vcip[id]) - value(vplex[id])) > 1e-15
            push!(not_even_close,id)
        end
    end
    #println("Difference in CPLEX and GLPK: ", keys_with_different_values)
    println("Not close in SCIP and CPLEX: ", not_even_close)

    empty!(keys_with_different_values)
    for (id,node) in enumerate(test_game)
        if (node.type == maximizer)
            if (value(vplex[id]) != value(vplex[node.arc_a]) && value(vplex[id]) != value(vplex[node.arc_b]))
                push!(keys_with_different_values,id)
                #println(value(vlpk[id]) - value(vlpk[node.arc_a])," ",value(vlpk[id]) - value(vlpk[node.arc_b]))
            end
        end
    end
    println("Max node constraint violated (CPLEX): ", keys_with_different_values)

    empty!(keys_with_different_values)
    for (id,node) in enumerate(test_game)
        if (node.type == maximizer)
            if (value(vlpk[id]) != value(vlpk[node.arc_a]) && value(vlpk[id]) != value(vlpk[node.arc_b]))
                push!(keys_with_different_values,id)
            end
        end
    end
    println("Max node constraint violated (GLPK): ", keys_with_different_values)

    empty!(keys_with_different_values)
    for (id,node) in enumerate(test_game)
        if (node.type == minimizer)
            if (value(vcip[id]) > value(vcip[node.arc_a]) || value(vcip[id]) > value(vcip[node.arc_b]))
                push!(keys_with_different_values,id)
                println((value(vlpk[id]) - value(vlpk[node.arc_a]))*1e20," ",(value(vlpk[id]) - value(vlpk[node.arc_b]))*1e20)
            end
        end
    end
    println("Min node constraint violated (SCIP): ", keys_with_different_values)

    empty!(keys_with_different_values)
    for (id,node) in enumerate(test_game)
        if (node.type == minimizer)
            if (value(vplex[id]) > value(vplex[node.arc_a]) || value(vplex[id]) > value(vplex[node.arc_b]))
                push!(keys_with_different_values,id)
            end
        end
    end
    println("Min node constraint violated (CPLEX): ", keys_with_different_values)

    empty!(keys_with_different_values)
    for (id,node) in enumerate(test_game)
        if (node.type == minimizer)
            if (value(vlpk[id]) > value(vlpk[node.arc_a]) || value(vlpk[id]) > value(vlpk[node.arc_b]))
                push!(keys_with_different_values,id)
                #println(value(vlpk[id]) - value(vlpk[node.arc_a])," ",value(vlpk[id]) - value(vlpk[node.arc_b]))
            end
        end
    end
    println("Min node constraint violated (GLPK): ", keys_with_different_values)
end

function get_implied_strategy!(v, max_strat, min_strat)
    for (id, node) in enumerate(test_game)
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
            if a_val >= b_val
                max_strat[id] = node.arc_a
            else
                max_strat[id] = node.arc_b
            end
        end
    end
end

