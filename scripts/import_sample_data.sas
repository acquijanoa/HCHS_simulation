%include "J:\HCHS\STATISTICS\GRAS\QAngarita\HCHS_simulation\scripts\_init.sas";

proc printto log = "&homepath./logs/import_sample_data_&sysdate..log"
			 print= "&homepath./lst/import_sample_data_&sysdate..lst" new; run; 
*********************************************************************************************************
        
        PROGRAM NAME: import_sample_data.sas

        PROGRAMMER: AQA    

        DESCRIPTION:  Convert the csv files in sas files

        VERSION CONTROL:
						- 20FEB25: Initialize the code 	

*********************************************************************************************************;

* Macro that import 1 to n csv files and convert them in sas dataset;
%macro process_files(n);
  %do i = 1 %to &n;
    /* Define paths and names dynamically */
    %let csv_file = &homepath./v3data/sample/samplemiss_&i..csv; 
    %let out_table = sample.samplemiss_&i; 
	proc import
		datafile="&csv_file"
        out=&out_table.
        dbms=csv
        replace;
        getnames=yes;
        guessingrows=100;
    run;

	* Derive new variables ;
	data sample.samplemiss_&i; 
	 	set sample.samplemiss_&i; 

		age_strat_new = 1*(age_base >= 45);
		if strat in (1,5) then strat_recoded = 1;
		else if strat in (2,6) then strat_recoded = 2;
		else if strat in (3,7) then strat_recoded = 3;
		else if strat in (4,8) then strat_recoded = 4;

		bghhsub_s2_nr = bghhsub_s2/RR;
	run;

	* sort by strat_recoded;
	 proc sort data = sample.samplemiss_&i; by strat_recoded; run;
  %end;
%mend;

/* Execute the macro */
%process_files(5);

proc printto; run;
