include("main.jl")

for i in 1:10
    generate_new_game(1000000, 1000000, 1000000, "1M_$i")
end