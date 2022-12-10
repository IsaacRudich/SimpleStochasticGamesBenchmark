#!/bin/bash
#SBATCH --time=72:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --mail-user=isaac.rudich@gmail.com
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

module load julia
julia gen_1M.jl