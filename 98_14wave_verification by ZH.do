* Zhengting (Johnathan) He
* May 8th, 2021
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


use "${RAW}/1998_2014_longitudinal_dataset_released_version1.dta", clear


// codebook on death variables

// validated death year
* d0vyear, d2vyear, d5vyear, d8vyear, d11vyear, d14vyear: validated year of death*/
* -9:lost to follow up in the 2000/2002/2005/2008/2011/2014 survey*
* -8:died or lost to follow-up in previous waves*
* -7:it is for the deceased persons, not applicable for survivors*
* 8888: don't know*/
* 9999: missing*/

// validated death month
* d0vmonth, d2vmonth, d5vmonth, d8vmonth, d11vmonth, d14vmonth: validated month of death*/
* -9: lost to follow-up in the 2000/02/05/08/11/14 survey*/
* -8: died or lost to follow-up in previous waves*/
* -7: it is for the deceased persons, not applicable for survivors*/
* 88: don't know*/
* 99: missing*/

// validated death day
* d0vday, d2vday, d5vday, d8vday, d11vday, d14vday: validated day of death*/
* -9: lost to follow-up in the 2000/02/05/08/11/14 survey*/ 
* -8: died or lost to follow-up in previous waves*/
* -7: it is for the deceased persons, not applicable for survivors*/
* 88: don't know*/
* 99: missing*/

* note: d14vyear/month/day & d11vday have . as missing value

// survival status
* dth98_00, dth00_02, dth02_05, dth05_08, dth08_11, dth11_14: status of survival, death, or lost to follow-up from 1998-2000/2000-2002/2002-2005/2005-2008/2008-2011/2011-2014 waves*/
* dth98_00:
* -9:lost to follow-up in the 2000 survey;
* 0: still alive at 2000 survey;
* 1: died before 2000 survey
* dth**_##:
* -9:lost to follow-up at the ## survey;
* -8:died or lost to follow-up in previous waves;
* 0:surviving at the ## survey;
* 1: died before the ## survey


// check whether there are logical mistakes for dth**_##
* If the current death status is -9/0/1, the previous one can only be 0;
* if the current death status is -8, then the previous can only be -8,-9 and 1.
preserve
rename dth98_00 dth1
rename dth00_02 dth2
rename dth02_05 dth3
rename dth05_08 dth4
rename dth08_11 dth5
rename dth11_14 dth6
label drop _all
forv i=1/5 {
    local j=`i'+1
    tab dth`i' if dth`j' == -9 | dth`j' == 0 | dth`j' == 1, missing //0
    tab dth`i' if dth`j' == -8, missing //-8, -9, 1
}
restore

* id = 45107898 & 50001898 were problematic
* id=50001898, died in 02_05wave, should change dth98_00/d0vyear/month/day from -9 to 0/-7
* id=45107898, have two died dates, 02_05wave:2002.8.29, and 05_08wave:2006.12.21, both dth02_05 and dth05_08 are 1. Inferring from the data, the person should die in 05_05wave, as there is detailed info in 2005 for that person.

replace dth98_00 = 0 if id==50001898 
replace dth02_05 = 0 if id==45107898
replace d5vday = -7 if id==45107898
replace d5vmonth = -7 if id==45107898
replace d5vyear = -7 if id==45107898

keep id dth98_00 dth00_02 dth02_05 dth05_08 dth08_11 dth11_14 d0vyear d0vmonth d0vday d2vyear d2vmonth d2vday d5vyear d5vmonth d5vday d8vyear d8vmonth d8vday d11vyear d11vmonth d11vday d14vyear d14vmonth d14vday

rename dth98_00 dth0
rename dth00_02 dth2
rename dth02_05 dth5
rename dth05_08 dth8
rename dth08_11 dth11
rename dth11_14 dth14

global waves "0 2 5 8 11 14"
global year1 "1999 2001 2002 2003 2005 2006 2007 2009 2010 2011 2013 2014"
global year2 "2000 2004 2008 2012"
global months "4 6 9 11"
global wavein "in98 in0 in2 in5 in8 in11 in14"
save "${INTER}/work.dta",replace


