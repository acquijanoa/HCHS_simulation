*********************************************************************************************************
        
        PROGRAM NAME: pop_cont_genmod.sas

        SOURCE:        Wenyi's code + Alex updates

        DESCRIPTION:   This program fits the GEE on the population level and get the true coefficients for inference 

        VERSION CONTROL:
                        01.24.25 Include headers, comments and update the code to make it clear

*********************************************************************************************************;
* Set system options;
OPTIONS MERGENOBY=WARN LS=95 PS=54 NODATE MPRINT
        formchar="|----|+|---+=|-/\<>*";

* Macro variable that create path to my folder ;
%let homepath=/work/users/a/q/aquijano/HCHS/v3;

* Path to Beibo's folder that contains the simulated population data;
%let popfile="/work/users/b/e/beibo/v3data/population_3visits_Dec2024.csv";

* Call libraries in;
libname home "&homepath";
libname output "&homepath./sasdata";

* Import the dataset;
proc import datafile=&popfile out=pop_data(keep=bgid hhid subid y_bmi y_gfr x12
        x17 x18 x14 x6 age_base strat hisp_strat v_num) dbms=csv replace;
        getnames=yes;
        guessingrows=100;
run;

data pop;
        set pop_data;
        age_strat_new=1*(age_base>=45);
        hisp_strat_new=1*(hisp_strat='TRUE');
run;

%macro pop(type=, m=, mt=);
        proc genmod data=pop;
                class subid;
                model y_gfr=x17 x12 x18 y_bmi age_strat_new x6/ dist=normal;
                repeated subject=subid / corr=&type.;
                %if &m.=_miss %then %do;
                        where miss_ind&mt.=0;
                %end;
                ods output GEEEmpPEst=output.betas_pop_genmod_&type.&m.&mt.;
        run;
%mend pop;

ods rtf file="&homepath./output/pop_genmod.rtf";
%let mt= ;
title '[PROC GENMOD]Independent correlation structure';
%pop(type=ind, mt=&mt.);
title '[PROC GENMOD]Exchangeable correlation structure';
%pop(type=exch, mt=&mt.);
title;
ods rtf close;
