clear
cd "C:\AAA\PYAN\CLHLS\CLHLS data and codebook\Longitudinal data_with survival time_STATA version"
set more off
set maxvar 30000

append using dat98_14 dat00_14 dat02_14 dat05_14 dat08_14 dat11_14,keep(id) gen(wave_long)
save work,replace

use "C:\AAA\PYAN\P06 Healthy lifestyle\Cleaning_data\crsset_mis.dta" ,clear
keep id id_num wave
sort id wave
duplicates drop id id_num,force
merge 1:1 id using "C:\AAA\PYAN\CLHLS\CLHLS data and codebook\Longitudinal data_with survival time_STATA version\work"
keep if _merge==2
tab wave_long  //222 all from dat08_14
drop _merge
merge 1:1 id using "C:\AAA\PYAN\CLHLS\CLHLS data and codebook\Longitudinal data_with survival time_STATA version\dat08_14"
keep if _merge==3
sum yearin_14  //all missing
tab yearin_11  //91 lost to fu in 2011, 131 deceased
sum yearin
*** so for the 222 only occurring in the longitudinal data, they all just have once survey


use "C:\AAA\PYAN\P06 Healthy lifestyle\Cleaning_data\crsset_mis.dta" ,clear
keep id id_num wave
sort id wave
duplicates drop id id_num,force
merge 1:1 id using "C:\AAA\PYAN\CLHLS\CLHLS data and codebook\Longitudinal data_with survival time_STATA version\work"
replace id_num=1 if _merge==2
drop if _merge==1
keep id id_num
save "C:\AAA\PYAN\CLHLS\CLHLS data and codebook\Longitudinal data_with survival time_STATA version\id_num14"
erase "C:\AAA\PYAN\CLHLS\CLHLS data and codebook\Longitudinal data_with survival time_STATA version\work.dta"

********************************* to 2018 ********************************
clear
cd "C:\AAA\PYAN\CLHLS\CLHLS data and codebook\Longitudinal data_with survival time_STATA version"
set more off
set maxvar 30000

foreach v in 98 00 02 05 08 11{
use dat`v'_18,clear
keep id survival_bas censor lost interview_baseline survival_bas`v'_18 censor`v'_18 lost`v'_18
rename survival_bas`v'_18 survival_bas18
rename censor`v'_18 censor18
rename lost`v'_18 lost18
rename survival_bas survival_bas14
rename censor censor14
rename lost lost14
save work`v',replace
}
use dat14_18_1125,clear
keep id in14 survival_bas14_18 censor14_18 lost14_18
rename in14 interview_baseline
rename survival_bas14_18 survival_bas18
rename censor14_18 censor18
rename lost14_18 lost18
save work14

append using work98 work00 work02 work05 work08 work11,keep(id interview_baseline survival_bas14 censor14 lost14 survival_bas18 censor18 lost18) gen(wave_long)
replace wave_long=7 if wave_long == 0 //recode work14 as the 7th wave.
save work,replace

use "C:\AAA\PYAN\P06 Healthy lifestyle\Cleaning_data\crsset_mis.dta" ,clear
keep id id_num wave
sort id wave
duplicates drop id id_num,force
merge 1:1 id using work  //10 only from master, 222 only from using (the 222 all from 2008wave, and they all just have one survey)

replace id_num=1 if _merge==2
drop if _merge==1
keep id id_num interview_baseline survival_bas14 censor14 lost14 survival_bas18 censor18 lost18
save "C:\AAA\PYAN\CLHLS\CLHLS data and codebook\Longitudinal data_with survival time_STATA version\idnum_survival18",replace
erase work.dta 
foreach v in 98 00 02 05 08 11 14{
erase work`v'.dta
}
