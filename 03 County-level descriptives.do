****
* Setup
***
cd "/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Data"
global path "/Users/amuchow/Dropbox/Caty&Neeraj&Ashley"

cap log close
log using "$path/Logs/03 County-level descriptives.log", replace

********************************************************************************
* COVID-19 project
* County-level descriptives
* Created on: 12 May 2020
* Updated on: 10 Dec 2020
********************************************************************************

* Define regressors 
global dem pct_over65 pct_under18 pct_male pct_nohs pct_bachelorplus 
global ses pct_below_fpl pct_unemp pct_unins ln_med_income 
global health pcp_pc md_pc hosp_pc hosp_beds_pc chc_pc npc_pc  
global chronic copd asthma atrial_fib heart_failure ischemic_heart_disease cancer hypertension /*hiv_aids*/ diabetes chronic_kidney_diease /*hepatitis*/

***
* Basic descriptives 
***
use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Temporarily replacing speed values for counties with no NPI to not throw off stats
foreach type in dbl cnty nat {
foreach npi in sah_bc sah bc sah_bc res mask k12 nh gym cmbd other {
replace `npi'_speed_`type'_both = . if missing(`npi'_both_start)
}
}

* Overall
tabstat covid_deaths_pc covid_cases_pc pop pop_density sah_bc_speed_dbl_both cmbd_speed_dbl_both sah_speed_dbl_both bc_speed_dbl_both other_speed_dbl_both mask_speed_dbl_both k12_speed_dbl_both gym_speed_dbl_both nh_speed_dbl_both res_speed_dbl_both state_test_results_pc m50 rep pct_over65 pct_unins pct_unemp pct_below_fpl comorbid_index, s(N mean sd min max) save

mat def overall = r(StatTotal)'
mat rownames overall = covid_deaths_pc covid_cases_pc pop pop_density sah_bc_speed_dbl_both cmbd_speed_dbl_both sah_speed_dbl_both bc_speed_dbl_both other_speed_dbl_both mask_speed_dbl_both k12_speed_dbl_both gym_speed_dbl_both nh_speed_dbl_both res_speed_dbl_both state_test_results_pc m50 rep pct_over65 pct_unins pct_unemp pct_below_fpl comorbid_index
matlist overall

putexcel set "$path/Output/County-level descriptive statistics 10Dec20.xlsx", replace sheet("Overall")
putexcel A1 = matrix(overall), names 

* By type
use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Create var that groups counties as (1) early (2) never or (3) late adopters
gen type = "Early" if early==1
	replace type = "Late" if late==1
	replace type = "Never" if never==1

* Temporarily replacing speed values for counties with no NPI to not throw off stats
foreach type in dbl cnty nat {
foreach npi in sah_bc sah bc sah_bc res mask k12 nh gym cmbd other {
replace `npi'_speed_`type'_both = . if missing(`npi'_both_start)
}
}

qui tabstat covid_deaths_pc covid_cases_pc pop pop_density sah_bc_speed_dbl_both cmbd_speed_dbl_both sah_speed_dbl_both bc_speed_dbl_both other_speed_dbl_both mask_speed_dbl_both k12_speed_dbl_both gym_speed_dbl_both nh_speed_dbl_both res_speed_dbl_both state_test_results_pc m50 rep pct_over65 pct_unins pct_unemp pct_below_fpl comorbid_index, by(type) s(N mean sd min max) save

forvalues i = 1/3 {
mat def m`i' = r(Stat`i')'
mat colnames m`i' = "`r(name`i')''"
mat rownames m`i' = covid_deaths_pc covid_cases_pc pop pop_density sah_bc_speed_dbl_both cmbd_speed_dbl_both sah_speed_dbl_both bc_speed_dbl_both other_speed_dbl_both mask_speed_dbl_both k12_speed_dbl_both gym_speed_dbl_both nh_speed_dbl_both res_speed_dbl_both state_test_results_pc m50 rep pct_over65 pct_unins pct_unemp pct_below_fpl comorbid_index
}

mat def table = m1, m2, m3

putexcel set "$path/Output/County-level descriptive statistics 10Dec20.xlsx", modify sheet("By type")
putexcel A1 = matrix(table), names 


**********************
** t-tests **
**********************

* Time-varying
use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Create var that groups counties as (1) early (2) never or (3) late adopters
gen type = "Early" if early==1
	replace type = "Late" if late==1
	replace type = "Never" if never==1

* Temporarily replacing speed values for counties with no NPI to not throw off stats
foreach type in dbl cnty nat {
foreach npi in sah_bc sah bc sah_bc res mask k12 nh gym cmbd other {
replace `npi'_speed_`type'_both = . if missing(`npi'_both_start)
}
}

foreach var in covid_deaths_pc covid_cases_pc pop pop_density sah_bc_speed_dbl_both cmbd_speed_dbl_both sah_speed_dbl_both bc_speed_dbl_both other_speed_dbl_both mask_speed_dbl_both k12_speed_dbl_both gym_speed_dbl_both nh_speed_dbl_both res_speed_dbl_both state_test_results_pc m50 rep pct_over65 pct_unins pct_unemp pct_below_fpl comorbid_index {

di "`var'"
ttest `var' if inlist(type,"Early","Late"), by(type)
mat def A = r(mu_1)
mat def B = r(sd_1)
mat def C = r(mu_2)
mat def D = r(sd_2)
mat def E = r(p)

cap ttest `var' if inlist(type,"Early","Never"), by(type)
mat def F = r(mu_2)
mat def G = r(sd_2)
mat def H = r(p)

mat def `var' = A, B, C, D, E, F, G, H

mat rown `var' = "`var'"
mat coln `var' = EarlyMean EarlySD LateMean LateSD p-value NeverMean NeverSD p-value 

}

mat def combined = covid_deaths_pc \ covid_cases_pc \ sah_bc_speed_dbl_both \ cmbd_speed_dbl_both \ sah_speed_dbl_both \ bc_speed_dbl_both \ other_speed_dbl_both \ mask_speed_dbl_both \ k12_speed_dbl_both \ gym_speed_dbl_both \ nh_speed_dbl_both \ res_speed_dbl_both \ state_test_results_pc \ m50 \ rep \ pct_over65 \ pct_unins \ pct_unemp \ pct_below_fpl \ comorbid_index

matlist combined
putexcel set "$path/Output/County-level descriptive statistics 10Dec20.xlsx", modify sheet("t-tests time-varying")
putexcel A1 = matrix(combined), names 


* Time-invariant

use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Create var that groups counties as (1) early (2) never or (3) late adopters
gen type = "Early" if early==1
	replace type = "Late" if late==1
	replace type = "Never" if never==1

* Temporarily replacing speed values for counties with no NPI to not throw off stats
foreach type in dbl cnty nat {
foreach npi in sah_bc sah bc sah_bc res mask k12 nh gym cmbd other {
replace `npi'_speed_`type'_both = . if missing(`npi'_both_start)
}
}

collapse rep pct_over65 pct_unins pct_unemp pct_below_fpl comorbid_index pop pop_density, by(grp_fips type)

foreach var in rep pct_over65 pct_unins pct_unemp pct_below_fpl comorbid_index pop pop_density {

di "`var'"
ttest `var' if inlist(type,"Early","Late"), by(type)
mat def A = r(mu_1)
mat def B = r(sd_1)
mat def C = r(mu_2)
mat def D = r(sd_2)
mat def E = r(p)

cap ttest `var' if inlist(type,"Early","Never"), by(type)
mat def F = r(mu_2)
mat def G = r(sd_2)
mat def H = r(p)

mat def `var' = A, B, C, D, E, F, G, H

mat rown `var' = "`var'"
mat coln `var' = EarlyMean EarlySD LateMean LateSD p-value NeverMean NeverSD p-value 

}

mat def combined = rep \ pct_over65 \ pct_unins \ pct_unemp \ pct_below_fpl \ comorbid_index \ pop \ pop_density

matlist combined
putexcel set "$path/Output/County-level descriptive statistics 10Dec20.xlsx", modify sheet("t-tests time-invar")
putexcel A1 = matrix(combined), names 




***
* Table showing states and counties with NPIs (for appendix?)
***

use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

format date %tdMonth_dd

* Create var that groups counties as (1) early (2) never or (3) late adopters
gen type = "Early" if early==1
	replace type = "Late" if late==1
	replace type = "Never" if never==1

collapse (max) sah_both bc_both sah_bc_both cmbd_both mask_both k12_both nh_both res_both gym_both other_both sah_state_start bc_state_start sah_bc_state_start cmbd_both_start mask_state_start k12_state_start nh_state_start res_state_start gym_state_start other_state_start sah_cnty_start bc_cnty_start sah_bc_cnty_start mask_cnty_start k12_cnty_start sah_speed_dbl_both bc_speed_dbl_both sah_bc_speed_dbl_both mask_speed_dbl_both k12_speed_dbl_both nh_speed_dbl_both res_speed_dbl_both gym_speed_dbl_both other_speed_dbl_both, by(state grp_fips county type)

export excel using "$path/Output/NPI adoption by state and county 10Dec20.xlsx", firstrow(variables) sheet("Overall") replace


* By group (early)
use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

format date %tdMonth_dd

* Create var that groups counties as (1) early (2) never or (3) late adopters
gen type = "Early" if early==1
	replace type = "Late" if late==1
	replace type = "Never" if never==1

collapse (max) sah_bc_both_start if type=="Early", by(state grp_fips county type)

export excel using "$path/Output/NPI adoption by state and county 10Dec20.xlsx", firstrow(variables) sheet("Early", modify) 


* By group (late)
use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

format date %tdMonth_dd

* Create var that groups counties as (1) early (2) never or (3) late adopters
gen type = "Early" if early==1
	replace type = "Late" if late==1
	replace type = "Never" if never==1

collapse (max) sah_bc_both_start if type=="Late", by(state grp_fips county type)

export excel using "$path/Output/NPI adoption by state and county 10Dec20.xlsx", firstrow(variables) sheet("Late", modify) 


* By group (never)
use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

format date %tdMonth_dd

* Create var that groups counties as (1) early (2) never or (3) late adopters
gen type = "Early" if early==1
	replace type = "Late" if late==1
	replace type = "Never" if never==1

collapse (max) sah_bc_both_start if type=="Never", by(state grp_fips county type)

export excel using "$path/Output/NPI adoption by state and county 10Dec20.xlsx", firstrow(variables) sheet("Never", modify) 


***
* Plots
***
use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

format date %tdMonth_dd

* Create var that groups counties as (1) early (2) never or (3) late adopters
gen type = 1 if early==1
	replace type = 2 if late==1
	replace type = 3 if never==1
tab type, m

*collapse type, by(grp_fips) // 78% early adopters, 12% late, 10% never

collapse (sum) covid_deaths covid_cases pop, by(date type)

* COVID deaths
twoway line covid_deaths date if type == 1, lstyle(color(blue)) mc(blue) lwidth(medthick) ///
		|| line covid_deaths date if type == 2, lstyle(color(orange)) mc(orange) lwidth(medthick) ///
		|| line covid_deaths date if type == 3, lstyle(color(gray)) mc(gray) lpatter(dash) lwidth(medthick) ///
		ytitle("COVID-19 Deaths", height(10)) ///
		xlabel(21960 21975 21989 22006 22020, labsize(3)) ///
		xtitle("Date", size(3) linegap(3)) ///
		leg(rows(1)) ysize(15) xsize(25) ///
		graphregion(color(white)) bgcolor(white) ///
		legend(label(1 "Early adopter") label(2 "Late adopter") label(3 "Never adopter") size(small) tstyle(nobox)) 
gr save "$path/Output/Plots/COVID deaths by NPI adoption.gph", replace
graph export "$path/Output/Plots/COVID deaths by NPI adoption.pdf", replace

* COVID deaths per capita
gen covid_deaths_pc = covid_deaths/pop*100000
twoway line covid_deaths_pc date if type == 1, lstyle(color(blue)) mc(blue) lwidth(medthick)  ///
		|| line covid_deaths_pc date if type == 2, lstyle(color(orange)) mc(orange) lwidth(medthick) ///
		|| line covid_deaths_pc date if type == 3, lstyle(color(gray)) mc(gray) lpatter(dash) lwidth(medthick) ///
		ytitle("COVID-19 Deaths per 100,000 Residents", height(10)) ///
		xlabel(21960 21975 21989 22006 22020, labsize(3)) ///
		xtitle("Date", size(3) linegap(3)) ///
		leg(rows(1)) ysize(15) xsize(25) ///
		graphregion(color(white)) bgcolor(white) ///
		legend(label(1 "Early adopter") label(2 "Late adopter") label(3 "Never adopter") size(small) tstyle(nobox)) 
gr save "$path/Output/Plots/COVID deaths per capita by NPI adoption.gph", replace
graph export "$path/Output/Plots/COVID deaths per capita by NPI adoption.pdf", replace

* COVID infections
twoway line covid_cases date if type == 1, lstyle(color(blue)) mc(blue) lwidth(medthick)  ///
		|| line covid_cases date if type == 2, lstyle(color(orange)) mc(orange) lwidth(medthick) ///
		|| line covid_cases date if type == 3, lstyle(color(gray)) mc(gray) lpatter(dash) lwidth(medthick) ///
		ytitle("COVID-19 Infections", height(10)) ///
		xlabel(21960 21975 21989 22006 22020, labsize(3)) ///
		xtitle("Date", size(3) linegap(3)) ///
		leg(rows(1)) ysize(15) xsize(25) ///
		graphregion(color(white)) bgcolor(white) ///
		legend(label(1 "Early adopter") label(2 "Late adopter") label(3 "Never adopter") size(small) tstyle(nobox)) 
gr save "$path/Output/Plots/COVID infections by NPI adoption.gph", replace
graph export "$path/Output/Plots/COVID infections by NPI adoption.pdf", replace

* COVID infections per capita
gen covid_cases_pc = covid_cases/pop*100000
twoway line covid_cases_pc date if type == 1, lstyle(color(blue)) mc(blue) lwidth(medthick)  ///
		|| line covid_cases_pc date if type == 2, lstyle(color(orange)) mc(orange) lwidth(medthick) ///
		|| line covid_cases_pc date if type == 3, lstyle(color(gray)) mc(gray) lpatter(dash) lwidth(medthick) ///
		ytitle("COVID-19 Infections per 100,000 Residents", height(10)) ///
		xlabel(21960 21975 21989 22006 22020, labsize(3)) ///
		xtitle("Date", size(3) linegap(3)) ///
		leg(rows(1)) ysize(15) xsize(25) ///
		graphregion(color(white)) bgcolor(white) ///
		legend(label(1 "Early adopter") label(2 "Late adopter") label(3 "Never adopter") size(small) tstyle(nobox)) 
gr save "$path/Output/Plots/COVID infections per capita by NPI adoption.gph", replace
graph export "$path/Output/Plots/COVID infections per capita by NPI adoption.pdf", replace

log close



