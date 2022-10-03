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
        splitLine = split(lines[i], ' ')
        if length(splitLine) == 2
            if splitLine[1]=="NMAX:"
                nmax = parse(Int, splitLine[2])
            elseif splitLine[1]=="NMIN:"
                nmin = parse(Int, splitLine[2])
            elseif splitLine[1]=="NAVG:"
                navg = parse(Int, splitLine[2])
            end
            if nmax != 0 && nmin != 0 && navg != 0
                break
            end
        end
    end

    #load game
    nodes = Vector{SGNode}(undef,nmax+nmin+navg+2)
    for i = eachindex(lines)
        splitLine = split(lines[i], ' ')
        if length(splitLine)==4 && tryparse(Int, splitLine[1])!==nothing && tryparse(Int, splitLine[2])!==nothing && tryparse(Int, splitLine[3])!==nothing && get(node_types,splitLine[4],nothing)!==nothing
            nodes[parse(Int, splitLine[1])] = SGNode(parse(Int, splitLine[2]),parse(Int, splitLine[3]),node_types[splitLine[4]])
        end
    end

    return nodes
end

"""
    write_stopping_game(nodes::Vector{SGNode}, filename::String)

Create a file with the given SSG

# Arguments
- `nodes::Vector{SGNode}`: The graph to write to the file
- `filename::String`: The name of the file (do not include an extension, that is done automatically)
"""
function write_stopping_game(nodes::Vector{SGNode}, filename::String)
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
        write(file,string(filename,"\n\n"))
        write(file,string("NMAX: ",nmax,"\n"))
        write(file,string("NMIN: ",nmin,"\n"))
        write(file,string("NAVG: ",navg,"\n\n"))
        for (i,node) in enumerate(nodes)
            write(file,string(i," ",node.arc_a," ",node.arc_b," ",node.type,"\n"))
        end
    close(file)
end