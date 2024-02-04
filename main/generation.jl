"""
    generate_new_game(nmax::Int, nmin::Int, navg::Int; filename::Union{Nothing, String} = nothing)

Generate a new SSG, and writes it to a file in the instances folder if a filename is provided
Returns {Vector{SGNode}} the SSG

# Arguments
- `nmax::Int`: number of max nodes
- `nmin::Int`: number of min nodes
- `navg::Int`: number of average nodes
- `filename::Union{Nothing, String}`: the name of the file to write the game to
"""
function generate_new_game(nmax::Int, nmin::Int, navg::Int; filename::Union{Nothing, String} = nothing)
    game, sccs  = generate_fully_reduced_stopping_game(nmax,nmin,navg)

    if !isnothing(filename)
        write_stopping_game(game, string(filename,".ssg"))
    end

    return game
end 

"""
    generate_balanced_benchmark_set(node_total::Int, num_to_generate::Int=100, filename::String="benchmark/balanced"; logging_on::Bool=false)

Generate a benchmark set of SSGs at the given size (num_to_generate*8)
This will fail for node_totals less than 15 because the number of average nodes is too small to satisfy the ratios

# Arguments
- `node_total::Int`: the intended number of nodes in the graph (it will be close to this, but not exact)
- `num_to_generate::Int=100`: how many of each ratio of nodes to generate (ratio is avg nodes to max nodes)
- `filename::String`: the file name that will be at the start of each instance name
- `logging_on::Bool`: whetehr or not the generator should log its progress at each attempt
"""
function generate_balanced_benchmark_set(node_total::Int, num_to_generate::Int=100, filename::String="benchmark/balanced"; logging_on::Bool=false)
    a_modifiers = [9,5,11/3,3,13/5,7/3,15/7,2]
    mn_modifiers = [4,2,4/3,1,4/5,2/3,4/7,1/2]
    names = ["1-4", "2-4", "3-4", "4-4", "5-4", "6-4", "7-4", "8-4"]

    a = 0
    m = 0
    n = 0
    folder_name = string(filename, "_$node_total")
    if !isdir(string("instances/", folder_name))
        mkdir(string("instances/", folder_name))
    end

    for i in 1:lastindex(a_modifiers)
        a = round(Int, (node_total-1)/a_modifiers[i])
        m = round(Int,a*mn_modifiers[i])
        n = m
        new_node_total = a + m + n + 2
        println("$a $m $n $new_node_total")

        for j in 1:num_to_generate
            game, sccs  = generate_fully_reduced_stopping_game(m,n,a)
            while length(game)  != new_node_total || length(sccs) != 3
                game, sccs  = generate_fully_reduced_stopping_game(m, n, a, logging_on=logging_on)
            end
            write_stopping_game(game, string(folder_name,"/",names[i],"_$m","_$n","_$a","_$j",".ssg"))
        end
    end
end