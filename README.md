# Chinese Longitudinal Healthy Longevity Survey (CLHLS) survival time generation

These codes are used to generate **survival time** and **survival status** of seven waves (1998, 2000, 2002, 2005, 2008, 2011, 2014, and 2018) of the Chinese Longitudinal Healthy Longevity Survey (CLHLS) for fitting survival analysis models.

Generation of the survival time and status follows the following flow and criteria:
```
1. Extract new added data at current wave
2. Check the actual values of death date variables, against the codebook for those variables
3. Check whether there are logical input mistakes between death status for different waves
4. Check whether there are logical input mistakes between death status and the verified death year, month, day
5. Replacement of the missing date according to Rule 1
6. Modify input mistakes of death date according to Rule 2
7. Replacement of the missing interview baseline date according to Rule 3
8. Modify input mistakes of interview baseline date according to Rule 2
9. Calculate survival time to 2014 wave for each person according to Rule 4
10. Extend survival time to 2018 wave for each person

Rule 1: For the 3 variables, year, month and day:
a. If only month is missing, the month is assumed to be July
b. If only day is missing, the day is assumed to be 15
c. For the rest of all scenarios, the year/month/day is assumed to be that of the mid-point between the last interview date of the previous wave and the first interview date of the next wave. (these scenarios inc, all the three variables are missing, or any two variables are missing, or only year is missing

Rule 2:
a. Change day 29/max of Feb to 28 for years 99, 01, 02, 03, 05, 06, 07, 09, 10, 11, 13, 14 (non-leap year)
b. Change day 30/max of Feb to 29 for years 00, 04, 08, 12 (leap year)
c. Change day 31 to 30 for months 4, 6, 9, 11

Rule 3:
a. If only the interview day is missing, then the day is assumed to be 15th
b. If both month and day are missing and the year isn’t missing, or only the month is missing, the month/day is assumed to be that of the mid-point between the earliest interview date and the latest interview date of that year.
c. No interview year is missing.

Rule 4: Generate survival time up to 2014 wave.
a. For those died in the study: survival time = death date – interview date at baseline
b. For those lost in the study: survival time = the mid-point of the two adjacent waves – interview date at baseline (the mid-point of the two adjacent waves is generated to Rule 1)
c. For those still alive at the end of the study: survival time = interview date in the last wave – interview date at baseline
d. If survival_bas < 0, change survival time to 0
```

These codes are generated by Yaxi Li, Victor Lee, and verified by Zhengting Johnathan He.