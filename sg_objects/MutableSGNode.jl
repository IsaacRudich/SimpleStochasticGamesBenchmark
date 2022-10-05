mutable struct MutableSGNode
    label    ::Int
    type     ::NodeTypes
    arc_a    ::Int
    arc_b    ::Int
end

MutableSGNode(label::Int,type::NodeTypes) = MutableSGNode(label,type,0,0)

Base.show(io::IO,node::MutableSGNode) = Base.print(io, "{",node.label,",",node.type," , ",node.arc_a," , ",node.arc_b,"}")
function Base.show(io::IO,nodes::Vector{MutableSGNode})
    i = 1
    for node in nodes
        Base.print(io,node, "  ")
        if mod(i, 3) == 0
            println()
        end
        i+=1
    end
end

Base.hash(node::MutableSGNode) = hash(node.label)

Base.:(==)(x::MutableSGNode,y::MutableSGNode) =  x.type==y.type && x.arc_a==y.arc_a && x.arc_b==y.arc_b ? true : false

"""
    isterminalnode(node::MutableSGNode)

Returns true if the node is of type 'terminal0' , 'terminal1'. Returns false otherwise

# Arguments
- `node::MutableSGNode`: the node in question
"""
function isterminalnode(node::MutableSGNode)
    return (node.type==terminal0 || node.type==terminal1) ? true : false
end

"""
    deepcopy(node::MutableSGNode)

Returns a deep copy of an MutableSGNode

# Arguments
- `node::MutableSGNode`: the node to be deep copied
"""
function deepcopy(node::MutableSGNode)
    return MutableSGNode(node.type, node.arc_a, node.arc_b)
end

"""
    deepcopy(nodes::Vector{MutableSGNode})

Returns a deep copy of an MutableSGNode array

# Arguments
- `node::Vector{MutableSGNode}`: the nodes to be deep copied
"""
function deepcopy(nodes::Vector{MutableSGNode})
    newnodes = Vector{MutableSGNode}(undef,length(nodes))
    for i=eachindex(nodes)
        @inbounds newnodes[i] = deepcopy(nodes[i])
    end
    return newnodes
end