cd "C:\AAA\PYAN\CLHLS\CLHLS data and codebook\2017 2018_cross sectional_longitudinal data survey data"
use clhls_2014_2018_longitudinal,clear
*************************codebook on death variables*************************
*d18vyear: validated year of death*/
* . : missing*/
*d18vmonth:validated month of death*/
* . : missing*/
*d18vday: validated day of death*/
* . : missing*/
*dth14_18: status of survival, death, or lost to follow-up from 2014 to 2018 wave: -9:lost to follow-up in the 2018 survey; 0:surviving at the 2018 survey; 1: died before the 2018 survey */

rename dth14_18 dth18

global waves "18"                                                            //******need to be changed
global year1 "2014 2015 2017 2018 2019"
global year2 "2016"
global months "4 6 9 11"
global wavein "in14 in18"
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
use wave18,clear                                                                //******need to be changed
/*In wave14, all is missing in d18vyear/month/day when dth18=-9/0. 
There is no logical mistakes between the 4 vars.
There are 47 deceased persons without d18year/month/day. */

erase work1.dta
erase wave18.dta

********************************Data cleaning**********************************
use work,clear
*Extract the new added data at 2008 survey*
gen int id_year=mod(id,100)  //id_year=14 were the newly added ones

/*change all . to 99 for month&day, . to 9999 for year*/
foreach a of global waves{
recode d`a'vday(.=99) 
recode d`a'vmonth(.=99)
recode d`a'vyear(.=9999)
}

****calculate the mid-point between the last interview date of the previous wave and the first interview date of the next wave
gen in14=mdy(monthin,dayin,yearin)                                              //******need to be changed
gen in18=mdy(monthin_18,dayin_18,yearin_18)

egen maxin14=max(in14)
egen minin18=min(in18)
gen mid_1418=(maxin14+minin18)/2
gen midyear=year(mid_1418)
gen midmonth=month(mid_1418)
gen midday=day(mid_1418)

recode d18vday (99=15) if d18vmonth!=99 & d18vyear!=9999 & dth18==1 //0 changes
recode d18vmonth (99=7) if d18vday!=99 & d18vyear!=9999 & dth18==1  //0 changes
replace d18vday=midday if d18vday==99 & dth18==1   //47 changes
replace d18vmonth=midmonth if d18vmonth==99 & dth18==1 //47 changes
replace d18vyear=midyear if d18vyear==9999 & dth18==1 //47 changes

***** modify input mistakes
* change day 29/max to 28 of Feb for years 2014-19; 
* change day 31 to 30 for months 4 6 9 11
foreach year of global year1{
 recode d18vday (29/max=28) if d18vyear==`year' & d18vmonth==2
 }
 foreach year of global year2{
 recode d18vday (30/max=29) if d18vyear==`year' & d18vmonth==2
 }
 foreach month of global months{
 recode d18vday (31=30) if d18vmonth==`month'
 }
 
 **********************************calc survival time************************
* gen survival_bas14_18, means the years from 2014 to death or censored
* For those who died during the study, survival_bas14_18=date of death-in14
* For those who were lost in the study, survival_bas14_18=the middle time of the wave-in14
* For those who were still alive at the end of the study,survival_bas14_18=interview date in the last wave-in14

* gen lostdate, means the lost date for those lost in the survey, and equals to the mid-point of last day of the previous interview and the first day of the next one
gen lostdate=.
gen survival_bas14_18=. 

gen dthdate=mdy(d18vmonth,d18vday,d18vyear)
replace lostdate=mid_1418 if dth18==-9
replace survival_bas14_18=(dthdate-in14)/365.25
gen censor14_18=0
replace censor14_18=1 if survival_bas14_18 !=.  //generate censor14_18=1 if die, censor14_18=0 if survived until end of the wave or lost to follow
replace survival_bas14_18=(lostdate-in14)/365.25 if lostdate !=.
replace survival_bas14_18=(in18-in14)/365.25 if dth18==0
gen lost14_18=1
replace lost14_18=. if lostdate ==.  

**************replace the survival time to 0 for those whose survival was negative
sum survival_bas14_18 //didn't replace the negative figures with 0, because the true value will be used to calculate the survival time to 2018 wave

* gen survival_bth14_18,means the years from birth to death or censor14_18ed
gen survival_bth14_18=survival_bas14_18+trueage
                                                               
erase work.dta
macro drop _all

********************************************************************************
**************************extract for baseline characteristics******************
* id trueage  

* trueage: age
* residenc: 1 urban 2 town 3 rural
* a1: 1 "male" 2 "female"
* a2: ethinic,1"han" 2-8:hui zhuang yao korea man mongolia others, ."missing"
* a51: co-residence, 1"with household member(s)", 2 "alone", 3 "in an institution",8 "don't know"
* f1: years of schooling, 0-20, 88"don't know" 99"missing"
* f2: main occupation before age 60, -1 "not applicable"; 0"professional and technical personnel", 1"governmental, institutional or managerial personnel", 2"commercial or service or industrial worker"; 3"self employed"; 4"agriculture,forestry,animal husbandry or fishery worker"; 5"houseworker", , 6"military personnel", 7"never worked", 8"others", 9 ."missing"
* f41: current marital status,1 currently married and living with spouse  2 married but not living with spouse 3 divorced 4 widowed 5 never married 8 don't know 9 . missing 
gen gender=.
replace gender=1 if a1==1
replace gender=0 if a1==2
label define gender_lb 1"male" 0 "female"
label value gender gender_lb
gen ethnicity=.
replace ethnicity=1 if a2==1
replace ethnicity=0 if a2>1 & a2<9
label define ethnicity_lb 1"han" 0 "the minority" 
label value ethnicity ethnicity_lb
gen coresidence=a51
replace coresidence=. if a51==9
label define coresidence_lb 1 "with household members" 2"alone" 3"In an institution" 
label value coresidence coresidence_lb
gen edu=.
replace edu=f1
replace edu=. if f1==99|f1==88|f1==.
gen occupation=. 
replace occupation=1 if f2>1 & f2<9
replace occupation=0 if f2==0 |f2==1
replace occupation=3 if f2==7
label define occupation_lb 1"manule" 0"non-mannual" 3 "never worked" 
label value occupation occupation_lb
gen marital=.
replace marital=1 if f41==1
replace marital=2 if f41==2|f41==3|f41==5
replace marital=3 if f41==4
label define marital_lb 1 "currently married and living with spouse" 2"separted, divorced or never married" 3"widowed" 
label value marital marital_lb
gen residence=1
replace residence=2 if residenc==3
label define residence_lb 1 "urban (city or town)" 2"rural"
label value residence residence_lb
save "C:\AAA\PYAN\CLHLS\CLHLS data and codebook\Longitudinal data_with survival time_STATA version\dat14_18",replace

******************************** Extend survival_bas to 2018 wave using dat14_18 ***********************************
cd "C:\AAA\PYAN\CLHLS\CLHLS data and codebook\Longitudinal data_with survival time_STATA version"
clear
set maxvar 30000

macro drop _all
global waves "98 00 05 11"  
foreach v of global waves{
use dat`v'_14,clear
merge 1:1 id using "dat14_18",keepus(id survival_bas14_18 survival_bth14_18 censor14_18 lost14_18) nolabel //47, 96, 1110, 821 merged for dat98/00/05/11_14
gen survival_bas`v'_18=survival_bas
replace survival_bas`v'_18=survival_bas+survival_bas14_18  if censor==0 & _merge==3
gen survival_bth`v'_18=survival_bth
replace survival_bth`v'_18=survival_bth+survival_bas14_18  if censor==0 & _merge==3
gen censor`v'_18=censor
replace censor`v'_18=censor14_18 if _merge==3  //23, 47, 282, 290 died between 2014 and 2018
gen lost`v'_18=lost
replace lost`v'_18=lost14_18 if _merge==3 //14, 29, 288, 87 lost between 2014 and 2018
drop if _merge==2
drop _merge
save dat`v'_18,replace
}

use dat02_14,clear
merge 1:1 id using "dat14_18",keepus(id survival_bas14_18 survival_bth14_18 censor14_18 lost14_18 d18vyear d18vmonth d18vday) nolabel  //1539 merged
gen survival_bas02_18=survival_bas
replace survival_bas02_18=survival_bas+survival_bas14_18  if censor==0 & _merge==3  //1538 replaced, one died in 2011.6.30, but was recorded as missing in d18vyear/month/day, so no need to be changed
preserve
 keep if censor==1 & _merge==3
 display id dthyear dthmonth dthday survival_bas lost censor d18vyear d18vmonth d18vday survival_bas14_18
restore
gen survival_bth02_18=survival_bth
replace survival_bth02_18=survival_bth+survival_bas14_18  if censor==0 & _merge==3
gen censor02_18=censor
replace censor02_18=censor14_18 if _merge==3 & id !=45454002  //427 died between 2014 and 2018
gen lost02_18=lost
replace lost02_18=lost14_18 if _merge==3 & id !=45454002  //351 lost between 2014 and 2018
drop if _merge==2
drop _merge
save dat02_18,replace

use dat08_14,clear
merge 1:1 id using "dat14_18",keepus(id survival_bas14_18 survival_bth14_18 censor14_18 lost14_18 d18vyear d18vmonth d18vday) nolabel  //2453 merged
gen survival_bas08_18=survival_bas
replace survival_bas08_18=survival_bas+survival_bas14_18  if censor==0 & _merge==3  //2452 replaced, one died on/three died before the interview date in 2014, but all were recorded as alive in dat08_14, so donot need special change ('replace survival_bas08_18=survival_bas+survival_bas14_18' works)
gen survival_bth08_18=survival_bth
replace survival_bth08_18=survival_bth+survival_bas14_18  if censor==0 & _merge==3
gen censor08_18=censor
replace censor08_18=censor14_18 if _merge==3  //814 died between 2014 and 2018
gen lost08_18=lost
replace lost08_18=lost14_18 if _merge==3  //530 lost between 2014 and 2018
drop if _merge==2
drop _merge
save dat08_18,replace

use dat14_18,clear
save dat14_18_7192

use dat14_18,clear
keep if id_year==14
save dat14_18_1125




