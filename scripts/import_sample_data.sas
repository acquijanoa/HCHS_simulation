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
  %end;
%mend;

/* Execute the macro */
%process_files(5);

proc printto; run;
