%include "J:\HCHS\STATISTICS\GRAS\QAngarita\HCHS_simulation\scripts\_init.sas";
/* This program combines the simulation results for 3 visits GEE */

libname home "&homepath";
libname sasdata "&homepath/v3/sasdata";
libname out "&homepath/v3/output";



* ; 
DATA MERGE_BETAS;
      SET sasdata.betasp_hhid_ind_3wts_mar_1 - sasdata.betasp_hhid_ind_3wts_mar_100;
      IF PARM="intercept" THEN PARM="Intercept";
RUN;

proc sql;
     create table DATASET2 as
       select a.*, b.estimate as true from
       MERGE_BETAS a
       right join 
       sasdata.betas_pop_ind b on a.parm=b.parm;
quit;

data out.DATASET2;
                set DATASET2;
                /*calculate statistics to summarize*/
                inci=(uppercl>=true & lowercl<=true);
                bias=estimate-true;
                relbias=bias/true;
                /*PROBT*/
                rejecth0=(abs(z)>quantile('NORMAL',.975));
run;

proc means data=out.DATASET2
                noprint nway;
                class parm;
                var true estimate bias relbias stderr inci rejecth0;
                output out=output_1 mean(true estimate bias relbias stderr inci
                        rejecth0)=true estimate empbias relbias estse coverage
                        prejecth0 std(estimate)=empse;
run;

        data out.sump_hhid_ind_ind_3wts_mar;
                set output_1;
                relse=estse/empse-1;
        run;

        ods rtf
                file="&homepath./output/Marg_p_hhid_ind_ind_3wts_mar.rtf"
                style=journal bodytitle;

        proc print data=out.sump_hhid_ind_ind_3wts_mar
                noobs label;
                var parm true estimate empbias relbias empse estse relse
                        coverage prejecth0;
                label parm='Effect' true='True Value' estimate='Estimate'
                        empbias='Empirical Bias' relbias='Relative Bias'
                        empse='Empirical SE' estse='Estimated SE'
                        coverage='Coverage' prejecth0='P(reject H0)'
                        relse='Relative SE difference';
        run;
        ods rtf close;





