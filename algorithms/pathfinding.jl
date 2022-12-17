mutable struct PathNode
    id          ::Int
    visited     ::BitVector
    parent      ::Union{PathNode, Nothing}
    children    ::Vector{PathNode}
end

"""
    get_path_to_root(node::PathNode)

Find the path to the root node in a PathNode tree
Returns Vector{Int}

# Arguments
- `node::PathNode`: The end node to start from
"""
function get_path_to_root(node::PathNode)
    path = Vector{Int}()
    sizehint!(path, length(node.visited))
    while !isnothing(node.parent)
        push!(path, node.id)
        node = node.parent
    end
    reverse!(path)
    return path
end

"""
    get_longest_acyclic_path(game::Vector{SGNode}, node_index::Int)

Get the longest acyclic path to a terminal node
Returns Vector{Int}

# Arguments
- `game::Vector{SGNode}`: The SSG
- `node_index::Int`: the index of the node to start the path from
"""
function get_longest_acyclic_path(game::Vector{SGNode}, node_index::Int)
    root_node = PathNode(node_index,falses(length(game)),nothing,PathNode[])
    root_node.visited[node_index] = true
    longest_path = [node_index]
    
    queue = [root_node]

    while !isempty(queue)
        println("queue:", length(queue))
        for node in queue
            longest_path = get_longest_acyclic_path_subroutine!(node, game[node.id].arc_a, game, queue, longest_path)
            longest_path = get_longest_acyclic_path_subroutine!(node, game[node.id].arc_b, game, queue, longest_path)
        end
    end

    return longest_path
end

"""
    get_longest_acyclic_path_subroutine!(node::PathNode, child::Int, game::Vector{SGNode}, queue::Vector{PathNode}, longest_path::Vector{Int})

Subroutine of get_longest_acyclic_path that adds children to the queue and updates the longest_path
Returns Vector{Int}

# Arguments
- `node::PathNode`: the current node being processed
- `child::Int`: the index of the child node in game
- `game::Vector{SGNode}`: The SSG
- `queue::Vector{PathNode}`: the nodes yet to be processed
- `longest_path::Vector{Int}`: the longest path to a terminal found so far
"""
function get_longest_acyclic_path_subroutine!(node::PathNode, child::Int, game::Vector{SGNode}, queue::Vector{PathNode}, longest_path::Vector{Int})
    if !node.visited[child]  #no cycles
        #create the new child
        new_node = PathNode(child, copy(node.visited), node, PathNode[])
        new_node.visited[child] = true
        push!(node.children, new_node)
        #if the new node is a terminal 
        if game[child].type == terminal1 || game[child].type == terminal0
            #if the new node has a longer longest path, update longest path
            if sum(new_node.visited) >= length(longest_path)
                longest_path = get_path_to_root(new_node)
            end
        else #the new node is not a terminal keep searching
            push!(queue, new_node)
        end
    end 
    return longest_path
end

"""
    get_longest_acyclic_paths_to_max_nodes(game::Vector{SGNode})

Get the longest acyclic path from all of the max nodes to a terminal
Returns Dict{Int, Int}, Dict{Int, Vector{Int}}

# Arguments
- `game::Vector{SGNode}`: The SSG
"""
function get_longest_acyclic_paths_to_max_nodes(game::Vector{SGNode})
    longest_path_values = Dict{Int, Int}()
    longest_paths = Dict{Int, Vector{Int}}()

    for (i, node) in enumerate(game)
        if node.type == maximizer
            println("workin on $i")
            longest_paths[i] = get_longest_acyclic_path(game, i)
            longest_path_values[i] = length(longest_paths[i])
        end
    end

    return longest_path_values, longest_paths
end