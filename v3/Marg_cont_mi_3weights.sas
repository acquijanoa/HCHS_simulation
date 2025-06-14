/* This program fits the GEE model for 3 visits longitudinal data under various contexts */
/* In particular, the missing visits are handled through MULTIPLE IMPUTATION */
/* The variables in the imputation model are pre-selected from a lasso regression */


OPTIONS MERGENOBY=WARN LS=95 PS=54 NODATE MPRINT formchar="|----|+|---+=|-/\<>*";


%let homepath=/work/users/a/k/aku/sim/v3;
*%let popfile="/work/users/a/k/aku/sim/v3data/set14/sample/samplemiss_&j..csv";
%let popfile="/work/users/b/e/beibo/v3data/sample/samplemiss_&j..csv";

data _null_;
        rnd = int(ranuni(0)*10000);
        CALL SYMPUT("day", put(today(), date9.));
        call SYMPUT("rnd", trim(left(put(rnd, best32.))));
run;


libname home "&homepath";
libname output "&homepath./sasdata";


%let k = &sysparm.;

%let start=%eval((&k-1)*10+1);
%let stop=%eval(&k*10);



/* Read in sample data and lasso variables selected for each replicate */
%macro importdat(start=, stop=);
        %do j=&start %to &stop;
        proc import datafile=&popfile
                out=samp&j.
                dbms=csv
                replace;
                getnames=yes;
                guessingrows=100;
        run;

        %end;

%mend importdat;

%importdat(start=&start,stop=&stop);

/* ------------------- Data Transformation ----------------*/



ods select none;




/* Fit GEE */
%macro itrt(start=, stop=, rowvar=, type=, clst=, wt=, m=, mt=, mivar=, mivar_n=);
        /* Parameter -------------------------------- */

/* start:
                dataset number to start */
/* stop:
                dataset number to end */
/* rowvar:
                the covariates for the gee model */
/* type:
                type for within-cluster correlation (ind/cs) */
/* clst:
                cluster level (subjid/hhid/bgid) */
/* wt:
                adjusted weight    */
/* m:
                method:
                _lasso: use lasso selected variables to do multiple imputation */

/* mt:
                missing type
                _mar: Missing at random
                <missing>: missing completely at random */

/* mivar:
                additional helpful variables to help imputation*/

/* mivar_n:
                name for missing variable adjustment pattern
                p: properly adjusted
                u: under specified
                o: overspecified */


        %do sid = &start. %to &stop.;


                data samp;
                        set samp&sid.;

                        /* log weight */
                        logwt=log(bghhsub_s2);


                        /* weight adjusted for non-response */
                        bghhsub_s2_nr = bghhsub_s2/RR;


                        /* combine strata */
                        if mod(strat, 4)^=0 then strat_c4 = mod(strat, 4);
                        else strat_c4 = 4;

                        age_strat_new = 1*(age_base>=45);
                        hisp_strat_new=1*(hisp_strat='TRUE');
                        hisp_age = hisp_strat_new * age_strat_new;
                        age_wt = age_strat_new* bghhsub_s2;
                        his_wt = hisp_strat_new* bghhsub_s2;

                        if strat_c4 = 1 then do;
                                age_str_1 = age_strat_new;
                                age_str_2 = 0;
                                age_str_3 = 0;
                                his_str_1 = hisp_strat_new;
                                his_str_2 = 0;
                                his_str_3 = 0;
                                age_his_str_1 = age_strat_new * hisp_strat_new;
                                age_his_str_2 = 0;
                                age_his_str_3 = 0;
                                strat_1 = 1;
                                strat_2 = 0;
                                strat_3 = 0;
                                strat_wt_1 = bghhsub_s2;
                                strat_wt_2 = 0;
                                strat_wt_3 = 0;
                        end;
                        if strat_c4 = 2 then do;
                                age_str_2 = age_strat_new;
                                age_str_1 = 0;
                                age_str_3 = 0;
                                his_str_2 = hisp_strat_new;
                                his_str_1 = 0;
                                his_str_3 = 0;
                                age_his_str_2 = age_strat_new * hisp_strat_new;
                                age_his_str_1 = 0;
                                age_his_str_3 = 0;
                                strat_2 = 1;
                                strat_1 = 0;
                                strat_3 = 0;
                                strat_wt_2 = bghhsub_s2;
                                strat_wt_1 = 0;
                                strat_wt_3 = 0;
                        end;
                        if strat_c4 = 3 then do;
                                age_str_3 = age_strat_new;
                                age_str_2 = 0;
                                age_str_1 = 0;
                                his_str_3 = hisp_strat_new;
                                his_str_2 = 0;
                                his_str_1 = 0;
                                age_his_str_3 = age_strat_new * hisp_strat_new;
                                age_his_str_2 = 0;
                                age_his_str_1 = 0;
                                strat_3 = 1;
                                strat_2 = 0;
                                strat_1 = 0;
                                strat_wt_3 = bghhsub_s2;
                                strat_wt_2 = 0;
                                strat_wt_1 = 0;
                        end;
                        if strat_c4 = 4 then do;
                                age_str_3 = 0;
                                age_str_2 = 0;
                                age_str_1 = 0;
                                his_str_3 = 0;
                                his_str_2 = 0;
                                his_str_1 = 0;
                                age_his_str_3 = 0;
                                age_his_str_2 = 0;
                                age_his_str_1 = 0;
                                strat_3 = 0;
                                strat_2 = 0;
                                strat_1 = 0;
                                strat_wt_3 = 0;
                                strat_wt_2 = 0;
                                strat_wt_1 = 0;
                        end;

                        WHERE miss_ind_mar = 0;
                run;


                /* Transform from long to wide */
                /* This step is the preparation step for multiple imputation */
				data samp_1 samp_2 samp_3;
				    set SAMP;
				    if V_NUM = 1 then output SAMP_1(rename=(x6=x6_1 y_bmi=y_bmi_1 y_gfr=y_gfr_1 bghhsub_s2_nr=w_nr_1));
				    else if V_NUM = 2 then output SAMP_2(rename=(x6=x6_2 y_bmi=y_bmi_2 y_gfr=y_gfr_2 bghhsub_s2_nr=w_nr_2));        
				    else if V_NUM = 3 then output SAMP_3(rename=(x6=x6_3 y_bmi=y_bmi_3 y_gfr=y_gfr_3 bghhsub_s2_nr=w_nr_3));
				run;

                data samp_wide;
                        MERGE SAMP_1-SAMP_3;
                        BY SUBID;

                        IF MISSING(x6_2) = 1 THEN v2miss = 1;
                        else v2miss=0;

                        IF MISSING(x6_3) = 1 THEN v3miss = 1;
                        else v3miss=0;

                        age_x17 = age_strat_new * x17;
                        inverse_weight = 1/bghhsub_s2;

                        logw = log(bghhsub_s2);
                run;

                proc sort data = SAMP_WIDE;
                	by subid;
                run;

                proc means data = SAMP_WIDE;
                        var bghhsub_s2;
                        output out=ss p20=p20 p40=p40 p60=p60 p80=p80;
                run;

                data samp_wide;
                        if _n_ = 1 then set ss;
                        set samp_wide;
                        if bghhsub_s2 <= p20 then weight_cat = 1;
                        else if bghhsub_s2 <= p40 then weight_cat = 2;
                        else if bghhsub_s2 <= p60 then weight_cat = 3;
                        else if bghhsub_s2 <= p80 then weight_cat = 4;
                        else weight_cat = 5;
                run;

                /* --- Begin multiple imputation --- */

                /* First we sort the missing variables by their missing frequencies (from lowest to highest) */

                PROC MEANS DATA = SAMP_WIDE n nmiss;
                                Var  x17 x12 x18 y_bmi_1-y_bmi_3 age_strat_new
                                x6_2-x6_3 y_gfr_1-y_gfr_3
                                x14 x12 w_nr_1 w_nr_2 w_nr_3
                                ;
                output out= mi_miss nmiss=;
                run;

                proc transpose data = MI_MISS(DROP=_TYPE_ _FREQ_) OUT=MI_LONG;
                run;

                proc sort data = MI_LONG;
                        by COL1;
                run;

                proc sql noprint;
                        select distinct _name_ into:var separated by ' ' from mi_long;
                quit;


                %put &var.;

                /* Then we fit MI */

                proc mi data=SAMP_WIDE seed=2021 nimpute=5 out=SAMP_COMPLETE;
                        %if %sysfunc(find(x14 x12 w_nr_1 w_nr_2 w_nr_3, weight_cat)) ge 1 %then %do;
                            class weight_cat;
                        %end;
                        %else %if %sysfunc(find(x14 x12 w_nr_1 w_nr_2 w_nr_3, bghhsub_s2)) ge 1 %then %do;
                            class bghzhsub_s2;
                        %end;
                        fcs reg(x6_2-x6_3 y_gfr_2-y_gfr_3 y_bmi_2-y_bmi_3);
                        var &var.;

                run;


                /* Transform the imputed datasets from wide format to long */
                data samp_long;
                        set SAMP_COMPLETE;


                        v_num = 1;
                        x6 = x6_1;
                        y_bmi = y_bmi_1;
                        y_gfr = y_gfr_1;
                        output;

                        v_num = 2;
                        x6 = x6_2;
                        y_bmi = y_bmi_2;
                        y_gfr = y_gfr_2;
                        output;

                        v_num = 3;
                        x6 = x6_3;
                        y_bmi = y_bmi_3;
                        y_gfr = y_gfr_3;
                        output;
                run;


                /* Fit GEE */
                proc genmod data=samp_long;
                        by _IMPUTATION_;
                        class &clst. /*v_num*/;
                        weight bghhsub_s2;
                        model y_gfr = x17 x12 x18 y_bmi age_strat_new x6 / dist=normal;
                        *repeated subject=&clst. / corr=&type. withinsubject=v_num;
                        repeated subject=&clst. /corr=&type.;
                        ods output GEEEmpPEst=betas_weighted_5;
                run;



                /* combine the fitted GEE results for 5 sets of imputation */
                proc mianalyze parms=betas_weighted_5;
                        modeleffects intercept x17 x12 x18 y_bmi age_strat_new x6;
                        ods output
                        ParameterEstimates = BETAS_WEIGHTED;
                run;

                DATA BETAS_WEIGHTED;
                        SET BETAS_WEIGHTED(RENAME=(UCLMEAN = UPPERCL LCLMEAN=LOWERCL ));
                RUN;



                %IF %sysfunc(MOD(&SID, 10)) = 1 %THEN %DO;
                        DATA output.betas&mivar_n._&clst._&type._3wts_mar_&k.;
                                SET BETAS_WEIGHTED;
                        RUN;
                %END;
                %else %do;

                        DATA output.betas&mivar_n._&clst._&type._3wts_mar_&k.;
                                SET output.betas&mivar_n._&clst._&type._3wts_mar_&k. BETAS_WEIGHTED;
                        RUN;
                %end;

        %end;

%mend;



%let mt=_mar;


%itrt(start=&start.,
        stop=&stop.,
        rowvar=x17 x12 x18 y_bmi age_strat_new x6,
        type=ind,
        clst=hhid,
        wt=bghhsub_s2,
        m=_3wts,
        mt=_mar,
        mivar=x14 x12 w_nr_1 w_nr_2 w_nr_3,
        mivar_n=p);
