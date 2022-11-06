function find_elementary_cycles(game::Vector{T})where{T<:Node}
    blocked = zeros(length(game))
    s = 1
    cycles = Vector{Vector{Int}}()
    stack = Vector{Int}()
    blist = Vector{Int}()
    sizehint!(stack, length(game))
end

function unblock!(v::Int, blocked::BitVector, blist::Vector{Int})
    blocked[v] = false
    @inbounds for i in blist
        if blocked[i]
            deleteat!(blist, findfirst(i,blist))
            unblock!(i, blocked, blist)
        end
    end
end

function circuit!(game::Vector{T},v::Int, blocked::BitVector, s::Int, cycles::Vector{Vector{Int}}, stack::Vector{Int}, blist::Vector{Int})where{T<:Node}
    f = false

    push!(blist, v)
    blocked[v] = true

    for w in [game.arc_a, game.arc_b]
        if w == s
            push!(cycles, push!(copy(stack), s))
            f = true
        elseif !blocked[w]
            if circuit!(game, w, blocked, s, cycles, stack, blist)
                f = true
            end
        end
    end

    if f
        unblock!(v, blocked, blist)
    else
        for w in [game.arc_a, game.arc_b]
            if !(v in blist)
                push!(blist, v)
            end
        end
    end

    pop!(v)
    return f
end