"""
    read_stopping_game(filePath::String)

Read a properly formatted file and return a Vector{SGNode}

# Arguments
- `filename::String`: The name of the file to be read
"""
function read_stopping_game(filename::String)
    filepath = string(@__DIR__ , "/../instances/" , filename)

    sg = nothing

    open(filepath) do openedfile
        sg = parseinput!(read(openedfile, String))
    end

    if sg === nothing
        throw(ArgumentError("Something went wrong reading the file"))
    end

    return sg
end

"""
    parseinput!(input_data)

Convert the contents of a file to a Vector{SGNode} and return it

# Arguments
- `input_data`: The contents of file
"""
function parseinput!(input_data)
    #acceptable formats for node type
    node_types = Dict([
        ("minimizer", minimizer),
        ("min", minimizer),
        ("3", minimizer),
        ("maximizer", maximizer),
        ("max", maximizer),
        ("2", maximizer),
        ("average", average),
        ("avg", average),
        ("4", average),
        ("terminal0", terminal0),
        ("t0",terminal0),
        ("0", terminal0),
        ("terminal1", terminal1),
        ("t1",terminal1),
        ("1", terminal1)
    ])

    #split the file into lines
    lines = split(input_data, '\n')

    #retrieve the settings for the game
    nmax::Int=0
    nmin::Int=0
    navg::Int=0

    for i = eachindex(lines)
        split_line = split(lines[i], ' ')
        if length(split_line) == 2
            if split_line[1]=="NMAX:"
                nmax = parse(Int, split_line[2])
            elseif split_line[1]=="NMIN:"
                nmin = parse(Int, split_line[2])
            elseif split_line[1]=="NAVG:"
                navg = parse(Int, split_line[2])
            end
            if nmax != 0 && nmin != 0 && navg != 0
                break
            end
        end
    end

    #load game
    nodes = Vector{SGNode}(undef,nmax+nmin+navg+2)
    for i = eachindex(lines)
        split_line = split(lines[i], ' ')
        if length(split_line)==4 && tryparse(Int, split_line[1])!==nothing && tryparse(Int, split_line[2])!==nothing && tryparse(Int, split_line[3])!==nothing && get(node_types,split_line[4],nothing)!==nothing
            if length(nodes) >= parse(Int, split_line[1])
                nodes[parse(Int, split_line[1])] = SGNode(node_types[split_line[4]], parse(Int, split_line[2]),parse(Int, split_line[3]))
            else
                push!(nodes, SGNode(node_types[split_line[4]], parse(Int, split_line[2]),parse(Int, split_line[3])))
            end
        end
    end

    return nodes
end

"""
    write_stopping_game(nodes::Vector{SGNode}, filename::String; num_iterations::Union{Nothing, Int})

Create a file with the given SSG

# Arguments
- `nodes::Vector{SGNode}`: The graph to write to the file
- `filename::String`: The name of the file (do not include an extension, that is done automatically)
- `max_iterations::Union{Nothing, Int}`: if it is not nothing, a line will be added to the file recording this number
- `min_iterations::Union{Nothing, Int}`: if it is not nothing, a line will be added to the file recording this number
"""
function write_stopping_game(nodes::Vector{SGNode}, filename::String; max_iterations::Union{Nothing, Int}=nothing,min_iterations::Union{Nothing, Int}=nothing, sccs::Union{Nothing,Vector{Vector{Int}}} = nothing)
    filepath = string(@__DIR__ , "/../instances/" , filename)
    nmax::Int=0
    nmin::Int=0
    navg::Int=0

    for node in nodes
        if node.type==maximizer
            nmax += 1
        elseif node.type==minimizer
            nmin += 1
        elseif node.type==average
            navg += 1
        end
    end

    file = open(string(@__DIR__ , "/../instances/" , filename),"w")
        write(file,string("# ",filename,"\n"))
        write(file,string("# created: ",Dates.today(),"\n"))
        write(file,string("# using instance generator from Avi Rudich, Isaac Rudich, Rachel Rue","\n\n"))
        if !isnothing(max_iterations)
            write(file,string("# worst known Hoffman-Karp seed converges in: $max_iterations"," for max player\n\n"))
        end
        if !isnothing(min_iterations)
            write(file,string("# worst known Hoffman-Karp seed converges in: $min_iterations"," for min player\n\n"))
        end
        write(file,string("NMAX: ",nmax,"\n"))
        write(file,string("NMIN: ",nmin,"\n"))
        write(file,string("NAVG: ",navg,"\n\n"))
        if isnothing(sccs)
            for (i,node) in enumerate(nodes)
                write(file,string(i," ",node.arc_a," ",node.arc_b," ",node.type,"\n"))
            end
        else
            counter = 1
            for scc in sccs
                for e in scc
                    node = nodes[counter]
                    write(file,string(counter," ",node.arc_a," ",node.arc_b," ",node.type,"\n"))
                    counter += 1
                end
                write(file,"--------------------------------------\n")
            end
        end
    close(file)
end

"""
    write_analysis(filename::String, instancename::String, worst::Int, avg::Float64)

Append to an analysis file

# Arguments
- `filename::String`: The name of the file (do not include an extension, that is done automatically)
- `instancename::String`: the name of the instance being analyzed
- `worst::Int`: the longest run time in HK iterations
- `avg::Float64`: the average run time in HK iterations
- `time::Float64`: the average run time in seconds for HK
- `worst_mod::Int`: the longest run time in mod-HK iterations
- `avg_mod::Float64`: the average run time in mod-HK iterations
- `time_mod::Float64`: the average run time in seconds for mod-HK
"""
function write_analysis(filename::String, instancename::String, worst::Int, avg::Float64, time::Float64, worst_mod::Int, avg_mod::Float64, time_mod::Float64)
    file = open(string(@__DIR__ , "/../analysis/" , filename,".txt"),"a")
        write(file,string(instancename," HK-worst: $worst"," HK-avg: $avg"," HK-avg-time: $time"," HK-mod-worst: $worst_mod"," HK-mod-avg: $avg_mod"," HK-mod-avg-time: $time_mod","\n"))
    close(file)
end