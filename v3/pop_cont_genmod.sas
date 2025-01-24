/* This program fits the GEE on the population level and get the true coefficients for inference */
%let homepath=/work/users/a/q/aquijano/HCHS/v3;
*%let popfile="/work/users/a/k/aku/sim/v3data/set14/population_3visits_Mar2021_missind.csv";
%let popfile="/work/users/b/e/beibo/v3data/population_3visits_Dec2024.csv";

libname home "&homepath";

libname output "&homepath./sasdata";

OPTIONS MERGENOBY=WARN LS=95 PS=54 NODATE MPRINT
        formchar="|----|+|---+=|-/\<>*";

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
