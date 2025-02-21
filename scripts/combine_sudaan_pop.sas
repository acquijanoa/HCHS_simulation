%include "J:\HCHS\STATISTICS\GRAS\QAngarita\HCHS_simulation\scripts\_init.sas";

proc printto log = "&homepath./logs/combine_sudaan_pop_&sysdate..log"
			 print= "&homepath./lst/combine_sudaan_pop_&sysdate..lst" new; run; 
*********************************************************************************************************
        
        PROGRAM NAME: combine_sudaan_pop.sas

        PROGRAMMER: AQA    

        DESCRIPTION:  

        VERSION CONTROL:
						- 20FEB25: Initialize the code 	

*********************************************************************************************************;

* Set macro variables;
%let corr = exchangeable;

* merge files containing beta estimates using sample data;
data merge_betas;
	set v3_outpt.betas_&corr._1 - v3_outpt.betas_&corr._100;
run;

* append the true value coming from population estimates; 
proc sql;
     create table betas_samp_pop as
       select a.*, b.estimate as true 
	   from
       merge_betas as a
       right join 
       v3_outpt.betas_pop_genmod_exch as b 
	   on a.parm=b.parm;
quit;

* Compute 95% confidence intervals;
data betas_samp_pop; 
	set betas_samp_pop;
	uppercl = Estimate + 1.986 * Stderr; 
	lowercl = Estimate - 1.986 * Stderr; 
run;

* Estimate quantities of interest: bias, ...; 
data betas_samp_pop_;
                set betas_samp_pop;
                /*calculate statistics to summarize*/
                inci=(uppercl>=true & lowercl<=true);
                bias=estimate-true;
                relbias=bias/true;
                /*PROBT*/
                rejecth0=(abs(t)>quantile('NORMAL',.975));
run;

proc means data=betas_samp_pop_
                noprint nway;
                class parm;
                var true estimate bias relbias stderr inci rejecth0;
                output out=output_1 mean(true estimate bias relbias stderr inci
                        rejecth0)=true estimate empbias relbias estse coverage
                        prejecth0 std(estimate)=empse;
run;


data output;
      set output_1;
      relse=estse/empse-1;
run;

ods rtf file="&homepath./v3/output/combine_sudaan_exchangeable.rtf" style=journal bodytitle;
        proc print data=output noobs label;
		var parm true estimate empbias relbias empse estse relse coverage prejecth0;
        label parm='Effect' true='True Value' estimate='Estimate'
                        empbias='Empirical Bias' relbias='Relative Bias'
                        empse='Empirical SE' estse='Estimated SE'
                        coverage='Coverage' prejecth0='P(reject H0)'
                        relse='Relative SE difference';
run;
ods rtf close;

proc printto; run;


