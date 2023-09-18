
function find_bugs(game, parentmap, inzeronodes)
    #debug check
    for node in game 
       parents = parentmap[node.label]
       if isempty(parents) && !(node.label in inzeronodes)
           println("Bug Type 1: ", node.label)
       end
       for parent in parents
           if game[parent].arc_a != node.label && game[parent].arc_b != node.label
               println("Bug Type 2: ", node.label)
           end
       end
       if node.label != length(game) && node.label != length(game)-1
           if !(node.label in parentmap[node.arc_a]) || !(node.label in parentmap[node.arc_b])
               println("Bug Type 3: ", node.label)
           end
       end
   end
end

# function find_stupid(d,b,c)
#    while true
#        a, parentmap = generate_reduced_stopping_game_efficient(d, b, c; logging_on=false)
#        if check_for_bad_subgraphs(a)
#            return a
#        end
#    end
# end