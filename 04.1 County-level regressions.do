****
* Setup
***
cd "/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Paper in JoPE/Data"
global path "/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Paper in JoPE"

cap log close
log using "$path/Logs/04.2.1 County-level regressions.log", replace

********************************************************************************
* COVID-19 project
* County-level regressions
* Created on: 12 May 2020
* Updated on: 10 Dec 2020
********************************************************************************

* Define regressors 
global dem pct_over65 pct_under18 pct_male pct_nohs pct_bachelorplus 
global ses pct_below_fpl pct_unemp pct_unins ln_med_income 
global health pcp_pc md_pc hosp_pc hosp_beds_pc chc_pc npc_pc  
global chronic copd asthma atrial_fib heart_failure ischemic_heart_disease cancer hypertension /*hiv_aids*/ diabetes chronic_kidney_diease /*hepatitis*/

* Define other NPI controls
global othernpis int_other_speed_dbl_both_lag14 /*int_mask_speed_dbl_both_lag14 int_res_speed_dbl_both_lag14 int_nh_speed_dbl_both_lag14 int_gym_speed_dbl_both_lag14 int_k12_speed_dbl_both_lag14*/

* Define state-level NPI controls
global stateothernpis int_other_speed_dbl_state_lag14 /*int_mask_speed_dbl_state_lag14 int_res_speed_dbl_state_lag14 int_nh_speed_dbl_state_lag14 int_gym_speed_dbl_state_lag14 int_k12_speed_dbl_state_lag14*/


** Update 26 June 2021
** Request for analytic file 
** Keeping only vars included in analysis
use working_county, clear

keep state county grp_fips date start_week state_fips pop state_pop covid_cases covid_cases_pc covid_deaths covid_deaths_pc state_total_deaths state_total_deaths_pc state_test_results state_test_results_pc sah_state_start sah_cnty_start bc_state_start bc_cnty_start other_both_start m50 pct_over65 rep_vote_share_2016 pct_unins pct_unemp pct_below_fpl comorbid_index pop_density

order state county grp_fips date start_week state_fips pop state_pop covid_cases covid_cases_pc covid_deaths covid_deaths_pc state_total_deaths state_total_deaths_pc state_test_results state_test_results_pc sah_state_start sah_cnty_start bc_state_start bc_cnty_start other_both_start m50 pct_over65 rep_vote_share_2016 pct_unins pct_unemp pct_below_fpl comorbid_index pop_density


label var other_both_start "Effective date of other county or state NPI"
label var pop_density "Population per square mile"
label var state_pop "State population (2018)"
label var pop "County population (2019)"

save COVIDcounty, replace


****
* Table 2: Main specification
****

use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Interpolating and extrapolating where mobility values are missing
sort grp_fips date
bys grp_fips: ipolate m50 date, gen(im50) epolate
replace im50 = . if date < date("20200301","YMD")
drop m50
ren im50 m50

egen miss = rmiss(m50)
bys grp_fips: egen nmiss = sum(miss)


* Main specification
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_2_main_results.xls", excel bdec(4) sdec(4) ctitle("SAH or BC: Baseline") label replace

* Control for testing
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_2_main_results.xls", excel se bdec(4) sdec(4) ctitle("SAH or BC: Control for testing") label append

* Control for other NPI speed
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_2_main_results.xls", excel se bdec(4) sdec(4) ctitle("SAH or BC: Control for other NPI speed") label append

* Control for mobillity
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis m50 if nmiss==15, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_2_main_results.xls", excel se bdec(4) sdec(4) ctitle("SAH or BC: Control for mobility") label append


****
* Table 3: Main specification (disaggregate SAH and BC)
****

* Main specification
reghdfe covid_deaths_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd) 
outreg2 using "$path/Output/Regressions/Table_3_main_results_disaggregated.xls", excel se bdec(4) sdec(4) title("Dependent variable: COVID deaths per 100K") ctitle("Baseline") label replace

* Control for testing
reghdfe covid_deaths_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14 state_test_results_pc, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_3_main_results_disaggregated.xls", excel se bdec(4) sdec(4) ctitle("Control for testing") label append

* Control for other NPIs
reghdfe covid_deaths_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14 state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd) 
outreg2 using "$path/Output/Regressions/Table_3_main_results_disaggregated.xls", excel se bdec(4) sdec(4) ctitle("Control for other NPIs") label append

* Wald test for equality of coefficients
test int_bc_speed_dbl_both_lag14=int_bc_speed_dbl_both_lag14


* Control for mobillity
reghdfe covid_deaths_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14 state_test_results_pc $othernpis m50 if nmiss==15, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_3_main_results_disaggregated.xls", excel se bdec(4) sdec(4) ctitle("Control for mobility") label append





****
* Table 4: Robustness checks
****

use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Separate estimates for SAH and BC

* #1: NPI speed alternative referencing pre-NPI national average
reghdfe covid_deaths_pc int_sah_bc_speed_nat_both_lag14 state_test_results_pc int_other_speed_nat_both_lag14, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_4_robustness_checks.xls", excel se bdec(4) sdec(4) title("Robustness checks") ctitle("Alt NPI speed #1") label replace

* #2: NPI speed alternative referencing pre-NPI county average
reghdfe covid_deaths_pc int_sah_bc_speed_cnty_both_lag14 state_test_results_pc int_other_speed_cnty_both_lag14, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_4_robustness_checks.xls", excel se bdec(4) sdec(4) ctitle("Alt NPI speed #2") label append

* #3: Population-weighted
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis [aw=pop], absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_4_robustness_checks.xls", excel se bdec(4) sdec(4) ctitle("Pop weighted baseline") label append

* #4: Exclude NY
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis if state !="New York", absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_4_robustness_checks.xls", excel se bdec(4) sdec(4) ctitle("Exclude NY") label append

* #5: Exclude NE region
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis if !inlist(state, "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont", "New Jersey", "New York", "Pennsylvania"), absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_4_robustness_checks.xls", excel se bdec(4) sdec(4) ctitle("Exclude NE region") label append
* NOTE: Mask control variable omitted because regions outside NE did not implement mask controls until 4/10 (which, with a 14 day lag puts covid deaths outside study window)

* #6: Only NE region
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis if inlist(state, "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont", "New Jersey", "New York", "Pennsylvania"), absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_4_robustness_checks.xls", excel se bdec(4) sdec(4) ctitle("Only NE region") label append



****
* Table 5: Exploring mechanisms
****

use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* #1: Preventing contagion
* Predict infection rates (control for testing at state level)
reghdfe covid_cases_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) title("Exploring mechanisms") ctitle("Contagion: COVID infections per 100K") label replace

* Exclude NY
reghdfe covid_cases_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis if state != "New York", absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: COVID infections per 100K (excl NY)") label append

* Exclude NE region
reghdfe covid_cases_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis if !inlist(state, "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont", "New Jersey", "New York", "Pennsylvania"), absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: COVID infections per 100K (excl NE region)") label append

* Predict state-level total deaths per capita using NPI speeds 
gen black = (pct_black/100) * pop
gen hisp = (pct_hisp/100) * pop

collapse (sum) covid_cases covid_deaths black hisp state_test_results, by(start_week state state_total_deaths state_pop sah_state_start bc_state_start sah_bc_state_start res_state_start k12_state_start mask_state_start nh_state_start gym_state_start other_state_start $otherstatenpis)
* 550 (50 states and 11 weeks)

* Need to create state-level NPI speed measures (use first week-to-week doubling as reference point)
sort state start_week
gen covid_cases_pc = covid_cases/state_pop
bys state: gen case_pc_change = covid_cases_pc/covid_cases_pc[_n-1]
*br state start_week covid_cases* covid_cases_pc case_pc_change

* Create indicator for first week when case rates were 2x previous day
gen cases_doubled = (case_pc_change > 2 & !missing(case_pc_change))
gen week_cases_doubled_ = start_week if cases_doubled==1
bys state: egen week_cases_doubled = min(week_cases_doubled_)
* all states had a week when cases pc doubled
format week_cases_doubled %td

* Multiplying number by (-1) so higher values indicate faster response
foreach npi in sah bc sah_bc res k12 mask nh gym other {
gen `npi'_speed_dbl_state = (`npi'_state_start - week_cases_doubled)*-1
	replace `npi'_speed_dbl_state = (22028 - week_cases_doubled)*-1 if missing(`npi'_state_start)
	replace `npi'_speed_dbl_state = 0 if missing(week_cases_doubled)
}

drop *doubled* case_pc_change

* Create interactions
foreach t in 14 {
foreach npi in sah bc sah_bc res k12 mask nh gym other {

gen `npi'_state_lag`t' = 0
	replace `npi'_state_lag`t' = 1 if start_week > (`npi'_state_start + `t') & !missing(`npi'_state_start)

gen int_`npi'_speed_dbl_state_lag`t' = `npi'_state_lag`t'*`npi'_speed_dbl_state
label var int_`npi'_speed_dbl_state "State `npi' (14 day lag) x # days btwn `npi' and 1st week-to-week infection doubling"
}
}

* Create variable that captures state-level non-COVID deaths
gen state_nonCOVID_deaths_pc = (state_total_deaths-covid_deaths)/state_pop*100000
gen state_test_results_pc=state_test_results/state_pop*100000

save working_county_state, replace

* Non-COVID deaths
reghdfe state_nonCOVID_deaths_pc int_sah_bc_speed_dbl_state_lag14 state_test_results_pc $stateothernpis, absorb(start_week state) keepsing vce(cluster state) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: non-COVID deaths in state") label append

* Non-COVID deaths (exclude NY)
reghdfe state_nonCOVID_deaths_pc int_sah_bc_speed_dbl_state_lag14 state_test_results_pc $stateothernpis if state != "New York", absorb(start_week state) keepsing vce(cluster state) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: non-COVID deaths in state (excl NY)") label append

* Non-COVID deaths (exclude NE region)
reghdfe state_nonCOVID_deaths_pc int_sah_bc_speed_dbl_state_lag14 state_test_results_pc $stateothernpis if !inlist(state, "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont", "New Jersey", "New York", "Pennsylvania"), absorb(start_week state) keepsing vce(cluster state) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: non-COVID deaths in state (excl NE region)") label append


* #2: Compliance
use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Interpolating and extrapolating where mobility values are missing
sort grp_fips date
bys grp_fips: ipolate m50 date, gen(im50) epolate
replace im50 = . if date < 21975
drop m50
ren im50 m50

egen miss = rmiss(m50)
bys grp_fips: egen nmiss = sum(miss)

reghdfe m50 int_sah_bc_speed_dbl_both $othernpis if nmiss==15, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Compliance: Mobility") label append

reghdfe m_res_nomiss int_sah_bc_speed_dbl_both $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Compliance: Google residental mobility") label append

reghdfe m_work_nomiss int_sah_bc_speed_dbl_both $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Compliance: Google work mobility") label append


****
* Table 6: Heterogenous effects
***

use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* SAH or BC

* Republican vs non-republican counties
gen int_sah_bc_speed_dbl_both_r = int_sah_bc_speed_dbl_both_lag14*rep
label var int_sah_bc_speed_dbl_both_r "Majority Republican x SAH or BC (14 day lag) x # days btwn NPI & 1st infection doubling"

reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 int_sah_bc_speed_dbl_both_r state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_6_heterogeneous_effects.xls", excel se bdec(4) sdec(4) title("Heterogenous effects (DV: COVID deaths per 100K)") ctitle("Majority Republican") label replace

* Elderly share
gen int_sah_bc_speed_dbl_both_e = int_sah_bc_speed_dbl_both_lag14*pct_over65
label var int_sah_bc_speed_dbl_both_e "Pct over 65 x SAH or BC (14 day lag)x # days btwn NPI & 1st infection doubling"

reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 int_sah_bc_speed_dbl_both_e state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_6_heterogeneous_effects.xls", excel se bdec(4) sdec(4) ctitle("Elderly") label append

* Uninsured
gen int_sah_bc_speed_dbl_both_u=  int_sah_bc_speed_dbl_both_lag14*pct_unins
label var int_sah_bc_speed_dbl_both_u "Pct uninsured x SAH or BC (14 day lag) x # days btwn NPI & 1st infection doubling"

reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 int_sah_bc_speed_dbl_both_u state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_6_heterogeneous_effects.xls", excel se bdec(4) sdec(4) ctitle("Uninsured") label append

* Unemployed
gen int_sah_bc_speed_dbl_both_une=  int_sah_bc_speed_dbl_both_lag14*pct_unemp
label var int_sah_bc_speed_dbl_both_une "Pct unemployed x SAH or BC (14 day lag) x # days btwn NPI & 1st infection doubling"

reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 int_sah_bc_speed_dbl_both_une state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips)  summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_6_heterogeneous_effects.xls", excel se bdec(4) sdec(4) ctitle("Unemployed") label append

* Poverty
gen int_sah_bc_speed_dbl_both_p=  int_sah_bc_speed_dbl_both_lag14*pct_below_fpl
label var int_sah_bc_speed_dbl_both_p "Pct below FPL x SAH or BC (14 day lag) x # days btwn NPI & 1st infection doubling"

reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 int_sah_bc_speed_dbl_both_p state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips)  summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_6_heterogeneous_effects.xls", excel se bdec(4) sdec(4) ctitle("Poverty") label append

* Comorbities
* Create mean comorbities index
gen int_sah_bc_speed_dbl_both_c=  int_sah_bc_speed_dbl_both_lag14*comorbid_index
label var int_sah_bc_speed_dbl_both_c "Comorbity index x SAH or BC (14 day lag) x # days btwn NPI & 1st infection doubling"

reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 int_sah_bc_speed_dbl_both_c state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips)  summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_6_heterogeneous_effects.xls", excel se bdec(4) sdec(4) ctitle("Comorbity") label append

* Population density
gen int_sah_bc_speed_dbl_both_pd = int_sah_bc_speed_dbl_both_lag14*pop_density
label var int_sah_bc_speed_dbl_both_pd "Population per sq mi x SAH or BC (14 day lag) x # days btwn NPI & 1st infection doubling"

reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 int_sah_bc_speed_dbl_both_pd state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_6_heterogeneous_effects.xls", excel se bdec(4) sdec(4) ctitle("Population density") label append


****
* Appendix Table A: Robustness checks with disaggregated SAH and BC
****

use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* #1: NPI speed alternative referencing pre-NPI national average
reghdfe covid_deaths_pc int_sah_speed_nat_both_lag14 int_bc_speed_nat_both_lag14 int_other_speed_dbl_both_lag14 state_test_results_pc, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_A_robustness_checks.xls", excel se bdec(4) sdec(4) ctitle("SAH or BC: Alt NPI speed #1") label replace

* #2: NPI speed alternative referencing pre-NPI county average
reghdfe covid_deaths_pc int_sah_speed_cnty_both_lag14 int_bc_speed_cnty_both_lag14 int_other_speed_dbl_both_lag14 state_test_results_pc, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_A_robustness_checks.xls", excel se bdec(4) sdec(4) ctitle("SAH or BC: Alt NPI speed #2") label append

* #3: Population-weighted
reghdfe covid_deaths_pc int_sah_speed_dbl_both_lag14 int_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis [aw=pop], absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_A_robustness_checks.xls", excel se bdec(4) sdec(4) ctitle("SAH or BC: Pop weighted baseline") label append

* #4: Exclude NY
reghdfe covid_deaths_pc int_sah_speed_dbl_both_lag14 int_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis if state !="New York", absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_A_robustness_checks.xls", excel se bdec(4) sdec(4) ctitle("SAH or BC: Exclude NY") label append

* #5: Exclude NE region
reghdfe covid_deaths_pc int_sah_speed_dbl_both_lag14 int_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis if !inlist(state, "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont", "New Jersey", "New York", "Pennsylvania"), absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_A_robustness_checks.xls", excel se bdec(4) sdec(4) ctitle("SAH or BC: Exclude NE region") label append

* #6: Only NE region
reghdfe covid_deaths_pc int_sah_speed_dbl_both_lag14 int_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis if inlist(state, "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont", "New Jersey", "New York", "Pennsylvania"), absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_A_robustness_checks.xls", excel se bdec(4) sdec(4) ctitle("SAH or BC: Only NE region") label append



****
* Appendix Table B: Exploring mechanisms with disaggregated SAH and BC
****

use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* #1: Preventing contagion
* Predict infection rates (control for testing at state level)
reghdfe covid_cases_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14 state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) title("Exploring mechanisms") ctitle("Contagion: COVID infections per 100K") label replace

* Exclude NY
reghdfe covid_cases_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14 state_test_results_pc $othernpis if state != "New York", absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: COVID infections per 100K (excl NY)") label append

* Exclude NE region
reghdfe covid_cases_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14 state_test_results_pc $othernpis if !inlist(state, "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont", "New Jersey", "New York", "Pennsylvania"), absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: COVID infections per 100K (excl NE region)") label append


use working_county_state, clear

* Non-COVID deaths
reghdfe state_nonCOVID_deaths_pc int_bc_speed_dbl_state_lag14 int_sah_speed_dbl_state_lag14 state_test_results_pc $stateothernpis, absorb(start_week state) keepsing vce(cluster state) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: non-COVID deaths in state") label append

* Non-COVID deaths (exclude NY)
reghdfe state_nonCOVID_deaths_pc int_bc_speed_dbl_state_lag14 int_sah_speed_dbl_state_lag14  state_test_results_pc $stateothernpis if state != "New York", absorb(start_week state) keepsing vce(cluster state) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: non-COVID deaths in state (excl NY)") label append

* Non-COVID deaths (exclude NE region)
reghdfe state_nonCOVID_deaths_pc int_bc_speed_dbl_state_lag14 int_sah_speed_dbl_state_lag14  state_test_results_pc $stateothernpis if !inlist(state, "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont", "New Jersey", "New York", "Pennsylvania"), absorb(start_week state) keepsing vce(cluster state) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: non-COVID deaths in state (excl NE region)") label append


* #2: Compliance
use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Interpolating and extrapolating where mobility values are missing
sort grp_fips date
bys grp_fips: ipolate m50 date, gen(im50) epolate
replace im50 = . if date < date("20200301","YMD")
drop m50
ren im50 m50

egen miss = rmiss(m50)
bys grp_fips: egen nmiss = sum(miss)

reghdfe m50 int_sah_speed_dbl_both int_bc_speed_dbl_both $othernpis if nmiss==15, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Compliance: Mobility") label append

reghdfe m_res_nomiss int_sah_speed_dbl_both int_bc_speed_dbl_both $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Compliance: Google residental mobility") label append

reghdfe m_work_nomiss int_sah_speed_dbl_both int_bc_speed_dbl_both $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Compliance: Google work mobility") label append



*****
* Appendix Table C: Restricted sample and alternative specification
*****

use working_county, clear

* Restrict sample to period from with mobility data
drop if date < date("20200301","YMD")
drop if date > date("20200423","YMD")

* Interpolating and extrapolating where mobility values are missing
sort grp_fips date
bys grp_fips: ipolate m50 date, gen(im50) epolate
replace im50 = . if date < date("20200301","YMD")
drop m50
ren im50 m50

egen miss = rmiss(m50)
bys grp_fips: egen nmiss = sum(miss)
drop if nmiss != 0 

* Panel A: SAH or BC

* Main specification
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_C_alt_models.xls", excel bdec(4) sdec(4) ctitle("Panel A: Restricted sample (SAH or BC)") label replace

* Control for testing
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_C_alt_models.xls", excel se bdec(4) sdec(4) ctitle("Panel A: Control for testing") label append

* Control for other NPI speed
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_C_alt_models.xls", excel se bdec(4) sdec(4) ctitle("Panel A: Control for other NPI speed") label append

* Control for mobillity
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis m50, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_C_alt_models.xls", excel se bdec(4) sdec(4) ctitle("Panel A: Control for mobility") label append


* Panel B: Disaggregte SAH and BC
* Main specification
reghdfe covid_deaths_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14 , absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_C_alt_models.xls", excel bdec(4) sdec(4) ctitle("Panel B: Restricted sample (SAH and BC)") label append

* Control for testing
reghdfe covid_deaths_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14  state_test_results_pc, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_C_alt_models.xls", excel se bdec(4) sdec(4) ctitle("Panel B: Control for testing") label append

* Control for other NPI speed
reghdfe covid_deaths_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14  state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_C_alt_models.xls", excel se bdec(4) sdec(4) ctitle("Panel B: Control for other NPI speed") label append

* Control for mobillity
reghdfe covid_deaths_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14  state_test_results_pc $othernpis m50, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_C_alt_models.xls", excel se bdec(4) sdec(4) ctitle("Panel B: Control for mobility") label append


* Panel C: SAH, BC, and both SAH and BC
use working_county, clear

* Restrict sample to study period
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Interpolating and extrapolating where mobility values are missing
sort grp_fips date
bys grp_fips: ipolate m50 date, gen(im50) epolate
replace im50 = . if date < date("20200301","YMD")
drop m50
ren im50 m50

egen miss = rmiss(m50)
bys grp_fips: egen nmiss = sum(miss)

* Create mutually exclusive speed terms (only SAH and only BC)
gen bc_only = (missing(sah_both_start) & !missing(bc_both_start))
gen int_o_bc_speed_dbl_both_lag14 = int_bc_speed_dbl_both_lag14*bc_only
tab bc_both_start bc_only if missing(sah_both_start), m

gen bc_only_test = bc_only*bc_both_lag14

gen sah_only = (!missing(sah_both_start) & missing(bc_both_start))
gen int_o_sah_speed_dbl_both_lag14 = int_sah_speed_dbl_both_lag14*sah_only
tab sah_both_start sah_only if missing(bc_both_start), m

gen sah_only_test = sah_only*sah_both_lag14

collapse (max) sah_only_test bc_only_test sah_bc_both, by(grp_fips)


* Add labels
foreach npi in sah bc {
label var int_o_`npi'_speed_dbl_both_lag14 "Only `npi' x # days btwn `npi' and 1st day-to-day infection doubling"
}

* Main specification
reghdfe covid_deaths_pc int_o_bc_speed_dbl_both_lag14 int_o_sah_speed_dbl_both_lag14 int_cmbd_speed_dbl_both_lag14, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_C_alt_models.xls", excel bdec(4) sdec(4) ctitle("Panel C: Only SAH vs only BC vs both") label append

* Control for testing
reghdfe covid_deaths_pc int_o_bc_speed_dbl_both_lag14 int_o_sah_speed_dbl_both_lag14 int_cmbd_speed_dbl_both_lag14 state_test_results_pc, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_C_alt_models.xls", excel se bdec(4) sdec(4) ctitle("Panel C: Control for testing") label append

* Control for other NPI speed
reghdfe covid_deaths_pc int_o_bc_speed_dbl_both_lag14 int_o_sah_speed_dbl_both_lag14 int_cmbd_speed_dbl_both_lag14 state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_C_alt_models.xls", excel se bdec(4) sdec(4) ctitle("Panel C: Control for other NPI speed") label append

* Control for mobillity
reghdfe covid_deaths_pc int_o_bc_speed_dbl_both_lag14 int_o_sah_speed_dbl_both_lag14 int_cmbd_speed_dbl_both_lag14 state_test_results_pc $othernpis m50 if nmiss==15, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_C_alt_models.xls", excel se bdec(4) sdec(4) ctitle("Panel C: Control for mobility") label append




*****
* Appendix Table D: Alternate lags
*****

use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Interpolating and extrapolating where mobility values are missing
sort grp_fips date
bys grp_fips: ipolate m50 date, gen(im50) epolate
replace im50 = . if date < date("20200301","YMD")
drop m50
ren im50 m50

egen miss = rmiss(m50)
bys grp_fips: egen nmiss = sum(miss)

* At least one (SAH and BC)
foreach t in 1 5 10 14 {

global othernpis int_mask_speed_dbl_both_lag`t' /*int_res_speed_dbl_both_lag`t' int_nh_speed_dbl_both_lag`t' int_gym_speed_dbl_both_lag`t'*/

* Main specification
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag`t', absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_D_alternate_lags.xls", excel bdec(4) sdec(4) ctitle("Baseline: `t'-day lag") label append

* Control for testing
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag`t' state_test_results_pc, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_D_alternate_lags.xls", excel se bdec(4) sdec(4) ctitle("Control for testing: `t'-day lag") label append

* Control for other NPIs
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag`t' state_test_results_pc int_other_speed_dbl_both_lag`t', absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_D_alternate_lags.xls", excel se bdec(4) sdec(4) ctitle("Control for other NPI speed: `t'-day lag") label append

* Control for mobillity
reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag`t' state_test_results_pc int_other_speed_dbl_both_lag`t' m50 if nmiss==15, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_D_alternate_lags.xls", excel se bdec(4) sdec(4) ctitle("Control for mobility: `t'-day lag") label append

}


****
* Appendix Table E: Republican vote share heterogenous effects
****

use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Creating vote share categories for more nuanced heterogenous effect analysis
/*foreach pctl in 20 40 60 80 100  {
gen rep`pctl' = (rep_vote_share_2016<`pctl' & rep_vote_share_2016>=`pctl'-20)
	replace rep`pctl'= . if missing(rep_vote_share_2016)

tabstat rep_vote_share_2016, s(N mean min median max) by(rep`pctl')

gen int_sah_bc_speed_dbl_both_r`pctl' = int_sah_bc_speed_dbl_both_lag14*rep`pctl'
label var int_sah_bc_speed_dbl_both_r`pctl' "Republican (`pctl'%)'x SAH or BC (14 day lag) x # days btwn NPI & 1st infection doubling"
}
*/
foreach pctl in 40 100  {
gen rep`pctl' = (rep_vote_share_2016<`pctl' & rep_vote_share_2016>=`pctl'-40)
	replace rep`pctl'= . if missing(rep_vote_share_2016)

tabstat rep_vote_share_2016, s(N mean min median max) by(rep`pctl')

gen int_sah_bc_speed_dbl_both_r`pctl' = int_sah_bc_speed_dbl_both_lag14*rep`pctl'
label var int_sah_bc_speed_dbl_both_r`pctl' "Republican (`pctl'%)'x SAH or BC (14 day lag) x # days btwn NPI & 1st infection doubling"
}

* SAH or BC

reghdfe covid_deaths_pc int_sah_bc_speed_dbl_both_lag14 int_sah_bc_speed_dbl_both_r40 int_sah_bc_speed_dbl_both_r100 state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_E_heterogeneous_effects.xls", excel se bdec(4) sdec(4) title("Heterogenous effects (DV: COVID deaths per 100K)") ctitle("Republican vote share") label replace


/*
****
* Appendix Table F: Identification checks
****

* Event study plots created in "04.2.2 County-level event study.do"

use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Interpolating and extrapolating where mobility values are missing
sort grp_fips date
bys grp_fips: ipolate m50 date, gen(im50) epolate
replace im50 = . if date < 21975
drop m50
ren im50 m50

egen miss = rmiss(m50)
bys grp_fips: egen nmiss = sum(miss)

* Model deaths as a function of mobility
reghdfe covid_deaths_pc m50 state_test_results_pc if nmiss==15, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_E_identification_checks.xls", excel se bdec(4) sdec(4) title("Indentification checks") ctitle("DV: COVID deaths per 100K") label replace

* Model cases as a function of mobility
reghdfe covid_cases_pc m50 state_test_results_pc if nmiss==15, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_E_identification_checks.xls", excel se bdec(4) sdec(4) title("Indentification checks") ctitle("DV: COVID cases per 100K") label append

* Model NPI speed using county characteristics
use working_county, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Creating vote share categories for more nuanced heterogenous effect analysis
gen rep50 = (rep_vote_share_2016<50)
	replace rep50 = . if missing(rep_vote_share_2016)

foreach pctl in 60 70 80 {
gen rep`pctl' = (rep_vote_share_2016<`pctl' & rep_vote_share_2016>=`pctl'-10)
	replace rep`pctl'= . if missing(rep_vote_share_2016)

tabstat rep_vote_share_2016, s(N mean min median max) by(rep`pctl')
}
gen rep100 = (rep_vote_share_2016<100 & rep_vote_share_2016>=80)
	replace rep100 = . if missing(rep_vote_share_2016)

* County characteristics
local chars pop pcp_pc hosp_pc hosp_beds_pc chc_pc md_pc copd asthma atrial_fib heart_failure ischemic_heart_disease cancer hypertension hiv_aids diabetes chronic_kidney_diease hepatitis pct_noncit pct_fb pct_white pct_black pct_hisp pct_asian pct_below_fpl pct_over65 pct_under18 pct_unemp pct_unins pct_male pct_nohs pct_bachelorplus /*rep_vote_share_2016*/ rep50 rep60 rep70 rep80 rep100 pop_density

collapse sah_bc_speed_dbl_both sah_speed_dbl_both bc_speed_dbl_both (sum) covid_deaths covid_cases, by(grp_fips state `chars' sah_both bc_both sah_bc_both)

* Create mean comorbities index
egen comorbid_mean = rowtotal(copd asthma atrial_fib heart_failure ischemic_heart_disease cancer hypertension hiv_aids diabetes chronic_kidney_diease hepatitis)
sum comorbid_mean, d
gen comorbid_index = (comorbid_mean - `r(mean)')/`r(sd)'

label var comorbid_index "Comorbity index N(0,1)"

* Create minority percent
gen pct_minority = 100 - pct_white
label var pct_minority "Pct non-white (2018)"

gen covid_deaths_pc = covid_deaths/pop*100000
gen covid_cases_pc = covid_cases/pop*100000

drop if sah_bc_both == 1

reg sah_speed_dbl_both rep50 rep60 rep70 rep80 rep100 pct_over65 pct_unins pct_unemp pct_below_fpl comorbid_index covid_deaths_pc pop_density,  vce(cluster grp_fips)
outreg2 using "$path/Output/Regressions/Appendix_Table_E_identification_checks.xls", excel se bdec(3) sdec(3) ctitle("DV: SAH speed") label append

reg bc_speed_dbl_both rep50 rep60 rep70 rep80 rep100 pct_over65 pct_unins pct_unemp pct_below_fpl comorbid_index covid_deaths_pc pop_density,  vce(cluster grp_fips)  
outreg2 using "$path/Output/Regressions/Appendix_Table_E_identification_checks.xls", excel se bdec(3) sdec(3) ctitle("DV: BC speed") label append

reg sah_bc_speed_dbl_both rep50 rep60 rep70 rep80 rep100 pct_over65 pct_unins pct_unemp pct_below_fpl comorbid_index covid_deaths_pc pop_density,  vce(cluster grp_fips)   
outreg2 using "$path/Output/Regressions/Appendix_Table_E_identification_checks.xls", excel se bdec(3) sdec(3) ctitle("DV: SAH or BC speed") label append
*/

log close





