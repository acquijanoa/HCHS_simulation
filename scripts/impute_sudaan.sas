%include "J:\HCHS\STATISTICS\GRAS\QAngarita\HCHS_simulation\scripts\_init.sas";

*proc printto log = "&homepath./logs/impute_sudaan_&sysdate..log"
			 print= "&homepath./lst/impute_sudaan_&sysdate..lst" new; run; 

data vars_labels;
    input MODELRHS Variable $20.; 
    	datalines;
	1 Intercept
	2 x17
	3 x12
	4 x18
	5 y_bmi
	6 age_strat_new
	7 x6
    ;
run;

%macro impute_sudaan(n=, corr=);
  %do i = 1 %to &n;
	data samp;
                        set sample.samplemiss_&i;

                        /* log weight */
                        logwt=log(bghhsub_s2);


                        /* weight adjusted for nomresponse */
                        bghhsub_s2_nr = bghhsub_s2/RR_glm;


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
				data samp_1(rename=(x6=x6_1 y_bmi=y_bmi_1 y_gfr=y_gfr_1 bghhsub_s2_nr=w_nr_1)) 
						samp_2(rename=(x6=x6_2 y_bmi=y_bmi_2 y_gfr=y_gfr_2 bghhsub_s2_nr=w_nr_2)) 
						samp_3(rename=(x6=x6_3 y_bmi=y_bmi_3 y_gfr=y_gfr_3 bghhsub_s2_nr=w_nr_3));
				    set SAMP;
				    if V_NUM = 1 then output SAMP_1;
				    else if V_NUM = 2 then output SAMP_2;        
				    else if V_NUM = 3 then output SAMP_3;
				run;
				* sort the output dataset;
				proc sort data = samp_1; by subid; run;
				proc sort data = samp_2; by subid; run;
				proc sort data = samp_3; by subid; run;

				data samp_wide;
                        merge SAMP_1-SAMP_3;
                        by SUBID;

                        IF MISSING(x6_2) = 1 THEN v2miss = 1;
                        else v2miss=0;

                        IF MISSING(x6_3) = 1 THEN v3miss = 1;
                        else v3miss=0;

                        age_x17 = age_strat_new * x17;
                        inverse_weight = 1/bghhsub_s2;

                        logw = log(bghhsub_s2);
                run;

                proc sort data = samp_wide;
                 by subid;
                run;

                proc means data = samp_wide;
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

				PROC MEANS DATA = SAMP_WIDE n nmiss;
                     Var  x17 x12 x18 y_bmi_1-y_bmi_3 age_strat_new
                                x6_2-x6_3 y_gfr_1-y_gfr_3
                                x14 w_nr_1 w_nr_2 w_nr_3;
                output out= mi_miss nmiss=;
                run;

                proc transpose data = mi_miss(drop=_TYPE_ _FREQ_) out=mi_long;
                run;

                proc sort data = mi_long;
                        by col1;
                run;

                proc sql noprint;
                        select distinct _name_ into:var separated by ' ' from mi_long;
                quit;
                %put &var.;

			data samp_wide;
				set samp_wide;
				strat_psu = cats(strat_recoded,bgid);
			run;

			proc mi data=samp_wide seed=2021 nimpute=10 out=samp_complete;	
				class strat_psu;
				fcs reg(x6_2-x6_3 y_gfr_2-y_gfr_3 y_bmi_2-y_bmi_3);
				var &var. bghhsub_s2 strat_psu; 
            run;
	
				    /* Transform the imputed datasets from wide format to long */
                data samp_long;
                        set samp_complete;
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

					* Fit regress model from sudaan using corr matrix; 
				* Looping over the 10 simulated datasets;
				%do j = 1 %to 10; 
					data temp;
						set samp_long;
						if _imputation_ = &j;
					run;
				proc sort data = temp; 
					by strat_recoded bgid hhid subid; 
				run;  	
					options pagesize=60 linesize=80;
					proc regress data = temp filetype=sas r=&corr semethod=zeger;
						%if &corr. = exchangeable %then %do; 
							nest strat_recoded hhid / psulev=2 ;
						%end;
						%else %do;
							nest strat_recoded hhid;
						%end;
						weight bghhsub_s2; *bghhsub_s2_nr;
						model y_gfr = x17 x12 x18 y_bmi age_strat_new x6;
						output beta sebeta p_beta t_beta / filename=betas_mi_&corr._&i._&j filetype=sas replace;
					run;

					data betas_mi_&corr._&i._&j; 
						merge vars_labels betas_mi_&corr._&i._&j ;
						by modelrhs;
						_imputation_ = &j;
						ClassVal0 = '';
						DF = 1;
						rename beta = Estimate sebeta = StdErr p_beta = ProbChisq t_beta = WaldChisq;
						drop PROCNUM MODELNO MODELRHS;
					run;
				%end;
		* merging the 10 datasets;
		data outparms;
			set betas_mi_&corr._&i._1 - betas_mi_&corr._&i._10;
		run;
		* combine estimates;
		proc mianalyze parms = outparms; 
			modeleffects intercept x17 x12 x18 y_bmi age_strat_new x6; 
			ods output ParameterEstimates = betas_mi_&corr._&i;
		run;			
		data dt_betas.betas_mi_&corr._&i;
                        SET betas_mi_&corr._&i(RENAME=(UCLMEAN = UPPERCL LCLMEAN=LOWERCL ));
        run;
  %end;
%mend impute_sudaan;


%impute_sudaan(n=100, corr=independent);
%impute_sudaan(n=100, corr=exchangeable);
