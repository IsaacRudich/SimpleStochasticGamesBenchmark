"""
    generate_upwards_max_strategy(game::Vector{SGNode})

Create a max node strategy that always points to the highest indexed node

# Arguments
- `game::Vector{SGNode}`: The SSG
"""
function generate_upwards_max_strategy(game::Vector{SGNode})
    max_strat = Dict{Int,Int}()
    for (id, node) in enumerate(game)
        if node.type == maximizer
            if node.arc_a > node.arc_b
                max_strat[id] = node.arc_a
            else
                max_strat[id] = node.arc_b
            end
        end
    end
    return max_strat
end

"""
    generate_downwards_max_strategy(game::Vector{SGNode})

Create a max node strategy that always points to the lowest indexed node

# Arguments
- `game::Vector{SGNode}`: The SSG
"""
function generate_downwards_max_strategy(game::Vector{SGNode})
    max_strat = Dict{Int,Int}()
    for (id, node) in enumerate(game)
        if node.type == maximizer
            if node.arc_a > node.arc_b
                max_strat[id] = node.arc_b
            else
                max_strat[id] = node.arc_a
            end
        end
    end
    return max_strat
end

"""
    generate_random_max_strategy(game::Vector{SGNode})

Create a max node strategy that is random

# Arguments
- `game::Vector{SGNode}`: The SSG
"""
function generate_random_max_strategy(game::Vector{SGNode})
    max_strat = Dict{Int,Int}()
    for (id, node) in enumerate(game)
        if node.type == maximizer
            choice = rand([0,1])
            if choice == 0
                max_strat[id] = node.arc_b
            else
                max_strat[id] = node.arc_a
            end
        end
    end
    return max_strat
end

"""
    generate_inverse_max_strategy(game::Vector{SGNode}, strat::Dict{Int,Int})

Create a max node strategy that inverses an existing strategy

# Arguments
- `game::Vector{SGNode}`: The SSG
- `strat::Dict{Int,Int}`: the strategy to inverse
"""
function generate_inverse_max_strategy(game::Vector{SGNode}, strat::Dict{Int,Int})
    max_strat = Dict{Int,Int}()
    for (id, node) in enumerate(game)
        if node.type == maximizer
            if node.arc_a == strat[id]
                max_strat[id] = node.arc_b
            else
                max_strat[id] = node.arc_a
            end
        end
    end
    return max_strat
end