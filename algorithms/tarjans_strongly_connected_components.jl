"""
    tarjans_strongly_connected_components!(game::Vector{T})where{T<:Node}
    
Uses tarjan's linear time algorithm for finding strongly connected components in a directed graph
Citation: Tarjan, Robert. "Depth-first search and linear graph algorithms." SIAM journal on computing 1.2 (1972): 146-160
Wikipedia: https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm
Returns sccs::Vector{Vector{Int}}, a list of strongly connected components

# Arguments
- `game::Vector{T}`: the SSG to consider
- `nodestoconsider::BitVector`: nodes that can be included
- `stack::Vector{Int}`: pre-allocated for performance
- `vindex::Vector{Int}`: pre-allocated for performance
- `vlowlink::Vector{Int}`: pre-allocated for performance
- `vonstack::BitVector`: pre-allocated for performance
- `sccs::Vector{Vector{Int}}`: pre-allocated for performance
"""
function tarjans_strongly_connected_components!(game::Vector{T},nodestoconsider::BitVector, stack::Vector{Int}, vindex::Vector{Int},vlowlink::Vector{Int}, vonstack::BitVector,sccs::Vector{Vector{Int}})where{T<:Node}
    index = 1
    empty!(stack)
    vindex .= zero(Int)
    vlowlink .= zero(Int)
    vonstack .= false
    empty!(sccs)
    @inbounds for (i,v) in enumerate(game)
        if nodestoconsider[i] && vindex[i] == 0 
            index = tarjans_strong_connect!(i,v,vindex, vlowlink,vonstack,index, stack,game, sccs,nodestoconsider)
        end
    end

    return sccs
end

"""
    tarjans_strong_connect!(i::Int, v::T, vindex::Vector{Int},vlowlink::Vector{Int}, vonstack::BitVector, index::Int, stack::Vector{Int}, game::Vector{T},sccs::Vector{Vector{Int}})where{T<:Node}
    
Recursive subroutine for tarjan's strong connected component finder
Returns index::Int, the updated index

# Arguments
- `i::Int`: the index of v in the game
- `v::T`: the root node for this call
- `vindex::Vector{Int}`: map of i -> index
- `vlowlink::Vector{Int}`: map of i -> lowlink
- `vonstack::BitVector`: map of i -> onstack
- `index::Int`: current index
- `stack::Vector{Int}`: the stack of node indexes
- `game::Vector{T}`: the SSG to consider
- `sccs::Vector{Vector{Int}}`: the list of strongly connected components
- `nodestoconsider::BitVector`: nodes that can be included
"""
function tarjans_strong_connect!(i::Int, v::T, vindex::Vector{Int},vlowlink::Vector{Int}, vonstack::BitVector, index::Int, stack::Vector{Int}, game::Vector{T},sccs::Vector{Vector{Int}},nodestoconsider::BitVector)where{T<:Node}
    #Set the depth index for v to the smallest unused index
    vindex[i] = index
    vlowlink[i] = index
    index += 1
    push!(stack, i)
    vonstack[i] = true

    #Consider successors of v
    if v.arc_a != 0 && nodestoconsider[v.arc_a]
        if vindex[v.arc_a]==0
            #Successor w has not yet been visited; recurse on it
            index = tarjans_strong_connect!(v.arc_a,game[v.arc_a],vindex, vlowlink,vonstack,index, stack,game,sccs,nodestoconsider)
            vlowlink[i] = min(vlowlink[i], vlowlink[v.arc_a])
        elseif vonstack[v.arc_a]
            #Successor w is in stack S and hence in the current SCC
            #If w is not on stack, then (v, w) is an edge pointing to an SCC already found and must be ignored
            #Note: The next line may look odd - but is correct.
            #It says w.index not w.lowlink; that is deliberate and from the original paper
            vlowlink[i] = min(vlowlink[i], vindex[v.arc_a])
        end
    end
    #same as above, but without the comment and arc_a -> arc_b
    if v.arc_b != 0 && nodestoconsider[v.arc_b]
        if vindex[v.arc_b]==0
            index = tarjans_strong_connect!(v.arc_b,game[v.arc_b],vindex, vlowlink,vonstack,index, stack,game,sccs,nodestoconsider)
            vlowlink[i] = min(vlowlink[i], vlowlink[v.arc_b])
        elseif vonstack[v.arc_b]
            vlowlink[i] = min(vlowlink[i], vindex[v.arc_b])
        end
    end

    #If v is a root node, pop the stack and generate an SCC
    if vlowlink[i] == vindex[i]
        #start a new strongly connected component
        scc = Vector{Int}()
        sizehint!(scc, length(stack))
        w = 0
        @inbounds while w != i
            w = pop!(stack)
            vonstack[w] = false
            push!(scc,w)
        end
        push!(sccs, scc)
    end

    return index
end