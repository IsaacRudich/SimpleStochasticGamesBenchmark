"""
    find_ones_or_zeros(find_ones::Bool, game::Vector{SGNode}, parentmap::Dict{Int, Vector{Int}})

A method thhat find all of the nodes in a game that collapse to a value of 1

# Arguments
- `find_ones::Bool`: if true, finds the ones, else finds the zeros
- `game::Vector{SGNode}`: The SSG
- `parentmap::Dict{Int, Vector{Int}}`: Map to the parents of the nodes
"""
function find_ones_or_zeros(find_ones::Bool, game::Vector{SGNode}, parentmap::Dict{Int, Vector{Int}})
    collapsing_cluster = trues(length(game))
    queue = Vector{Int}()

    for index in Iterators.reverse(1:length(game))
        if find_ones && game[index].type == terminal0
            collapsing_cluster[index] = false
            push!(queue, index)
            break
        elseif !find_ones && game[index].type == terminal1
            collapsing_cluster[index] = false
            push!(queue, index)
            break
        end
    end

    

    while !isempty(queue)
        currrent_index = pop!(queue)
        for parent in parentmap[currrent_index]
            if collapsing_cluster[parent]
                if find_ones
                    if game[parent].type==minimizer || game[parent].type==average
                        collapsing_cluster[parent] = false
                        push!(queue,parent)
                    elseif game[parent].type==maximizer && !collapsing_cluster[game[parent].arc_a] && !collapsing_cluster[game[parent].arc_b]
                        collapsing_cluster[parent] = false
                        push!(queue,parent)
                    end
                else
                    if game[parent].type==maximizer || game[parent].type==average
                        collapsing_cluster[parent] = false
                        push!(queue,parent)
                    elseif game[parent].type==minimizer && !collapsing_cluster[game[parent].arc_a] && !collapsing_cluster[game[parent].arc_b]
                        collapsing_cluster[parent] = false
                        push!(queue,parent)
                    end
                end
            end
        end
    end

    for node in 1:lastindex(game)-2
        if find_ones && collapsing_cluster[node]
            if (!collapsing_cluster[game[node].arc_a] || !collapsing_cluster[game[node].arc_b]) && (game[node].type == average || game[node].type == minimizer)
                println(node.type," ", node)
            elseif game[node].type == maximizer && (!collapsing_cluster[game[node].arc_a] && !collapsing_cluster[game[node].arc_b])
                println("Max: ", node)
            end
        end
    end

    return collapsing_cluster
end