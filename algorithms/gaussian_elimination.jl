"""
    gaussian_elimination(game::Vector{SGNode}, strategy::Dict{Int, Int})

Use a gaussian_elimination to get the values for a set of nodes
Returns: Vector{Float} the values of the nodes

# Arguments
- `game::Vector{SGNode}`: The SSG
- `strategy::Dict{Int, Int}`: a strategy for the max and min nodes
"""
function gaussian_elimination(game::Vector{SGNode}, strategy::Dict{Int, Int})
    # Define the size of the coefficient matrix
    n = length(game)

    # Create a sparse coefficient matrix 'A' and a right-hand side vector 'b'
    A = sparse(1.0 * I, n, n)  # Initialize A as an identity matrix
    b = zeros(n)

    # Iterate over the nodes and add constraints to the matrix and vector
    for (i, node) in enumerate(game)
        if node.type == average
            # A[i, i] = 1.0
            A[i, node.arc_a] = -1/2
            A[i, node.arc_b] = -1/2
        elseif node.type == maximizer || node.type == minimizer
            A[i, strategy[i]] = -1
        elseif node.type == terminal1
            b[i] = 1
        end
    end

    return A \ b
end