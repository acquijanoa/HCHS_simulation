#!/bin/bash

#SBATCH --job-name=sas_run
#SBATCH -n 1
#SBATCH --cpus-per-task=1
#SBATCH --mem=5g
#SBATCH -t 1-

module add sas
sas pop_cont_genmod.sas



