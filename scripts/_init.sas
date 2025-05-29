
* set macro variables;
%let homepath = J:/HCHS/STATISTICS/GRAS/QAngarita/HCHS_simulation;
%let popfile = J:/HCHS/STATISTICS/GRAS/QAngarita/HCHS_simulation/data/raw/pop/population_3visits_Dec2024.csv;

* Set library names;
libname v3data "&homepath./v3data";
libname sample "&homepath./data/derived/sample";
libname v3_outpt "&homepath./v3/sasdata";
libname dt_betas "&homepath./data/processed/betas";
libname betas_b "&homepath./data/processed/betas/bin";


