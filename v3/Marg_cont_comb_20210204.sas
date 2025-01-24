/* This program combines the simulation results for 3 visits GEE */
OPTIONS MERGENOBY=error LS=max PS=max NODATE MPRINT
        formchar="|----|+|---+=|-/\<>*";

%let homepath=/work/users/a/k/aku/sim/v3;

libname home "&homepath";
libname inter "&homepath/sasdata";
libname out "&homepath/output";

*%let suffix=;
*if continuous;
%let suffix=_bin; *if binary;

%macro combresSAS(model=, clst=, type=, ptype=, m=, mt=, miss_n=);
        data all&miss_n._&clst._&type.&m.&mt.&suffix.;
                set inter.betas&miss_n._&clst._&type.&m.&mt.&suffix._1 -
                        inter.betas&miss_n._&clst._&type.&m.&mt.&suffix._100;
                if parm="intercept" then parm="Intercept";
        run;

        title3 'Model-Based Inference';
        %if &model=survey %then %do;
                data all&miss_n._&clst._&type.&m.&mt.&suffix.;
                        set all&miss_n._&clst._&type.&suffix.
                                (rename=(parameter=parm tvalue=z));
                run;
        %end;

        proc sql;
                create table agg&miss_n._&clst._&type._&ptype&m.&mt.&suffix. as
                        select a.*, b.estimate as true from
                        all&miss_n._&clst._&type.&m.&mt.&suffix. a
                        /*right join inter.betas_pop_&ptype._miss b on a.parm=b.parm;*/
                        right join %if &m. ne %then %do;
                /*inter.betas_pop_&ptype.&mt. b on a.parm=b.parm;*/
                inter.betas_pop_&ptype. b on a.parm=b.parm;
                %end;
                %else %do;
                        /*inter.betas_pop_&ptype._miss&mt. b on a.parm=b.parm;*/
                        /*inter.betas_pop_&ptype.&mt. b on a.parm=b.parm;*/
                        inter.betas_pop_&ptype. b on a.parm=b.parm;
                %end;
        quit;

        data out.agg&miss_n._&clst._&type._&ptype&m.&mt.&suffix.;
                set agg&miss_n._&clst._&type._&ptype&m.&mt.&suffix.;
                /*calculate statistics to summarize*/
                inci=(uppercl>=true & lowercl<=true);
                bias=estimate-true;
                relbias=bias/true;
                /*PROBT*/
                rejecth0=(abs(z)>quantile('NORMAL',.975));
                *indicator that H0 rejected (i.e., |t|>1.96);
        run;

        proc means data=out.agg&miss_n._&clst._&type._&ptype&m.&mt.&suffix.
                noprint nway;
                class parm;
                var true estimate bias relbias stderr inci rejecth0;
                output out=output_1 mean(true estimate bias relbias stderr inci
                        rejecth0)=true estimate empbias relbias estse coverage
                        prejecth0 std(estimate)=empse;
        run;

        data out.sum&miss_n._&clst._&type._&ptype&m.&mt.&suffix.;
                set output_1;
                relse=estse/empse-1;
        run;

        ods rtf
                file="&homepath./output/Marg_&miss_n._&clst._&type._&ptype.&m.&mt.&suffix..rtf"
                style=journal bodytitle;

        proc print data=out.sum&miss_n._&clst._&type._&ptype&m.&mt.&suffix.
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

%mend combresSAS;

title 'Marginal Model';

%let ptype=ind;

title2 '(3) Weighted';
%combresSAS(model=, clst=hhid, type=ind, ptype=&ptype., m=_3wts, mt=_mar,
        miss_n=p);
