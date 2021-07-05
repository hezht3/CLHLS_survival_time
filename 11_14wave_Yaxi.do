clear
cd "C:\AAA\PYAN\CLHLS\Longitudinal data"
use "C:\AAA\PYAN\CLHLS\Longitudinal data\2011_2014_longitudinal_dataset_released_version1", clear
*Extract the new added data at 2011 survey*
gen int id_year=mod(id,100)
keep if id_year==12 //1340 obs

************************codebook on death variables*************************
*d14vyear: validated year of death*/
* . : missing*/
*d14vmonth:validated month of death*/
* . : missing*/
*d14vday: validated day of death*/
* . 99: missing*/
*dth11_14: status of survival, death, or lost to follow-up from 2000-2002/2002-2005/2005-2008/2008-2011/2011-2014 waves*/
* dth**_##: -9:lost to follow-up at the ## survey; 0:surviving at the ## survey; 1: died before the ## survey */

*****************************create work.dta, which has changed the death status according results above, and renanme dth**_##***********
rename dth11_14 dth14

global waves "14"                                                            //******need to be changed
global year1 "2011 2013 2014"
global year2 "2012"
global months "4 6 9 11"
global wavein "in11 in14"
save work,replace

*********check whether there are logical mistakes between d*vyear d*vmonth d*vday dth**_##
foreach i of global waves{
recode d`i'vday(. 88=99) 
recode d`i'vmonth(. 88=99)
recode d`i'vyear(. 88 9999=99)  //no 88 for all the 4 vars
replace d`i'vyear=1 if d`i'vyear>1997 & d`i'vyear<2020
replace d`i'vmonth=1 if d`i'vmonth>0 & d`i'vmonth<13
replace d`i'vday=1 if d`i'vday>0 & d`i'vday<32
bys d`i'vyear:gen fre`i'_year=_N
bys d`i'vmonth:gen fre`i'_month=_N
bys d`i'vday:gen fre`i'_day=_N
bys dth`i':gen fre`i'_dth=_N
}
label drop _all
save work1,replace
foreach i of global waves{
keep d`i'vyear d`i'vmonth d`i'vday dth`i' fre`i'_year fre`i'_month fre`i'_day fre`i'_dth 
duplicates drop d`i'vyear d`i'vmonth d`i'vday dth`i',force 
save wave`i',replace
use work1,clear
}
use wave14,clear                                                                //******need to be changed
                                                             
/* The results show that, in wave0-wave11, -9, -8, 0/-7(alive) have completely the same freq, 
all missing values in d*vyear/month/day occur only when dth*=1(died). Only in wave14, all is missing in d14vyear/month/day when dth14=-9/-8/0. 
There is no logical mistakes between the 4 vars.*/

*********tabulate the lost,died and alive number for each wave
use work1,clear
foreach i of global waves{
tabulate dth`i' if dth`i' !=-8
} 

foreach i of global waves{
erase wave`i'.dta
}
erase work1.dta 

********************************Data cleaning**********************************
use work,clear
/*change all . to 99 for month&day, . to 9999 for year*/
foreach a of global waves{
recode d`a'vday(.=99) 
recode d`a'vmonth(.=99)
recode d`a'vyear(.=9999)
}

****calculate the mid-point between the last interview date of the previous wave and the first interview date of the next wave
capture noisily gen in98=mdy(month98,date98,year9899)                            
capture noisily gen in0=mdy(month_0,day_0,2000)
capture noisily gen in2=mdy(month02,day02,2002)
capture noisily gen in5=mdy(monthin,dayin,2005)                                 
capture noisily gen in8=mdy(monthin,dayin,yearin)                               
gen in11=mdy(monthin,dayin,yearin)                                              //******need to be changed
gen in14=mdy(monthin_14,dayin_14,yearin_14)                                    
forv i=1/1{                                                                       //******need to be changed                                               
   local wavein2=word("$wavein",`i')
         egen min_`wavein2'=min(`wavein2')
         egen max_`wavein2'=max(`wavein2')
   local j=`i'+1
   local wavein3=word("$wavein",`j')
         egen min_`wavein3'=min(`wavein3')
         egen max_`wavein3'=max(`wavein3')
   gen mid_`wavein2'_`wavein3'=(max_`wavein2'+min_`wavein3')/2
   gen midyear_`wavein2'_`wavein3'=year(mid_`wavein2'_`wavein3')
   gen midmonth_`wavein2'_`wavein3'=month(mid_`wavein2'_`wavein3')
   gen midday_`wavein2'_`wavein3'=day(mid_`wavein2'_`wavein3')
drop min_`wavein3' max_`wavein3'
}
**** Replacement of death missing value
local j=1
foreach i of global waves {       
        recode d`i'vday (99=15) if d`i'vmonth!=99 & d`i'vyear!=9999 & dth`i'==1 
        recode d`i'vmonth (99=7) if d`i'vday!=99 & d`i'vyear!=9999 & dth`i'==1 
    local inid=word("$wavein",`j')
        replace d`i'vday=midday_`inid'_in`i' if d`i'vday==99 & dth`i'==1
        replace d`i'vmonth=midmonth_`inid'_in`i' if d`i'vmonth==99 & dth`i'==1
        replace d`i'vyear=midyear_`inid'_in`i' if d`i'vyear==9999 & dth`i'==1
    local j=`j'+1
}

***** modify input mistakes
* change day 29/max to 28 of Feb for years 99,01,02,03,05,06,07,09,10,11,13, 14; 
* change day 30/max to 29 for years 00,04,08,12;
* change day 31 to 30 for months 4 6 9 11
foreach i of global waves{
 foreach year of global year1{
 recode d`i'vday (29/max=28) if d`i'vyear==`year' & d`i'vmonth==2
 }
 foreach year of global year2{
 recode d`i'vday (30/max=29) if d`i'vyear==`year' & d`i'vmonth==2
 }
 foreach month of global months{
 recode d`i'vday (31=30) if d`i'vmonth==`month'
 }
}

*******************************calculating survival time, censor and lost to follow-up********************
****set interview baseline
**codebook on interview date variables
* dayin: day of interview of the 2011 survey; 1~31
* monthin: month of the interview of the 2011 survey; 5~9
* yearin:2012
**Replacement of interview date missing value 
* a. if only the interview day is missing, then the day is assumed to be 15th
* b. if both month and day are missing, or only the month is missing, the month/day is considered within the interview year, and is assumed to be that of the mid-point in the current interview year
* c. no interview year is missing.                                 
gen interview_baseline=mdy(monthin,dayin,yearin)                                  //******need to be changed
                             
**********************************calc survival time************************
* gen survival_bas,means the years from baseline to death or censored
* For those who died during the study,survival_bas=date of death-interview_baseline
* For those who were lost in the study, survival_bas=the middle time of the wave-interview_baseline
* For those who were still alive at the end of the study,survival_bas=interview date in the last wave-interview_baseline

* generate dthyear/month/day, means the exact death year/month/day of those who died during the whole period(2005-2014)
* gen lostdate, means the lost date for those lost in the survey, and equals to the mid-point of last day of the previous interview and the first day of the next one
gen dthyear=.
gen dthmonth=.
gen dthday=.
gen lostdate=.
gen survival_bas=. 
local j=1
  foreach i of global waves{
       replace dthyear=d`i'vyear if d`i'vyear>0 & d`i'vyear<2020
       replace dthmonth=d`i'vmonth if d`i'vmonth>0 & d`i'vmonth<13
       replace dthday=d`i'vday if d`i'vday>0 & d`i'vday<32
   local inid=word("$wavein",`j')
       replace lostdate=mdy(midmonth_`inid'_in`i',midday_`inid'_in`i',midyear_`inid'_in`i') if dth`i'==-9
   local j=`j'+1
  }  
gen dthdate=mdy(dthmonth,dthday,dthyear)
replace survival_bas=(dthdate-interview_baseline)/365.25
gen censor=0
replace censor=1 if survival_bas !=.  //generate censor=1 if die, censor=0 if survived until end of the wave or lost to follow
replace survival_bas=(lostdate-interview_baseline)/365.25 if lostdate !=.
gen interview2014=mdy(monthin_14,dayin_14,yearin_14) if dth14==0 
replace survival_bas=(interview2014-interview_baseline)/365.25 if interview2014 !=.
gen lost=1
replace lost=. if lostdate ==.  

**************replace the survival time to 0 for those whose survival was negative
sum survival_bas 
replace survival_bas=0 if survival_bas<0  
* gen survival_bth,means the years from birth to death or censored
gen survival_bth=survival_bas+trueage                                                               
erase work.dta
macro drop _all
********************************************************************************
**************************extract for baseline characteristics******************
* keep id trueage  

* trueage: age
* residenc: 1 urban (city and town) 2 rural
* a1: 1 "male" 2 "female"
* a2: ethinic,1"han" 2-8:hui zhuang yao korea man mongolia others, 9"missing"
* a51: co-residence, 1"with household member(s)", 2 "alone", 3 "in an institution",9 "missing"
* f1: years of schooling, 0-26, 88"don't know" 99"missing"
* f2: main occupation before age 60, 0"professional and technical personnel", 1"governmental, institutional or managerial personnel", 2"agriculture,forest,animal husbandry", 3"fishery worker", 4"industrial worker", 5"commercial or service worker", 6"military personnel", 7"housework", 8"others", 9"missing"
* f41: current marital status,1 currently married and living with spouse  2 separated 3 divorced 4 widowed 5 never married 9 missing
gen gender=9
replace gender=1 if a1==1
replace gender=0 if a1==2
label define gender_lb 1"male" 0 "female" 9"missing"
label value gender male_lb
gen ethnicity=9
replace ethnicity=1 if a2==1
replace ethnicity=0 if a2>1 & a2<9
label define ethnicity_lb 1"han" 0 "the minority" 9"missing"
label value ethnicity ethnicity_lb
gen coresidence=a51
label define coresidence_lb 1 "with household members" 2"alone" 3"In an institution" 9"missing"
label value coresidence coresidence_lb
gen edu=.
replace edu=f1
replace edu=99 if f1==99|f1==88|f1==.
label value edu edu
label define edu 99"missing"
gen occupation=. 
replace occupation=1 if f2>1 & f2<9
replace occupation=0 if f2==0 |f2==1
replace occupation=9 if f2==9
label define occupation_lb 1"manule" 0"non-mannual" 9"missing"
label value occupation occupation_lb
gen marital=9
replace marital=1 if f41==1
replace marital=2 if f41==2|f41==3|f41==5
replace marital=3 if f41==4
label define marital_lb 1 "currently married and living with spouse" 2"separted, divorced or never married" 3"widowed" 9"missing"
label value marital marital_lb
gen residence=1
replace residence=2 if residenc==3
label define residence_lb 1 "urban (city or town)" 2"rural"
label value residence residence_lb
save dat11_14                                                                  //******need to be changed



