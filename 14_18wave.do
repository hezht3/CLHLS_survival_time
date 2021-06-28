<<<<<<< HEAD
* Zhengting (Johnathan) He
* June 28th, 2021
* healthy-aging project
* Verify Yaxi's code on generting survival time: 14_18wave.do

// set working directories
global root "F:\Box Sync\Archives2020LLY\Zhengting\Duke Kunshan University Intern (zh133@duke.edu)\4 healthy aging-CLHLS\Group meeting coordination\survival time"
* define path for data sources
global RAW "${root}/raw data"
* define path for output data
global OUT "${root}/out data"
* define path for INTERMEDIATE
global INTER "${root}/inter data"

/*********************************************************************************************************************/
/************************************* I. logical check on death status and date *************************************/
/*********************************************************************************************************************/

/************************************* (1) Extract new added data at current wave *************************************/
use "${RAW}/clhls_2014_2018_longitudinal.dta", clear

/************************************* (2) Check the actual values of death date variables, against the codebook for those variables *************************************/
foreach var in d18vyear d18vmonth d18vday dth14_18 {
    codebook `var'
}
// codebook on death variables

// validated death year
* d18vyear: validated year of death
* . : missing

// validated death month
*d18vmonth:validated month of death*/
* . : missing

// validated death day
*d18vday: validated day of death*/
* . : missing

// survival status
* dth14_18: status of survival, death, or lost to follow-up from 2014 to 2018 wave
* -9: lost to follow-up in the 2018 survey
* 0: surviving at the 2018 survey
* 1: died before the 2018 survey

/************************************* Not applicable for this wave: (3) Check whether there are logical input mistakes between death status for different waves *************************************/
// check whether there are logical mistakes for dth**_##
* If the current death status is -9/0/1, the previous one can only be 0;
* if the current death status is -8, then the previous can only be -8,-9 and 1.
rename dth14_18 dth18

global waves "18"                                                            //******need to be changed
global year1 "2014 2015 2017 2018 2019"
global year2 "2016"
global months "4 6 9 11"
global wavein "in14 in18"
save work, replace
save "${INTER}/work.dta", replace

/************************************* (4) Check whether there are logical input mistakes between death status and the verified death year, month, day *************************************/
// check whether there are logical mistakes between d*vyear d*vmonth d*vday dth**_##
foreach i of global waves {
    // unify missing value to "99"
    recode d`i'vday(. 88=99) 
    recode d`i'vmonth(. 88=99)
    recode d`i'vyear(. 8888 9999=99)  //no 88 for all the 4 vars
    
    replace d`i'vyear = 1 if d`i'vyear > 1997 & d`i'vyear < 2020
    replace d`i'vmonth = 1 if d`i'vmonth > 0 & d`i'vmonth < 13
    replace d`i'vday = 1 if d`i'vday > 0 & d`i'vday < 32
    
    bys d`i'vyear: gen fre`i'_year = _N
    bys d`i'vmonth: gen fre`i'_month = _N
    bys d`i'vday: gen fre`i'_day = _N
    bys dth`i': gen fre`i'_dth = _N
}
label drop _all
save "${INTER}/work1.dta", replace

foreach i of global waves{
    keep d`i'vyear d`i'vmonth d`i'vday dth`i' fre`i'_year fre`i'_month fre`i'_day fre`i'_dth 
    duplicates drop d`i'vyear d`i'vmonth d`i'vday dth`i', force 
    save "${INTER}/wave`i'.dta", replace
    use "${INTER}/work1.dta", clear
}
use "${INTER}/wave18.dta",clear

browse

/* In wave14, all is missing in d18vyear/month/day when dth18=-9/0. 
There is no logical mistakes between the 4 vars.
There are 47 deceased persons without d18year/month/day. */

erase "${INTER}/work1.dta"
erase "${INTER}/wave18.dta"

/********************************************************************************************************************/
/************************************* II. Replacement of NA and input mistakes *************************************/
/********************************************************************************************************************/

use "${INTER}/work.dta", clear
*Extract the new added data at 2008 survey*
gen int id_year=mod(id,100)  //id_year=14 were the newly added ones

/*change all . to 99 for month&day, . to 9999 for year*/
foreach a of global waves{
    recode d`a'vday (. = 99) 
    recode d`a'vmonth (. = 99)
    recode d`a'vyear (. = 9999)
}

****calculate the mid-point between the last interview date of the previous wave and the first interview date of the next wave
gen in14 = mdy(monthin, dayin, yearin)                                              //******need to be changed
gen in18 = mdy(monthin_18, dayin_18, yearin_18)

egen maxin14 = max(in14)
egen minin18 = min(in18)
gen mid_1418 = (maxin14 + minin18)/2
gen midyear = year(mid_1418)
gen midmonth = month(mid_1418)
gen midday = day(mid_1418)

/************************************* (5) Replacement of the missing death date according to Rule 1 *************************************/
* Rule 1:
* For the three variables, year, month, and day:
* a. if only month is missing, the month is assumed to be July;
* b. if only day is missing, the day is assumed to be 15;
* c. for the rest of all the scenarios, the year/month/day is assumed to be that of the mid-point between the last interview date of the previous wave and
* the first interview date of the next wave. (these scenarios inc, all the three variables are missing, or any two variables are missing, or only year is
* missing.)
replace d18vday = midday if d18vday == 99 & dth18 == 1   //47 changes
replace d18vmonth = midmonth if d18vmonth == 99 & dth18 == 1 //47 changes
replace d18vyear = midyear if d18vyear == 9999 & dth18 == 1 //47 changes

recode d18vday (99=15) if d18vmonth != 99 & d18vyear != 9999 & dth18 == 1 //0 changes
recode d18vmonth (99=7) if d18vday != 99 & d18vyear != 9999 & dth18 == 1  //0 changes

/************************************* (6) Modify input mistakes of death date according to Rule 2 *************************************/
* Rule 2:
* a. change day 29/max of Feb to 28 for years 99, 01, 02, 03, 05, 06, 07, 09, 10, 11, 13, 14 (non-leap year);
* b. change day 30/max of Feb to 29 for years 00, 04, 08, 12 (leap year);
* c. change day 31 to 30 for months 4, 6, 9, 11
foreach year of global year1 {
    recode d18vday (29/max=28) if d18vyear == `year' & d18vmonth == 2
}
foreach year of global year2 {
    recode d18vday (30/max=29) if d18vyear == `year' & d18vmonth == 2
}
foreach month of global months {
    recode d18vday (31=30) if d18vmonth == `month'
}

/****************************************************************************************************************************************/
/************************************* III. calculating survival time, censor and lost to follow-up *************************************/
/****************************************************************************************************************************************/

****set interview baseline
**codebook on interview date variables
* datein: day of interview
* monthin: month of the interview

/************************************* (7) Replacement of the missing interview baseline date according to Rule 3 *************************************/
* Rule 3:
* a. if only the interview day is missing, then the day is assumed to be 15th
* b. if both month and day are missing and the year isn't missing, or only the month is missing, the month/day is assumed to be that of the mid-point between the earliest interview date
* and the latest interiew date of that year
* c. no interview year is missing

codebook dayin    // no missing interview day
codebook monthin  // no missing interview month
codebook yearin   // no missing interview year

/************************************* (8) Modify input mistakes of interview baseline date according to Rule 2 *************************************/
* Rule 2:
* a. change day 29/max of Feb to 28 for years 99, 01, 02, 03, 05, 06, 07, 09, 10, 11, 13, 14 (non-leap year);
* b. change day 30/max of Feb to 29 for years 00, 04, 08, 12 (leap year);
* c. change day 31 to 30 for months 4, 6, 9, 11
recode dayin (29/max=28) if monthin == 2

foreach month of global months {
    recode dayin (31=30) if monthin == `month'
}

/************************************* (9) Calculate survival time for each person according to Rule 4 *************************************/

* Generate `survival_bas14_18', means the years from 2014 to death or censored.
* a. For those who died during the study, survival_bas14_18 = date of death - in14;
* b. For those who were lost in the study, survival_bas14_18 = the middle time of the wave - in14;
* c. For those who were lost in the study, survival_bas14_18 = the middle time of the wave - in14.

* Generate `survival_bth', from birth to death or censor14_18ed.
* e. survival_bth = survival_bas14_18 + verified age (*trueage*)

* Generate `lostdate`, means the lost date for those lost in the survey, and equals to the mid-point of last day of the previous interview
* and the first day of the next one

gen lostdate = .
gen survival_bas14_18 = . 

replace lostdate = mid_1418 if dth18 == -9

gen dthdate = mdy(d18vmonth, d18vday, d18vyear)
replace survival_bas14_18 = (dthdate - in14)/365.25
gen censor14_18 = 0
replace censor14_18 = 1 if survival_bas14_18 != .  //generate censor14_18=1 if die, censor14_18=0 if survived until end of the wave or lost to follow

replace survival_bas14_18 = (lostdate - in14)/365.25 if lostdate != .
gen lost14_18 = 1
replace lost14_18 = . if lostdate == .  

replace survival_bas14_18 = (in18 - in14)/365.25 if dth18 == 0

************** Not applicable for this wave: replace the survival time to 0 for those whose survival was negative
sum survival_bas14_18 //didn't replace the negative figures with 0, because the true value will be used to calculate the survival time to 2018 wave

* gen survival_bth14_18,means the years from birth to death or censor14_18ed
gen survival_bth14_18=survival_bas14_18+trueage

erase "${INTER}/work.dta"
macro drop _all

save "${OUT}/dat14_18.dta" // Match with Yaxi's dataset
=======
* Zhengting (Johnathan) He
* June 28th, 2021
* healthy-aging project
* Verify Yaxi's code on generting survival time: 14_18wave.do

// set working directories
global root "F:\Box Sync\Archives2020LLY\Zhengting\Duke Kunshan University Intern (zh133@duke.edu)\4 healthy aging-CLHLS\Group meeting coordination\survival time"
* define path for data sources
global RAW "${root}/raw data"
* define path for output data
global OUT "${root}/out data"
* define path for INTERMEDIATE
global INTER "${root}/inter data"

/*********************************************************************************************************************/
/************************************* I. logical check on death status and date *************************************/
/*********************************************************************************************************************/

/************************************* (1) Extract new added data at current wave *************************************/
use "${RAW}/clhls_2014_2018_longitudinal.dta", clear

/************************************* (2) Check the actual values of death date variables, against the codebook for those variables *************************************/
foreach var in d18vyear d18vmonth d18vday dth14_18 {
    codebook `var'
}
// codebook on death variables

// validated death year
* d18vyear: validated year of death
* . : missing

// validated death month
*d18vmonth:validated month of death*/
* . : missing

// validated death day
*d18vday: validated day of death*/
* . : missing

// survival status
* dth14_18: status of survival, death, or lost to follow-up from 2014 to 2018 wave
* -9: lost to follow-up in the 2018 survey
* 0: surviving at the 2018 survey
* 1: died before the 2018 survey

/************************************* Not applicable for this wave: (3) Check whether there are logical input mistakes between death status for different waves *************************************/
// check whether there are logical mistakes for dth**_##
* If the current death status is -9/0/1, the previous one can only be 0;
* if the current death status is -8, then the previous can only be -8,-9 and 1.
rename dth14_18 dth18

global waves "18"                                                            //******need to be changed
global year1 "2014 2015 2017 2018 2019"
global year2 "2016"
global months "4 6 9 11"
global wavein "in14 in18"
save work, replace
save "${INTER}/work.dta", replace

/************************************* (4) Check whether there are logical input mistakes between death status and the verified death year, month, day *************************************/
// check whether there are logical mistakes between d*vyear d*vmonth d*vday dth**_##
foreach i of global waves {
    // unify missing value to "99"
    recode d`i'vday(. 88=99) 
    recode d`i'vmonth(. 88=99)
    recode d`i'vyear(. 8888 9999=99)  //no 88 for all the 4 vars
    
    replace d`i'vyear = 1 if d`i'vyear > 1997 & d`i'vyear < 2020
    replace d`i'vmonth = 1 if d`i'vmonth > 0 & d`i'vmonth < 13
    replace d`i'vday = 1 if d`i'vday > 0 & d`i'vday < 32
    
    bys d`i'vyear: gen fre`i'_year = _N
    bys d`i'vmonth: gen fre`i'_month = _N
    bys d`i'vday: gen fre`i'_day = _N
    bys dth`i': gen fre`i'_dth = _N
}
label drop _all
save "${INTER}/work1.dta", replace

foreach i of global waves{
    keep d`i'vyear d`i'vmonth d`i'vday dth`i' fre`i'_year fre`i'_month fre`i'_day fre`i'_dth 
    duplicates drop d`i'vyear d`i'vmonth d`i'vday dth`i', force 
    save "${INTER}/wave`i'.dta", replace
    use "${INTER}/work1.dta", clear
}
use "${INTER}/wave18.dta",clear

browse

/* In wave14, all is missing in d18vyear/month/day when dth18=-9/0. 
There is no logical mistakes between the 4 vars.
There are 47 deceased persons without d18year/month/day. */

erase "${INTER}/work1.dta"
erase "${INTER}/wave18.dta"

/********************************************************************************************************************/
/************************************* II. Replacement of NA and input mistakes *************************************/
/********************************************************************************************************************/

use "${INTER}/work.dta", clear
*Extract the new added data at 2008 survey*
gen int id_year=mod(id,100)  //id_year=14 were the newly added ones

/*change all . to 99 for month&day, . to 9999 for year*/
foreach a of global waves{
    recode d`a'vday (. = 99) 
    recode d`a'vmonth (. = 99)
    recode d`a'vyear (. = 9999)
}

****calculate the mid-point between the last interview date of the previous wave and the first interview date of the next wave
gen in14 = mdy(monthin, dayin, yearin)                                              //******need to be changed
gen in18 = mdy(monthin_18, dayin_18, yearin_18)

egen maxin14 = max(in14)
egen minin18 = min(in18)
gen mid_1418 = (maxin14 + minin18)/2
gen midyear = year(mid_1418)
gen midmonth = month(mid_1418)
gen midday = day(mid_1418)

/************************************* (5) Replacement of the missing death date according to Rule 1 *************************************/
* Rule 1:
* For the three variables, year, month, and day:
* a. if only month is missing, the month is assumed to be July;
* b. if only day is missing, the day is assumed to be 15;
* c. for the rest of all the scenarios, the year/month/day is assumed to be that of the mid-point between the last interview date of the previous wave and
* the first interview date of the next wave. (these scenarios inc, all the three variables are missing, or any two variables are missing, or only year is
* missing.)
replace d18vday = midday if d18vday == 99 & dth18 == 1   //47 changes
replace d18vmonth = midmonth if d18vmonth == 99 & dth18 == 1 //47 changes
replace d18vyear = midyear if d18vyear == 9999 & dth18 == 1 //47 changes

recode d18vday (99=15) if d18vmonth != 99 & d18vyear != 9999 & dth18 == 1 //0 changes
recode d18vmonth (99=7) if d18vday != 99 & d18vyear != 9999 & dth18 == 1  //0 changes

/************************************* (6) Modify input mistakes of death date according to Rule 2 *************************************/
* Rule 2:
* a. change day 29/max of Feb to 28 for years 99, 01, 02, 03, 05, 06, 07, 09, 10, 11, 13, 14 (non-leap year);
* b. change day 30/max of Feb to 29 for years 00, 04, 08, 12 (leap year);
* c. change day 31 to 30 for months 4, 6, 9, 11
foreach year of global year1 {
    recode d18vday (29/max=28) if d18vyear == `year' & d18vmonth == 2
}
foreach year of global year2 {
    recode d18vday (30/max=29) if d18vyear == `year' & d18vmonth == 2
}
foreach month of global months {
    recode d18vday (31=30) if d18vmonth == `month'
}

/****************************************************************************************************************************************/
/************************************* III. calculating survival time, censor and lost to follow-up *************************************/
/****************************************************************************************************************************************/

****set interview baseline
**codebook on interview date variables
* datein: day of interview
* monthin: month of the interview

/************************************* (7) Replacement of the missing interview baseline date according to Rule 3 *************************************/
* Rule 3:
* a. if only the interview day is missing, then the day is assumed to be 15th
* b. if both month and day are missing and the year isn't missing, or only the month is missing, the month/day is assumed to be that of the mid-point between the earliest interview date
* and the latest interiew date of that year
* c. no interview year is missing

codebook dayin    // no missing interview day
codebook monthin  // no missing interview month
codebook yearin   // no missing interview year

/************************************* (8) Modify input mistakes of interview baseline date according to Rule 2 *************************************/
* Rule 2:
* a. change day 29/max of Feb to 28 for years 99, 01, 02, 03, 05, 06, 07, 09, 10, 11, 13, 14 (non-leap year);
* b. change day 30/max of Feb to 29 for years 00, 04, 08, 12 (leap year);
* c. change day 31 to 30 for months 4, 6, 9, 11
recode dayin (29/max=28) if monthin == 2

foreach month of global months {
    recode dayin (31=30) if monthin == `month'
}

/************************************* (9) Calculate survival time for each person according to Rule 4 *************************************/

* Generate `survival_bas14_18', means the years from 2014 to death or censored.
* a. For those who died during the study, survival_bas14_18 = date of death - in14;
* b. For those who were lost in the study, survival_bas14_18 = the middle time of the wave - in14;
* c. For those who were lost in the study, survival_bas14_18 = the middle time of the wave - in14.

* Generate `survival_bth', from birth to death or censor14_18ed.
* e. survival_bth = survival_bas14_18 + verified age (*trueage*)

* Generate `lostdate`, means the lost date for those lost in the survey, and equals to the mid-point of last day of the previous interview
* and the first day of the next one

gen lostdate = .
gen survival_bas14_18 = . 

replace lostdate = mid_1418 if dth18 == -9

gen dthdate = mdy(d18vmonth, d18vday, d18vyear)
replace survival_bas14_18 = (dthdate - in14)/365.25
gen censor14_18 = 0
replace censor14_18 = 1 if survival_bas14_18 != .  //generate censor14_18=1 if die, censor14_18=0 if survived until end of the wave or lost to follow

replace survival_bas14_18 = (lostdate - in14)/365.25 if lostdate != .
gen lost14_18 = 1
replace lost14_18 = . if lostdate == .  

replace survival_bas14_18 = (in18 - in14)/365.25 if dth18 == 0

************** Not applicable for this wave: replace the survival time to 0 for those whose survival was negative
sum survival_bas14_18 //didn't replace the negative figures with 0, because the true value will be used to calculate the survival time to 2018 wave

* gen survival_bth14_18,means the years from birth to death or censor14_18ed
gen survival_bth14_18=survival_bas14_18+trueage

erase "${INTER}/work.dta"
macro drop _all

save "${OUT}/dat14_18.dta" // Match with Yaxi's dataset
>>>>>>> 088ede343dd2dc26a7a9a0e206422180fd123b5f
