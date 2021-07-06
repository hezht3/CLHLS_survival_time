# Summary on issues and updates related to CLHLS longitudinal dataset survival time generation

I do not think I identified any problems in previous datasets generated, but I do think there are some minor issues on the codes generating these datasets.

## For all waves

### Add comments to reflect the diagram and flow of data cleaning

### (2) Check the actual values of death date variables, against the codebook for those variables

Add a command to check the values of **validated year month day** and **status of survival**
```
foreach var in d0vyear d2vyear d5vyear d8vyear d11vyear d14vyear d0vmonth d2vmonth d5vmonth d8vmonth d11vmonth d14vmonth d0vday d2vday d5vday d8vday d11vday d14vday dth98_00 dth00_02 dth02_05 dth05_08 dth08_11 dth11_14 {
    codebook `var'
}
```

### (4) Check whether there are logical input mistakes between death status and the verified death year, month, day

In unifing missing value to "99", change problematic recoding d`i'vyear according to codebook
```
recode d`i'vyear(. 88 9999=99)
->
recode d`i'vyear(. 8888 9999=99)
```

### (7) Replacement of the missing interview baseline date according to Rule 3

For some waves, add missing step of "replacement of the missing interview baseline date according to Rule 3"
```
codebook dayin     // no missing interview date
codebook monthin   // no missing interview month
```
Or:
```
gen mid_in2 = (min_in2 + max_in2)/2
foreach x in month day {
	gen mid`x'_in2 = `x'(mid_in2)
	replace `x'02 = mid`x'_in2 if `x'02 == 99
}  
```

### (8) Modify input mistakes of interview baseline date according to Rule 2

Add missing step of "modify input mistakes of interview baseline date according to Rule 2
```
recode date98 (29/max=28) if month98 == 2

foreach month of global months{
    recode date98 (31=30) if month98 == `month'
}
```

## wave02_18

line 227-229, my output shows:
```
	keep if censor02_14==1 & _merge==3
	display id dthyear dthmonth dthday survival_bas02_14 lost02_14 censor02_14 d18vyear d18vmonth d18vday survival_bas14_18
restore
# (15,400 observations deleted)
# 4545400220116309.1964408.1d18vyear not found
# r(111);
# r(111);
```
And, only 1 obs left after these lines.
If I change `keep` to `drop`, the outputted dataset has 9747 obs, contrast to Yaxi's dataset which has 9748 obs.
I wonder whether these lines are just temporary commands.

## code for creating idnum_survival18.do

Supplement generation code of "crsset_mis.dta"

line 69 reports error:

```
merge 1:1 id using work
# variable id does not uniquely identify observations in the using data
```

I think it should be revised as
```
merge 1:m id using "${INTER}/work.dta"
#     Result                           # of obs.
#     -----------------------------------------
#     not matched                           231
#         from master                         9  (_merge==1)
#         from using                        222  (_merge==2)
# 
#     matched                            50,457  (_merge==3)
#     -----------------------------------------
```

And the total obs and values of each variable I generated does match with Yaxi's dataset.


```R

```
