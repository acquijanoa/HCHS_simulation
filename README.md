# HCHS_simulation

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
- [Folder Structure](#folder-structure)

This include the files for running simulations for the Hispanic Community Healh Study

## Folder structure 
```
|- v3/
|---- Marg_cont_comb_20210204.sas :
|---- Marg_cont_mi_3weights.sas : 
|---- pop_cont_genmod.sas : Use the population data and PROC GENMOD to fit the model for a continuous covariate
|---- output/
|---- sasdata/
|
|- v3data/
|---- V3_pop.R : Create the synthetic population for running simulations at visit 3
|---- sample/
|--------- samplemiss_#.csv : samples from the simulated population 
```

