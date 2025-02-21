ods _all_ close; /* Close all open ODS destinations */
ods listing;     /* Re-enable the default listing destination */

%let input = %scan(&sysparm,1,*);
%let output =  %scan(&sysparm,2,*);

data "&output";
 set "&input";
	length var $ 10;
	var = "added";
run;

proc print data = "&output"; run; 
 
