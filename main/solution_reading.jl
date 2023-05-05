"""
    print_solution_values(game::Vector{SGNode}, values::Dict{Int, Float64})

Prints the values of a solution

# Arguments
- `game::Vector{SGNode}`: The SSG
- `values::Dict{Int, Float64}`: The solution values
"""
function print_solution_values(game::Vector{SGNode}, values::Dict{Int, Float64})
    for i in 1:length(game)
        println(i, " => ", round(values[i],digits = 4))
    end
end

"""
    retrive_solution_values(game::Vector{SGNode})

Returns the values of a solution

# Arguments
- `game::Vector{SGNode}`: The SSG
- `strategy::Dict{Int, Int}`: The strategy for the max/min nodes to use
"""
function retrive_solution_values(game::Vector{SGNode}, strategy::Dict{Int, Int})
     # Initialize arrays to store row, column indices, and values for the sparse matrix
     rows = Vector{Int}()
     cols = Vector{Int}()
     vals = Vector{Float64}()
     sizehint!(rows, length(game))
     sizehint!(cols, length(game))
     sizehint!(vals, length(game))

     # Initialize a right-hand side vector
     b = zeros(length(game))

     # Loop over the nodes and build the sparse matrix based on their type
     @inbounds for (i,node) in enumerate(game)
        if node.type == average
            push!(rows, i)
            push!(cols, node.arc_a)
            push!(vals, 0.5)

            push!(rows, i)
            push!(cols, node.arc_b)
            push!(vals, 0.5)

            push!(rows, i)
            push!(cols, i)
            push!(vals, -1.0)
        elseif node.type == maximizer || node.type == minimizer
            push!(rows, i)
            push!(cols, strategy[i])
            push!(vals, 1.0)

            push!(rows, i)
            push!(cols, i)
            push!(vals, -1.0)
        elseif node.type == terminal1
            push!(rows, i)
            push!(cols, i)
            push!(vals, 1.0)

            b[i] = 1
        else
            push!(rows, i)
            push!(cols, i)
            push!(vals, 1.0)
        end
    end

    # Create the sparse matrix A
    A = sparse(rows, cols, vals, length(game), length(game))

    # Solve the linear system Ax = b
    x = A \ b

    values = Dict{Int, Float64}()
    
    @inbounds for i in eachindex(x)
        values[i] = x[i]
    end

    return values
end