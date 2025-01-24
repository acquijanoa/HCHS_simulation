### Generate Populations for Simulation Study (based on plan from 03/23/17) ###

## interaction with time ##
# A = 1: Original interaction; A = 2: reduced interaction; A = 3: No interaction

## cluster effect ##
# B = 1: medium BG correlation; B = 2: large BG correlation; B = 3 small BG correlation

## time standalone effect ##
# C = 1: Large X6 effect; C = 2: Small X6 effect

## additional interaction ##
# D = 1: x17*age has interaction; D = 2 no interaction

library(tidyverse)
set.seed(123)

work_dir <- ("/work/users/b/e/beibo/v3gee/")  # set working directory
A = 1
B = 3
C = 1
D = 1


# Adjust conditions based on A
if(A == 1){
  int_coef <- c(1.55, -1.26, 1.58, 0.43,0)
  bin_int_coef <- c(0.02, -0.12, -0.24, 0.128, 0)
} else if(A == 2){
  int_coef <- c(1.55, -0.26, 1.58, 0.2, 0)
  bin_int_coef <- c(0.02, -0.12, -0.24, 0.128, 0)
} else if(A == 3){
  int_coef <- c(0, 0, 0, 0, 0)
  bin_int_coef <- c(0, 0, 0, 0, 0)
}

# Adjust conditions based on B
if(B == 1){
  var_list <- list(bgvar=25,
                   hhvar=30,
                   subvar=60,
                   evar=10)
} else if(B == 2){
  var_list <- list(bgvar=50,
                   hhvar=55,
                   subvar=60,
                   evar=10)
} else if(B == 3){
  var_list <- list(bgvar=6,
                   hhvar=30,
                   subvar=60,
                   evar=10)
}

# Adjust conditions based on C
if(C == 1){
  x6_coef <- 3.17
  bin_x6_coef <- 0.32
} else if(C == 2){
  x6_coef <- 1.12
  bin_x6_coef <- 0.32
}

if(D == 1){
  x17_age_coef <- 2.5
  bin_x17_age_coef <- -0.39
} else if(D == 2){
  x17_age_coef <- 0
  bin_x17_age_coef <- 0
}



####### generate population (design variables) #######

Nbg.strat=rep(c(58,21,130,167),times=2)         # number of BGs within each stratum
# Number of BGs in each stratum: 1: 58, 2: 21, 3: 130, 4: 167, 5: 58, 6: 21, 7: 130, 8: 167
Nbg=sum(Nbg.strat)
# bg.size.temp=1+round(rexp(Nbg,1/450))    # at least 1 HH per BG, mean number of HHs/BG=451 -- this is number of ALL HHs in each BG (including non-eligible HHs)
# Define the range
min_size <- 600
max_size <- 3000
# Adjust the rate parameter based on the desired mean size. 
# We'll use the midpoint of the desired range as the mean size.
mean_size <- (min_size + max_size) / 2
rate <- 1 / mean_size
# Generate the sizes
bg.size.temp <- round(rexp(Nbg, rate))
# Check and adjust any values outside the range
for (i in 1:Nbg) {
  while (bg.size.temp[i] < min_size || bg.size.temp[i] > max_size) {
    bg.size.temp[i] <- round(rexp(1, rate))
  }
}


hisp.prop=rep(c(.2,.2125,.2975,.2975),times=2)  # proportion of HHs within each stratum with Hispanic surname & in target population
other.prop=rep(c(.15,.225,.26,.2925),times=2)   # proportion of HHs within each stratum with other surname & in target population

# Number of household with Hispanic surname
num.hisp.strat=round(c(bg.size.temp[1:Nbg.strat[1]]*hisp.prop[1],bg.size.temp[(Nbg.strat[1]+1):sum(Nbg.strat[1:2])]*hisp.prop[2],bg.size.temp[(sum(Nbg.strat[1:2])+1):sum(Nbg.strat[1:3])]*hisp.prop[3],bg.size.temp[(sum(Nbg.strat[1:3])+1):sum(Nbg.strat[1:4])]*hisp.prop[4],
                       bg.size.temp[(sum(Nbg.strat[1:4])+1):sum(Nbg.strat[1:5])]*hisp.prop[5],bg.size.temp[(sum(Nbg.strat[1:5])+1):sum(Nbg.strat[1:6])]*hisp.prop[6],bg.size.temp[(sum(Nbg.strat[1:6])+1):sum(Nbg.strat[1:7])]*hisp.prop[7],bg.size.temp[(sum(Nbg.strat[1:7])+1):sum(Nbg.strat[1:8])]*hisp.prop[8])) # number of eligible HHs with Hispanic surname in each BG
# Number of household with other surname
num.other.strat=round(c(bg.size.temp[1:Nbg.strat[1]]*other.prop[1],bg.size.temp[(Nbg.strat[1]+1):sum(Nbg.strat[1:2])]*other.prop[2],bg.size.temp[(sum(Nbg.strat[1:2])+1):sum(Nbg.strat[1:3])]*other.prop[3],bg.size.temp[(sum(Nbg.strat[1:3])+1):sum(Nbg.strat[1:4])]*other.prop[4],
                        bg.size.temp[(sum(Nbg.strat[1:4])+1):sum(Nbg.strat[1:5])]*other.prop[5],bg.size.temp[(sum(Nbg.strat[1:5])+1):sum(Nbg.strat[1:6])]*other.prop[6],bg.size.temp[(sum(Nbg.strat[1:6])+1):sum(Nbg.strat[1:7])]*other.prop[7],bg.size.temp[(sum(Nbg.strat[1:7])+1):sum(Nbg.strat[1:8])]*other.prop[8])) # number of eligible HHs with other surname in each BG


bg.size=num.hisp.strat+num.other.strat  # number of eligible HHs in each BG
Nhh=sum(bg.size)                        # number of HHs in target population
hh.size=1+rpois(Nhh,1)                  # at least 1 subject per HH, mean number of subjects/HH=2
N=sum(hh.size)                          # number of subjects in target population

A=matrix(rep(NA,times=max(bg.size)*length(bg.size)),nrow=max(bg.size),ncol=length(bg.size))
for (i in 1:length(bg.size)){
  A[,i]=c(rep(TRUE,times=num.hisp.strat[i]),rep(FALSE,times=num.other.strat[i]),rep(NA,times=max(bg.size)-bg.size[i]))    # create matrix A with each column corresponding to a BG (containing 1's for each Hispanic HH followed by 0's for each other HH)
}
hisp.strat.hh=na.omit(c(A))   #indicator for Hispanic surname (one entry per HH)

BGid=rep(rep(rep(1:Nbg, times=bg.size), times=hh.size), times=3)  # all ID's unique (e.g., subid=k only for one subject within one HH)
hhid=rep(rep(1:Nhh, times=hh.size), times=3)
subid=rep(1:N, times=3)
v.num=rep(c(1,2,3),each=N)
strat=1+(BGid>Nbg.strat[1])+(BGid>sum(Nbg.strat[1:2]))+(BGid>sum(Nbg.strat[1:3]))+(BGid>sum(Nbg.strat[1:4]))+(BGid>sum(Nbg.strat[1:5]))+(BGid>sum(Nbg.strat[1:6]))+(BGid>sum(Nbg.strat[1:7]))
hisp.strat=hisp.strat.hh[hhid]

age.inrange=FALSE
age=rep(0,N)            #create age vector with all 0's (so all values will be replaced in first iteration of while loop)
while(!age.inrange){
  age[age<18|age>74]=rnorm(length(age[age<18|age>74]),40,15)    #only generate new values for age to replace out of range values
  #check for success
  age.inrange=(sum(age>=18 & age<=74)==N)   #age.inrange=TRUE if all N subjects have 18<=age<=74 (which would break the loop)
}

#! How to ensure increasing age?
age.base=rep(age,times=3)   #create baseline age (which is the same at V1 and V2 and V3)
age.strat=(age.base>=45)    #indicator for older (45-74 years) stratum


######### generate population outcome and covariates #########

age.strat.unq=age.strat[v.num==1]
hisp.strat.unq=hisp.strat[v.num==1]
strat.unq=strat[v.num==1]

### generate covariates ###
x0=rep(1,N)
x1=rbinom(N,1,.5)
x2=rbinom(N,1,.67)
x3=rbinom(N,1,.2)
x4=rbinom(N,1,.2)

x6.inrange=FALSE
x6=rep(-1,N)            #create x6 vector with all -1's (so all values will be replaced in first iteration of while loop)
while(!x6.inrange){
  x6[x6<3|x6>9]=rnorm(length(x6[x6<3|x6>9]),6,.5)    #only generate new values for x6 to replace out of range values
  #check for success
  x6.inrange=(sum(x6>=3 & x6<=9)==N)   #x6.inrange=TRUE if all N subjects have 3<=x6<=9 (which would break the loop)
}

x8.inrange=FALSE
x8=rep(-1,N)            #create x8 vector with all -1's (so all values will be replaced in first iteration of while loop)
while(!x8.inrange){
  x8[x8<0]=rnorm(length(x8[x8<0]),4.5,sqrt(.17))    #only generate new values for x8 to replace out of range values
  #check for success
  x8.inrange=(sum(x8>=0)==N)   #x8.inrange=TRUE if all N subjects have x8>=0 (which would break the loop)
}

x12=rbinom(N,1,.5)
x13=rbinom(N,1,.3)
x14=rbinom(N,1,.25)

x15.inrange=FALSE
x15=rep(25,N)            #create x15 vector with all 25's (so all values will be replaced in first iteration of while loop)
while(!x15.inrange){
  x15[x15<0|x15>24]=rnorm(length(x15[x15<0|x15>24]),2,sqrt(6.5))    #only generate new values for x15 to replace out of range values
  #check for success
  x15.inrange=(sum(x15>=0 & x15<=24)==N)   #x15.inrange=TRUE if all N subjects have 0<=x5<=24 (which would break the loop)
}

#generate x16 (time b/t V2 and V3)
x16.inrange=FALSE
x16=rep(-1,N)            #create x16 vector with all -1's (so all values will be replaced in first iteration of while loop)
while(!x16.inrange){
  x16[x16<3|x16>9]=rnorm(length(x16[x16<3|x16>9]),5.2,.5)    #only generate new values for x16 to replace out of range values
  #check for success
  x16.inrange=(sum(x16>=3 & x16<=9)==N)   #x16.inrange=TRUE if all N subjects have 3<=x16<=9 (which would break the loop)
}

x17=rnorm(N,4.5+1*age.strat.unq+.1*(strat.unq %in% c(1,5))+.2*(strat.unq %in% c(2,6))+.3*(strat.unq %in% c(3,7))-1*hisp.strat.unq,.1)
x18=rbinom(N,1,exp(1.5-.06*age+1*(strat.unq %in% c(1,5))+.5*(strat.unq %in% c(2,6))+1*(strat.unq %in% c(3,7))-1*hisp.strat.unq)/(1+exp(1.5-.06*age+1*(strat.unq %in% c(1,5))+.5*(strat.unq %in% c(2,6))+1*(strat.unq %in% c(3,7))-1*hisp.strat.unq)))

x.v1=cbind(x0,x1,x2,x3,x4,rep(0,N),x8,x12,x13,x14,x15,x17,x18)
x.v2=cbind(x0,x1,x2,x3,x4,x6,x8,x12,x13,x14,x15,x17,x18)
x.v3=cbind(x0,x1,x2,x3,x4,x16+x6,x8,x12,x13,x14,x15,x17,x18)



x=rbind(x.v1,x.v2,x.v3)   #V1 V2 and V3 observations are stacked
colnames(x)=c("x0","x1","x2","x3","x4","x6","x8","x12","x13","x14","x15","x17","x18")
x=data.frame(x)


### generate continuous outcomes ###
gen.y=function(beta, xmat, beta.v1_time, time, bgvar, hhvar, subvar, evar){
  error=rnorm(N*3,0,sqrt(evar))
  bg=rep(rep(rep(rnorm(Nbg,0,sqrt(bgvar)),times=bg.size),times=hh.size),times=3)
  hh=rep(rep(rnorm(Nhh,0,sqrt(hhvar)),times=hh.size),times=3)
  sub=rep(rnorm(N,0,sqrt(subvar)),times=3)
  
  y=
    (xmat%*%beta)+    # (main effect + interaction)
    ((xmat*time)%*%beta.v1_time)+  # x6 interaction with (main effect + interaction) 
    bg+hh+sub+error       # error;
  
  return(y)
}

##BMI
xbmi=matrix(c(x$x0,x$x1,x$x2,x$x3,x$x4,x$x15,age.base,
              (strat%in%c(1,5)),(strat%in%c(2,6)),(strat%in%c(3,7)),
              x$x2*(strat%in%c(1,5)),x$x2*(strat%in%c(2,6)),x$x2*(strat%in%c(3,7)),
              age.strat*x$x15), ncol=14, nrow=dim(x)[[1]])
y.bmi=gen.y(beta=c(30,-1,-0.7,-1, 2,-0.8,0.03,
                   0.4, -0.04,-1.5,1.7,0.7,-0.6,
                   1.8),
            xmat=xbmi,
            # beta.v1_time=c(1.3, 0.67, 0, -1.25, -1.0, -0.15, 0, 
            #                1.17, 0, 0.17,0.17,0,-0.05,
            #                0.22),
            beta.v1_time=c(1.3, 0.67, 0, -1.25, -1.0, -0.15, 0, 
                           c(1.17, 0, 0.17,0.17,0,-0.05)*0,
                           0.22),
            time=x$x6,
            bgvar=0.2,
            hhvar=7.3,
            subvar=10,
            evar=21.5)

##EGFR
# if(pop_id <= 12|pop_id == 14){
  xgfr=matrix(c(
    
    x$x0,x$x12,x$x18,x$x14,x$x17,age.base, 
    
    (strat%in%c(1,5)),(strat%in%c(2,6)),(strat%in%c(3,7)),
                
    x$x12*(strat%in%c(1,5)),x$x12*(strat%in%c(2,6)),x$x12*(strat%in%c(3,7)), 
    
    x$x17*age.strat),
    
    ncol=13,nrow=dim(x)[[1]])
  y.gfr=gen.y(beta=c(c(150, -0.17, -2.95, 4.87, -4, -0.85, 
                       2.37, -6.38, -2.58),
                     -1,1.2,.2,
                     x17_age_coef
                      # if(pop_id == 14){
                      #   c(-1,1.2,.2,2.5)
                      # }else{
                      #   c(0, 0, 0,0)
                      # }
  )
  ,
  xmat=xgfr,
  # beta.v1_time=c(3.17,
        # 1.55,-1.26,1.58,0.43,0,
        # -1.15,1.75,-0.53, -0.52, 0.28, 0.12, 
        # -0.27),
  
  # parameters for x6 * (main + interaction) 
  # x6_coef: effect on x6 
  # int_coef: effect on x6*others
  beta.v1_time=c(x6_coef,
                 int_coef,
                 c(-1.15,1.75,-0.53, 
                   -0.52, 0.28, 0.12,
                   -0.27)*0
                 # ifelse(pop_id == 14, -0.27, 0)  # if pop_id is 14 then set to -0.27
  ),
  time=x$x6,
  bgvar=var_list$bgvar,
  hhvar=var_list$hhvar,
  subvar=var_list$subvar,
  evar=var_list$evar)


### Generate Binary Outcomes ###
gen.y.bin=function(beta, xmat, beta.v1_time, time, bgvar, hhvar, subvar, evar){
  error=rnorm(N*3,0,sqrt(evar))
  bg=rep(rep(rep(rnorm(Nbg,0,sqrt(bgvar)),times=bg.size),times=hh.size),times=3)
  hh=rep(rep(rnorm(Nhh,0,sqrt(hhvar)),times=hh.size),times=3)
  sub=rep(rnorm(N,0,sqrt(subvar)),times=3)
  
  p <- 1/(1+exp(-xmat%*%beta-(xmat*time) %*% beta.v1_time -bg-hh-sub-error))
  y=rbinom(length(p), 1, p)
  return(y)
}

xgfr=matrix(c(x$x0,
              x$x12,x$x18,x$x14,x$x17,
              age.base,
              (strat%in%c(1,5)),(strat%in%c(2,6)),(strat%in%c(3,7)),
              x$x12*(strat%in%c(1,5)),x$x12*(strat%in%c(2,6)),x$x12*(strat%in%c(3,7)),
              x$x17*age.strat),
            ncol=13,nrow=dim(x)[[1]])

y.gfr.bin=gen.y.bin(beta=c(-7.74, 
                           0.01, 0.45, -0.76, 0.62, 
                           0.13, 
                           -0.34, 1, 0.39, 
                           0.16, -0.12, -0.04, 
                           bin_x17_age_coef
                           ),
                    xmat=xgfr,
                    beta.v1_time=c(bin_x6_coef, 
                                   bin_int_coef,
                                   c(-1.15,1.75,-0.53, 
                                     -0.52, 0.28, 0.12,
                                     -0.13)*0 
                                   ),
                    time=as.numeric(scale(x$x6)),
                    bgvar=0.2,
                    hhvar=0.3,
                    subvar=0.5,
                    evar=0.25)



pop=data.frame(strat,BGid,hhid,subid,v.num,hisp.strat,age.base,age.strat,x,y.bmi,y.gfr, y.gfr.bin)
# pop=pop[order(pop$subid,pop$v.num),]

names(pop)[names(pop) %in% 
             c('v.num','hisp.strat','age.base','age.strat','y.bmi','y.gfr', 'y.gfr.bin')] = c('v_num','hisp_strat','age_base','age_strat','y_bmi','y_gfr', 'y_bin_gfr')



dat__ <- pop %>% arrange(subid, v_num)



write.csv(dat__,paste0(work_dir,
                       "population_3visits_Dec2024.csv"), 
          row.names=FALSE)
