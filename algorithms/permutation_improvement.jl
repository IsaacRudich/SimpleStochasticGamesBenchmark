function permutation_improvment(game::Vector{SGNode},average_node_order::Vector{Int}; logging_on::Bool = true)
	#memory allocation
	labeled = zeros(Int, length(game)-2)
    queue = Vector{Int}()
    sizehint!(queue, length(game))
    strategy = Dict{Int, Int}()
    values = Vector{Float64}()

    #strategy initialization
	parentmap = get_parent_map(game)
	min_parent_map = get_min_parents(game, parentmap)
	max_tails = get_max_tails(game, parentmap)

    total = -1
    while sum(values) != total
        total = sum(values)
        strategy = generate_strategy_from_average_order(game, average_node_order, max_tails, min_parent_map, labeled, queue)
        values = gaussian_elimination(game, strategy)
        sort!(average_node_order, by=id -> values[id], rev = true)
        println("Permutation: Improvement Objective Value: ",sum(values))
    end

    return strategy
end

function test_permutation()
    game = read_stopping_game("benchmark/balanced_4096/1-4_1820_1820_455_30.ssg")

    hk_solution = nothing
    elapsed_time = 0
    while isnothing(hk_solution)
        max_strat = generate_random_max_strategy(game)
        elapsed_time = @elapsed begin
            hk_solution = hoffman_karp_switch_max_nodes(game,max_strat, logging_on = true, auto_terminate = true)
        end
    end

    avg_node_order = generate_random_average_nodes_order(game)

    elapsed_time_2 = @elapsed begin
        permutation_improvment(game,avg_node_order, logging_on = true)
    end

    println("HK: $elapsed_time PermutationImprovement: $elapsed_time_2")
end