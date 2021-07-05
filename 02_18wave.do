/*********************************************************************************************************************/
/************************************** CLHLS longitudinal dataset survival time *************************************/
/*********************************************************************************************************************/
* Zhengting (Johnathan) He
* July 5th, 2021
* healthy-aging project
* Verify Yaxi's code on generting survival time: 98_14wave.do

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
use "${RAW}/2002_2014_longitudinal_dataset_released_version1.dta", clear
gen int id_year = mod(id, 100)
keep if id_year == 02

/************************************* (2) Check the actual values of death date variables, against the codebook for those variables *************************************/
foreach var in d5vyear d8vyear d11vyear d14vyear d5vmonth d8vmonth d11vmonth d14vmonth d5vday d8vday d11vday d14vday dth02_05 dth05_08 dth08_11 dth11_14 {
    codebook `var'
}
// codebook on death variables

// validated death year
* d5vyear, d8vyear, d11vyear, d14vyear: validated year of death*/
* -9: lost to follow up in the 2005/2008/2011/2014 survey*
* -8: died or lost to follow-up in previous waves*
* -7: it is for the deceased persons, not applicable for survivors*
* . 9999: missing*/

// validated death month
* d5vmonth, d8vmonth, d11vmonth, d14vmonth: validated month of death*/
* -9: lost to follow-up in the 2005/08/11/14 survey*/
* -8: died or lost to follow-up in previous waves*/
* -7: it is for the deceased persons, not applicable for survivors*/
* . 99: missing*/

// validated death day
* d5vday, d8vday, d11vday, d14vday: validated day of death*/
* -9: lost to follow-up in the 2002/05/08/11/14 survey*/ 
* -8: died or lost to follow-up in previous waves*/
* -7: it is for the deceased persons, not applicable for survivors*/
* . 99: missing*/

// survival status
* dth02_05, dth05_08, dth08_11, dth11_14: status of survival, death, or lost to follow-up from 2002-2005/2005-2008/2008-2011/2011-2014 waves*/
* dth**_##:
* -9: lost to follow-up at the ## survey;
* -8: died or lost to follow-up in previous waves;
* 0: surviving at the ## survey;
* 1: died before the ## survey
* dth08_11:
* 2: surviving at 2011 survey but died before 2012 survey (only one, 2011.12.9 died)

/************************************* (3) Check whether there are logical input mistakes between death status for different waves *************************************/
// check whether there are logical mistakes for dth**_##
* If the current death status is -9/0/1, the previous one can only be 0;
* if the current death status is -8, then the previous can only be -8,-9 and 1.
preserve
rename dth02_05 dth3
rename dth05_08 dth4
rename dth08_11 dth5
rename dth11_14 dth6
label drop _all
forv i = 3/5 {
    local j = `i' + 1
    tab dth`i' if dth`j' == -9 | dth`j' == 0 | dth`j' == 1, missing //0
    tab dth`i' if dth`j' == -8, missing //-8, -9, 1
}
restore

keep if dth08_11 == 2 & (dth11_14 == -9 | dth11_14 == 0 | dth11_14 == 1)

// id = 32176802, died in 08_11 wave(dth08_11=2,2011.12.9), but dth11_14 = -9, d14vyear/month/day = .

*****************************create work.dta, which has changed the death status according results above, and renanme dth**_##***********
use "${RAW}/2002_2014_longitudinal_dataset_released_version1.dta", clear
gen int id_year = mod(id, 100)
keep if id_year == 02

recode dth08_11(2=1) //1 change
recode dth11_14(-9=-8) if id==32176802

rename dth02_05 dth5
rename dth05_08 dth8
rename dth08_11 dth11
rename dth11_14 dth14

global waves "5 8 11 14"                                                        //******need to be changed
global year1 "2002 2003 2005 2006 2007 2009 2010 2011 2013 2014"
global year2 "2004 2008 2012"
global months "4 6 9 11"
global wavein "in2 in5 in8 in11 in14"
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
use "${INTER}/wave14.dta",clear
append using "${INTER}/wave5.dta" "${INTER}/wave8.dta" "${INTER}/wave11.dta"

browse

/* The results show that, in wave0-wave11, -9, -8, 0/-7(alive) have completely the same freq, 
all missing values in d*vyear/month/day occur only when dth*=1(died). Only in wave14, all is missing in d14vyear/month/day when dth14=-9/-8/0. 
There is no logical mistakes between the 4 vars.*/

// tabulate the lost,died and alive number for each wave
use "${INTER}/work1.dta",clear
foreach i of global waves {
    tabulate dth`i' if dth`i' != -8
}

foreach i of global waves {
    erase "${INTER}/wave`i'.dta"
}
erase "${INTER}/work1.dta"

/********************************************************************************************************************/
/************************************* II. Replacement of NA and input mistakes *************************************/
/********************************************************************************************************************/

use "${INTER}/work.dta", clear
/*change all . to 99 for month&day, . to 9999 for year*/
foreach a of global waves {
    recode d`a'vday (. = 99) 
    recode d`a'vmonth (. = 99)
    recode d`a'vyear (. = 9999)
}

****calculate the mid-point between the last interview date of the previous wave and the first interview date of the next wave
capture noisily gen in98 = mdy(month98, date98, year9899)                            
capture noisily gen in0 = mdy(month_0, day_0, 2000)
capture noisily gen in2 = mdy(month02, day02, 2002)
capture noisily gen in5 = mdy(month_5, day_5, 2005)
capture noisily gen in8 = mdy(month_8, day_8, year_8)
gen in11 = mdy(monthin_11, dayin_11, yearin_11)
gen in14 = mdy(monthin_14, dayin_14, yearin_14) 

forv i=1/4 {                                                                     //******need to be changed                                               
    local wavein2 = word("$wavein", `i')
         egen min_`wavein2' = min(`wavein2')
         egen max_`wavein2' = max(`wavein2')
    local j = `i'+1
    local wavein3 = word("$wavein", `j')
         egen min_`wavein3' = min(`wavein3')
         egen max_`wavein3' = max(`wavein3')
    gen mid_`wavein2'_`wavein3' = (max_`wavein2' + min_`wavein3')/2
    gen midyear_`wavein2'_`wavein3' = year(mid_`wavein2'_`wavein3')
    gen midmonth_`wavein2'_`wavein3' = month(mid_`wavein2'_`wavein3')
    gen midday_`wavein2'_`wavein3' = day(mid_`wavein2'_`wavein3')
drop min_`wavein3' max_`wavein3'
}

/************************************* (5) Replacement of the missing death date according to Rule 1 *************************************/
* Rule 1:
* For the three variables, year, month, and day:
* a. if only month is missing, the month is assumed to be July;
* b. if only day is missing, the day is assumed to be 15;
* c. for the rest of all the scenarios, the year/month/day is assumed to be that of the mid-point between the last interview date of the previous wave and
* the first interview date of the next wave. (these scenarios inc, all the three variables are missing, or any two variables are missing, or only year is
* missing.)
local j = 1
foreach i of global waves { 
        recode d`i'vday (99 = 15) if d`i'vmonth != 99 & d`i'vyear != 9999 & dth`i' == 1 
        recode d`i'vmonth (99 = 7) if d`i'vday != 99 & d`i'vyear != 9999 & dth`i' == 1 
    
    local inid = word("$wavein",`j')
        replace d`i'vday = midday_`inid'_in`i' if d`i'vday == 99 & dth`i' == 1
        replace d`i'vmonth = midmonth_`inid'_in`i' if d`i'vmonth == 99 & dth`i' == 1
        replace d`i'vyear = midyear_`inid'_in`i' if d`i'vyear == 9999 & dth`i' == 1
      
    local j = `j'+1
}

/************************************* (6) Modify input mistakes of death date according to Rule 2 *************************************/
* Rule 2:
* a. change day 29/max of Feb to 28 for years 99, 01, 02, 03, 05, 06, 07, 09, 10, 11, 13, 14 (non-leap year);
* b. change day 30/max of Feb to 29 for years 00, 04, 08, 12 (leap year);
* c. change day 31 to 30 for months 4, 6, 9, 11
foreach i of global waves{
    foreach year of global year1{
        recode d`i'vday (29/max=28) if d`i'vyear == `year' & d`i'vmonth == 2
    }
    foreach year of global year2{
        recode d`i'vday (30/max=29) if d`i'vyear == `year' & d`i'vmonth == 2
    }
    foreach month of global months{
        recode d`i'vday (31=30) if d`i'vmonth == `month'
    }
}

/****************************************************************************************************************************************/
/************************************* III. calculating survival time, censor and lost to follow-up *************************************/
/****************************************************************************************************************************************/

/************************************* (7) Replacement of the missing interview baseline date according to Rule 3 *************************************/
* Rule 3:
* a. if only the interview day is missing, then the day is assumed to be 15th
* b. if both month and day are missing and the year isn't missing, or only the month is missing, the month/day is assumed to be that of the mid-point between the earliest interview date
* and the latest interiew date of that year
* c. no interview year is missing

gen mid_in2 = (min_in2 + max_in2)/2
foreach x in month day {
	gen mid`x'_in2 = `x'(mid_in2)
	replace `x'02 = mid`x'_in2 if `x'02 == 99
}  

/************************************* (8) Modify input mistakes of interview baseline date according to Rule 2 *************************************/
* Rule 2:
* a. change day 29/max of Feb to 28 for years 99, 01, 02, 03, 05, 06, 07, 09, 10, 11, 13, 14 (non-leap year);
* b. change day 30/max of Feb to 29 for years 00, 04, 08, 12 (leap year);
* c. change day 31 to 30 for months 4, 6, 9, 11
recode day02 (29/max=28) if month02 == 2

foreach month of global months {
    recode day02 (31=30) if month02 == `month'
}

****set interview baseline
**codebook on interview date variables
* date00: day of interview of the 2000 survey; 1~31, 99=missing
* month00: month of the interview of the 2000 survey*; 1~12, 99=missing
gen interview_baseline = mdy(month02, day02, 2002)                                  //******need to be changed      

/************************************* (9) Calculate survival time for each person according to Rule 4 *************************************/
* Rule 4:
* Generate two different survival time (**for data sets with suffix_14**):

* One is `survival_bas', from interview baseline to death or censored, **up to 2014 wave**.
* a. For those died in the study: survival time = death date - interview date at baseline;
* b. For those lost in the study: survival time = the mid-point of the two adjacent waves - interview date at baseline;
* (the mid-point of the two adjacent waves is generated according to Rule 1)
* c. For those still alive at the end of the study: survival time = interview date in the last wave - interview date at baseline;
* d. If survival_bas < 0, change survival time to 0.

* Another one is `survival_bth', from birth to death or censored, **up to 2014 wave**.
* e. survival_bth = survival_bas + verified age (*trueage*)

* Variables for death/lost status
* `censor' is coded as: 1 = died, 0 = not died (alive or lost);
* `lost' is coed as: 1 = lost, . = not lost

* gen survival_bas,means the years from baseline to death or censored
* generate dthyear/month/day, means the exact death year/month/day of those who died during the whole period (2000-2014)
* gen lostdate, means the lost date for those lost in the survey, and equals to the mid-point of last day of the previous interview and the first day of the next one

gen dthyear = .
gen dthmonth = .
gen dthday = .
gen lostdate = .
gen survival_bas = .

local j=1
foreach i of global waves {
    replace dthyear = d`i'vyear if d`i'vyear > 0 & d`i'vyear < 2020
    replace dthmonth = d`i'vmonth if d`i'vmonth > 0 & d`i'vmonth < 13
    replace dthday = d`i'vday if d`i'vday > 0 & d`i'vday < 32
local inid = word("$wavein", `j')
    replace lostdate = mdy(midmonth_`inid'_in`i', midday_`inid'_in`i', midyear_`inid'_in`i') if dth`i' == -9
local j = `j' + 1
}

gen dthdate = mdy(dthmonth, dthday, dthyear)
replace survival_bas = (dthdate - interview_baseline)/365.25
gen censor = 0
replace censor = 1 if survival_bas != .  //generate censor=1 if die, censor=0 if survived until end of the wave or lost to follow

replace survival_bas = (lostdate - interview_baseline)/365.25 if lostdate != .
gen lost = 1
replace lost = . if lostdate == .

gen interview2014 = mdy(monthin_14, dayin_14, yearin_14) if dth14 == 0
replace survival_bas = (interview2014 - interview_baseline)/365.25 if interview2014 != .

**************replace the survival time to 0 for those whose survival was negative
sum survival_bas
* gen survival_bth,means the years from birth to death or censored
replace survival_bas = 0 if survival_bas < 0  
* gen survival_bth,means the years from birth to death or censored
gen survival_bth = survival_bas + trueage                                                            
erase "${INTER}/work.dta"
macro drop _all

/************************************* (10) calc survival time to 2018 *************************************/

merge 1:1 id using "${OUT}/dat14_18surtime.dta", keepus(id survival_bas14_18 survival_bth14_18 censor14_18 lost14_18) nolabel //47, 96, 1110, 821 merged for dat98/00/05/11_14

ren (survival_bas survival_bth lost censor) (survival_bas02_14 survival_bth02_14 lost02_14 censor02_14)

gen survival_bas02_18 = survival_bas02_14
replace survival_bas02_18 = survival_bas02_14 + survival_bas14_18 if censor02_14 == 0 & _merge == 3  //1538 replaced, one died in 2011.6.30, but was recorded as missing in d18vyear/month/day, so no need to be changed
preserve

    /* drop if censor02_14 == 1 & _merge == 3
	display id dthyear dthmonth dthday survival_bas02_14 lost02_14 censor02_14 d18vyear d18vmonth d18vday survival_bas14_18
restore */

gen survival_bth02_18 = survival_bth02_14
replace survival_bth02_18 = survival_bth02_14 + survival_bas14_18 if censor02_14 == 0 & _merge == 3

gen censor02_18 = censor02_14
replace censor02_18 = censor14_18 if _merge == 3 & id !=45454002  //427 died between 2014 and 2018

gen lost02_18 = lost02_14
replace lost02_18 = lost14_18 if _merge==3 & id != 45454002  //351 lost between 2014 and 2018

drop if _merge==2
drop _merge

save "${OUT}/dat02_18surtime.dta", replace
