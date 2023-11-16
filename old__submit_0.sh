#!/bin/bash

#SBATCH     --job-name=0__download-data
#SBATCH     --output=0__download-data.out
#SBATCH     --error=0__download-data.err
#SBATCH     --ntasks=128
#SBATCH     --cpus-per-task=1  # number of threads for multi-threading
##SBATCH     --mem-per-cpu=2G
#SBATCH     --mem=0  # use all memory on node
#SBATCH     --time=1-00:00:00  # 2 day max
#SBATCH     --partition=normal
#SBATCH     --mail-type=ALL
#SBATCH     --mail-user=jxw190004@utdallas.edu


julia --project=. 0__download-data.jl
