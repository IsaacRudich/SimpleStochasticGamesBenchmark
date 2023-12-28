using StatsPlots
using ColorSchemes
using Plots.PlotMeasures
using Printf

function graph_analysis_data()
    data = Dict{String, Dict{String, Vector{AnalysisDataPoint}}}()

    data["4096"] = read_balanced_analysis_file("balanced_4096.txt")
    data["2048"] = read_balanced_analysis_file("balanced_2048.txt")
    data["1024"] = read_balanced_analysis_file("balanced_1024.txt")
    data["512"] = read_balanced_analysis_file("balanced_512.txt")
    data["256"] = read_balanced_analysis_file("balanced_256.txt")
    data["128"] = read_balanced_analysis_file("balanced_128.txt")

    graph_grouped_boxplot(data["4096"], "avg_itr", name = "graphs/avg_itr_boxplots_4096", ylims = (0, 28), ytick = 5.0, title = "Average Iterations to Solve for Size 4096 Games", ylabel="Average Number of Iterations")
    graph_grouped_boxplot(data["2048"], "avg_itr", name = "graphs/avg_itr_boxplots_2048", ylims = (0, 26), ytick = 5.0, title = "Average Iterations to Solve for Size 2048 Games", ylabel="Average Number of Iterations")
    graph_grouped_boxplot(data["1024"], "avg_itr", name = "graphs/avg_itr_boxplots_1024", ylims = (0, 18), ytick = 5.0, title = "Average Iterations to Solve for Size 1024 Games", ylabel="Average Number of Iterations")
    graph_grouped_boxplot(data["512"], "avg_itr", name = "graphs/avg_itr_boxplots_512", ylims = (0, 16), ytick = 5.0, title = "Average Iterations to Solve for Size 512 Games", ylabel="Average Number of Iterations")
    graph_grouped_boxplot(data["256"], "avg_itr", name = "graphs/avg_itr_boxplots_256", ylims = (0, 13), ytick = 5.0, title = "Average Iterations to Solve for Size 256 Games", ylabel="Average Number of Iterations")
    graph_grouped_boxplot(data["128"], "avg_itr", name = "graphs/avg_itr_boxplots_128", ylims = (0, 12), ytick = 5.0, title = "Average Iterations to Solve for Size 128 Games", ylabel="Average Number of Iterations")
    
end

function graph_grouped_boxplot(
        analysis_data::Dict{String, Vector{AnalysisDataPoint}}, 
        analysis_type::String;
        name::String="./graphs/boxplots", 
        ylims::Tuple{Int,Int}=(0,28),
        ytick::Float64=5.0,
        legend::Any=:topright,
        title::String = "Title",
        ylabel::String = "y label"
    )
    
    # Extract hk_avg for each problem type into an array of arrays
    hk_values = Float64[]
    mod_hk_values = Float64[]
    problem_type_labels = String[]
    problem_types = collect(keys(analysis_data))
    sort!(problem_types)
    

    # Iterate over the sorted problem types
    for ptype in problem_types
        # Append hk_avg values and their corresponding problem type label to the arrays
        for dp in analysis_data[ptype]
            if analysis_type == "avg_itr"
                push!(hk_values, dp.hk_avg)
                push!(mod_hk_values, dp.mod_hk_avg)
            elseif analysis_type == "worst_itr"
                push!(hk_values, dp.hk_worst)
                push!(mod_hk_values, dp.mod_hk_worst)
            elseif analysis_type == "avg_time"
                push!(hk_values, dp.hk_avg_time)
                push!(mod_hk_values, dp.mod_hk_avg_time)
            end
            push!(problem_type_labels, ptype)
        end
    end

    x = [problem_type_labels; problem_type_labels]
    y = [hk_values; mod_hk_values]
    g = [fill("hk", length(hk_values)); fill("perm-impr", length(mod_hk_values))]


    cs = palette(ColorSchemes.rainbow, 7)
    cs = [cs[1],cs[2]]
    plot = groupedboxplot(x ,y, 
            group = g, 
            bar_width = 0.6,
            ylims=ylims,
            legendfontsize = 8,
            xlabel="Ratio of Average Nodes to Max Nodes", ylabel=ylabel, 
            size = (790,420),dpi=600, legend= legend,
            bottom_margin = 20px,left_margin = 20px,right_margin = 20px,top_margin = 0px,
            yticks = range(ylims[1], stop = ylims[2], step = ytick),
            palette = cs,
            title = title
    )

    # display(plot)

    savefig(plot, name)
end

function print_latex_table(selection::String="avg")
    data = Dict{String, Dict{String, Vector{AnalysisDataPoint}}}()

    data["4096"] = read_balanced_analysis_file("balanced_4096.txt")
    data["2048"] = read_balanced_analysis_file("balanced_2048.txt")
    data["1024"] = read_balanced_analysis_file("balanced_1024.txt")
    data["512"] = read_balanced_analysis_file("balanced_512.txt")
    data["256"] = read_balanced_analysis_file("balanced_256.txt")
    data["128"] = read_balanced_analysis_file("balanced_128.txt")

    table_data = Dict{Tuple{String,String}, Float64}()
    # Iterate through each instance size
    for (instance_size, analysis_data) in data
        # Compute average iterations for each problem type
        for (problem_type, data_points) in analysis_data
            table_cell = nothing
            if selection == "avg"
                table_cell = mean([dp.hk_avg for dp in data_points])
            elseif selection == "time"
                table_cell = mean([dp.hk_avg_time for dp in data_points])*1000
            elseif selection == "avg-m"
                table_cell = mean([dp.mod_hk_avg for dp in data_points])
            elseif selection == "time-m"
                table_cell = mean([dp.mod_hk_avg_time for dp in data_points])*1000
            end
            table_data[(instance_size,problem_type)] = table_cell
        end
    end

    # Find unique problem types and instance sizes
    problem_types = unique([key[2] for key in keys(table_data)])
    sort!(problem_types)

    instance_sizes = ["128", "256","512","1024","2048","4096"]
 
   # Begin LaTeX table
   latex_code = "\\begin{tabular}{c|" * repeat("c|", length(instance_sizes)-1) * "c}\n\\hline\n"

   # Header row with diagonally divided cell
   latex_code *= "\\tiny{\\diagbox{ratio}{size}} & " * join(instance_sizes, " & ") * " \\\\\n\\hline\n"

   # Data rows
   for problem_type in problem_types
       latex_code *= problem_type
       for instance_size in instance_sizes
           latex_code *= " & " * @sprintf("%.1f", get(table_data, (instance_size, problem_type), 0.0))
       end
       latex_code *= " \\\\\n"
   end

   # End LaTeX table
   latex_code *= "\\end{tabular}"

   println(latex_code)
end