struct SGNode <: Node
    type    ::NodeTypes
    arc_a    ::Int
    arc_b    ::Int
end

SGNode(type::NodeTypes) = SGNode(type::NodeTypes,0,0)

Base.show(io::IO,node::SGNode) = Base.print(io, "{",node.arc_a," , ",node.arc_b, " , ",node.type,"}")

Base.:(==)(x::SGNode,y::SGNode) =  x.type==y.type && x.arc_a==y.arc_a && x.arc_b==y.arc_b ? true : false

"""
    isterminalnode(node::SGNode)

Returns true if the node is of type 'terminal0' , 'terminal1'. Returns false otherwise

# Arguments
- `node::SGNode`: the node in question
"""
function isterminalnode(node::SGNode)
    return (node.type==terminal0 || node.type==terminal1) ? true : false
end

"""
    deepcopy(node::SGNode)

Returns a deep copy of an SGNode

# Arguments
- `node::SGNode`: the node to be deep copied
"""
function deepcopy(node::SGNode)
    return SGNode(node.type, node.arc_a, node.arc_b)
end

"""
    deepcopy(nodes::Vector{SGNode})

Returns a deep copy of an SGNode array

# Arguments
- `node::Vector{SGNode}`: the nodes to be deep copied
"""
function deepcopy(nodes::Vector{SGNode})
    newnodes = Vector{SGNode}(undef,length(nodes))
    for i=eachindex(nodes)
        @inbounds newnodes[i] = deepcopy(nodes[i])
    end
    return newnodes
end