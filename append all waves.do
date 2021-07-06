/*********************************************************************************************************************/
/************************************** CLHLS longitudinal dataset survival time *************************************/
/*********************************************************************************************************************/
* Zhengting (Johnathan) He
* July 5th, 2021
* healthy-aging project
* Verify Yaxi's code on appending survival time: code for creating idnum_survival18.do
* Verify Yaxi's code on generating crsset_mis.dta: healthy_lifestyle_code_repeated measures.sas

// set working directories
global root "F:\Box Sync\Archives2020LLY\Zhengting\Duke Kunshan University Intern (zh133@duke.edu)\4 healthy aging-CLHLS\Group meeting coordination\survival time"
* define path for data sources
global RAW "${root}/raw data"
* define path for output data
global OUT "${root}/out data"
* define path for INTERMEDIATE
global INTER "${root}/inter data"

foreach v in 98 00 02 05 08 11 {
    use "${OUT}/dat`v'_18surtime.dta", clear
    keep id interview_baseline survival_bas`v'_18 censor`v'_18 lost`v'_18
    rename survival_bas`v'_18 survival_bas18
    rename censor`v'_18 censor18
    rename lost`v'_18 lost18
    save "${INTER}/work`v'.dta", replace
}

use "${OUT}/dat14_18_1125surtime.dta", clear
keep id in14 survival_bas14_18 censor14_18 lost14_18
rename in14 interview_baseline
rename survival_bas14_18 survival_bas18
rename censor14_18 censor18
rename lost14_18 lost18
save "${INTER}/work14.dta", replace

append using "${INTER}/work98.dta" "${INTER}/work00.dta" "${INTER}/work02.dta" ///
"${INTER}/work05.dta" "${INTER}/work08.dta" "${INTER}/work11.dta", ///
keep(id interview_baseline survival_bas18 censor18 lost18) gen(wave_long)

replace wave_long=7 if wave_long == 0

save "${INTER}/work.dta", replace

*generating crsset_mis.dta (id_num, wave)
use "${RAW}/origin_crs14.dta", clear
keep id
append using "${RAW}/origin_crs98.dta" "${RAW}/origin_crs00.dta" "${RAW}/origin_crs02.dta" "${RAW}/origin_crs05.dta" ///
"${RAW}/origin_crs08.dta" "${RAW}/origin_crs11.dta", keep(id) gen(wave)

replace wave = 7 if wave == 0

bys id: gen id_num = _N

save "${OUT}/crsset_mis.dta", replace

sort id wave

duplicates drop id id_num, force

merge 1:m id using "${INTER}/work.dta"

replace id_num = 1 if _merge == 2
drop if _merge == 1

keep id id_num interview_baseline survival_bas18 censor18 lost18

save "${OUT}/idnum_survival18.dta", replace
