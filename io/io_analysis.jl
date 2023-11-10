struct AnalysisDataPoint
    n              ::Int
    m              ::Int
    a              ::Int
    hk_worst       ::Int
    hk_avg         ::Float64
    hk_med         ::Float64
    hk_stdev       ::Float64
    hk_avg_time    ::Float64
    mod_hk_worst   ::Int
    mod_hk_avg     ::Float64
    mod_hk_med     ::Float64
    mod_hk_stdev   ::Float64
    mod_hk_avg_time::Float64
end

"""
    read_balanced_analysis_file(filename::String)

Read an analysis file output by analyze_benchmark_set()

# Arguments
- `filename::String`: The name of the file to be read
"""
function read_balanced_analysis_file(filename::String)
    filepath = string(@__DIR__ , "/../analysis/" , filename)

    analysis = nothing

    open(filepath) do openedfile
        analysis = parse_balanced_analysis!(read(openedfile, String))
    end

    if analysis === nothing
        throw(ArgumentError("Something went wrong reading the file"))
    end

    return analysis
end

"""
    parse_balanced_analysis!(input_data)

Convert the contents of a file to a Dict{String, Vector{Vector{Float32}}} and return it

# Arguments
- `input_data`: The contents of file
"""
function parse_balanced_analysis!(input_data)
    analysis = Dict{String, Vector{AnalysisDataPoint}}()
    names = ["1-4", "2-4", "3-4", "4-4", "5-4", "6-4", "7-4", "8-4"]

    for name in names
        analysis[name] = Vector{AnalysisDataPoint}()
    end

    #split the file into lines
    lines = split(input_data, '\n')

    for i = eachindex(lines)
        split_line = split(lines[i], ' ')
        
        if length(split_line) > 1
            name = split_line[1]
            split_name = split(name, '_')
            key = split_name[1]

            datapoint = AnalysisDataPoint(
                Int(parse(Float64, split_name[2])), #n
                Int(parse(Float64, split_name[3])), #m
                Int(parse(Float64, split_name[4])), #a 
                Int(parse(Float64, split_line[3])), #hk_worst
                parse(Float64, split_line[5]), #hk_average
                parse(Float64, split_line[7]), #hk_med
                parse(Float64, split_line[9]), #hk_stdev
                parse(Float64, split_line[11]), #hk_avg_time
                Int(parse(Float64, split_line[13])), #mod_hk_worst
                parse(Float64, split_line[15]), #mod_hk_average
                parse(Float64, split_line[17]), #mod_hk_med
                parse(Float64, split_line[19]), #mod_hk_stdev
                parse(Float64, split_line[21]), #mod_hk_avg_time
            )

            push!(analysis[key], datapoint)
        end
    end

    return analysis
end