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
|
|---- output/
|--------- pop_genmod.rtf : The beta estimates for the population model.
|
|---- sasdata/
|--------- betas_pop_genmod_exch.sas7bdat : betas in the population model (Exchangeable correlation matrix)
|--------- betas_pop_genmod_ind.sas7bdat: betas in the population model (Independent correlation matrix)  
|
|- v3data/
|---- population_3visits_Dec2024.csv : the population created using V3_pop.R (in .gitignore)
|---- V3_pop.R : Create the synthetic population for running simulations at visit 3
|
|---- sample/
|--------- samplemiss_#.csv : samples from the simulated population 
```

