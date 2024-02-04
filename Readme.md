# Simple Stochastic Stopping Game (SSSG) Benchmark Set and Generator

This repository contains a benchmark set with 6400 problems, as well as the code used to generate and analyze the instances. Details about the generator can be found in the paper: *Simple Stochastic Stopping Games:A Generator and Benchmark Library*

## Getting ready to use this repository

0. If you are just looking for the benchmark set, you will find the instances in the *instances/benchmark* folder. If you want to use the generator, continue to Step 1.
1. Install Julia by following the instructions [here](https://julialang.org/downloads/). In theory any up-to-date version of Julia should work, but if not, reverting to v1.10.0 will fix any deprecation issues.
2. Clone this repository by following the instructions [here](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
3. Open the terminal on a Mac or the command shell on a Windows. Navigate to the cloned repository. If you are not sure how to navigate within the temrinal/shell I suggest using a search engine with the phrase *"navigating folders in terminal/shell"*. I am refraining from linking a specific article in case it is removed or edited. 
4. Type `julia` and hit *Enter* to start the julia REPL. It should look like this after a few seconds:<img width="781" alt="Image1" src="https://user-images.githubusercontent.com/65783146/160921840-4259962b-21c4-4a29-8447-532b5112dde8.png">

5. Open the package manager with `]` and then use `add pkgname` to add the following packages: `StatsBase, JuMP, Random, Dates, SparseArrays, LinearAlgebra, SCIP, StatsPlots, ColorSchemes, Plots, Printf`
6. Type `include("StoppingGames.jl")` into the REPL and hit *Enter*. This will load the code.


## Our format for saving SSG instances

Instances are saved in *ssg* files. The first lines are for comments indicated with `#` that will be ignored when the file is read in. We have included authorship and date stamps in our files, but this is not necesarry. All blank lines are also ignored. The first uncommented line must be `NMAX: num` where num is the number of max nodes. The second uncommented line must be `NMin: num` where num is the number of min nodes. The third uncommented line must be `NAVG: num` where num is the number of average nodes. Then the following lines are of the form `node_index arc_one_index arc_two_index node_type`. The first three of those are integers seperated by spaces. The last element of the line must be one of the following:

* minimizer
* min
* maximizer
* max
* average
* avg
* terminal0
* t0
* terminal1
* t1

There must be exactly one of each type of terminal, the 0-terminal must have the index *n-1*, and the 1-terminal must have the index *n*. We reccomend using a text editor if you wish to edit a game manually. Here is an example file:


## Using this repository

The code in this repository is fully self-documenting. In the Julia REPL, if you type `?` it will open the help utility. If you put any function in our code into the help utility, it will provide you with documentation for that function.

### Generating a new instance

To generate a new instance you can use the `generate_new_game` function. It has three required parameters: `nmax::Int, nmin::Int, navg::Int` denoting the number of each type of node. It also has an optional paramter `filename::String` that when used saves the generated instance to the *instances* folder with the given file name. For example, `generate_new_game(10,11,12; filename="test") would try to create an instance with 10 max nodes, 11 min nodes, 12 avg nodes, and then write it to *instances/test.ssg*. However, it will reduce the game by removing trivial subgraphs, and the resulting game might be smaller than the inputs.

### Generating a new benchmark set

To generate a new benchmark set, you can use the `generate_balanced_benchmark_set` function. It has three required parameters: `node_total::Int, num_to_generate::Int=100, filename::String="benchmark/balanced"`. `node_total` is the total number of nodes in each instance (minimum of 15), `num_to_generate` is the number of instances to generate of each ratio of average nodes to max nodes (there are 8 ratios), and `filename` is the prefix for each instance name. If the default `filename` of *"benchmark/balanced"* is used, then it will be written to the benchmark folder, with the prefix *balanced* on each instance name. For example, `generate_balanced_benchmark_set(20, 100, "benchmark/new")` will generate 800 instances with about 20 nodes each, and write them to the *benchmark* folder with the prefix *new*.

### Other useful functions

The following other funtions may also be of interest (documentation for using these is in the code):

* `analyze_benchmark_set` which shows how to call Hoffman-Karp and our Permutation Improvement algorithm which we call Mod-HK in the code
* `read_stopping_game` which reads an appropriately formatted SSG into Julia from a file
* `write_stopping_game` which writes an SSG to a file
* `sort_into_sccs` which breaks a game into its strongly connected components
* `check_for_bad_subgraphs` checks whether a game is a stopping game

Many other functions can be found by exploring the code.

```text
# ex.ssg
# created: 2024-02-04
# using instance generator from Avi Rudich, Isaac Rudich, Rachel Rue

NMAX: 2
NMIN: 2
NAVG: 2

1 4 2 minimizer
2 3 6 minimizer
3 5 6 maximizer
4 6 2 maximizer
5 7 4 average
6 8 7 average
7 0 0 terminal0
8 0 0 terminal1
```

### Using LP Solvers

Please be aware that we set the default solver for LPs to *SCIP* because it is freely available. However, when we generated our data for the paper, we used *CPLEX*. You may freely choose your preferred solves from any on the list found [here](https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers).
