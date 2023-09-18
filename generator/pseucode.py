
'''
Return the arcB options that can be added to node that will not create a Bad Subgraph

'''
def available_arcs(node):
    # Use BFS to find parent tree s.t. node.arcB points to node in parent tree creates a Bad Subgraph
    parent_tree = set()

    # keep track of occurences of average nodes in parent tree
    average_nodes_ct = dict()

    new_parents = node.parents

    while not empty(new_parents):
        n = []
        for parent in new_parents:
            if parent.type == average:
                if average_nodes_ct[parent.id] == 1:
                    average_nodes_ct[parent.id] = 2
                    parent_tree.add(parent)
                    n.extend(parent.parents)
                elif average_nodes_ct[parent.id] == 0:
                    average_nodes_ct[parent.id] = 1
            else:
                parent_tree.add(parent)
                n.extend(parent.parents)

        new_parents = n

    return parent_tree
        
#dont add things in parent tree

#how many times is the whole graph the parent tree