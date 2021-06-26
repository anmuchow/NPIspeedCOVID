****
* Setup
***
cd "/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Paper in JoPE/Github repo/Data"
global path "/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Paper in JoPE/Github repo"

cap log close
log using "$path/Logs/04 Regressions and event study.log", replace

********************************************************************************
* COVID-19 project
* County-level regressions
* Created on: 12 May 2020
* Updated on: 10 Dec 2020
********************************************************************************

* Globals
* Define other NPI controls
global othernpis int_other_speed_dbl_both_lag14
* Define state-level NPI controls
global stateothernpis int_other_speed_dbl_state_lag14


****
* Table 2: Main specification
****

use COVIDcounty, clear

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

use COVIDcounty, clear

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

use COVIDcounty, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* #1: Stemming contagion
* Predict infection rates (control for testing at state level)
reghdfe covid_cases_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) title("Exploring mechanisms") ctitle("Contagion: COVID infections per 100K") label replace

* Exclude NY
reghdfe covid_cases_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis if state != "New York", absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: COVID infections per 100K (excl NY)") label append

* Exclude NE region
reghdfe covid_cases_pc int_sah_bc_speed_dbl_both_lag14 state_test_results_pc $othernpis if !inlist(state, "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont", "New Jersey", "New York", "Pennsylvania"), absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: COVID infections per 100K (excl NE region)") label append


* #2: Preventing overwhelmed healthcare system
* Predict state-level total deaths per capita using NPI speeds 
gen black = (pct_black/100) * pop
gen hisp = (pct_hisp/100) * pop

collapse (sum) covid_cases covid_deaths black hisp state_test_results, by(start_week state state_total_deaths state_pop sah_state_start bc_state_start sah_bc_state_start other_state_start $otherstatenpis)
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
foreach npi in sah bc sah_bc other {
gen `npi'_speed_dbl_state = (`npi'_state_start - week_cases_doubled)*-1
	replace `npi'_speed_dbl_state = (22028 - week_cases_doubled)*-1 if missing(`npi'_state_start)
	replace `npi'_speed_dbl_state = 0 if missing(week_cases_doubled)
}

drop *doubled* case_pc_change

* Create interactions
foreach t in 14 {
foreach npi in sah bc sah_bc other {

gen `npi'_state_lag`t' = 0
	replace `npi'_state_lag`t' = 1 if start_week > (`npi'_state_start + `t') & !missing(`npi'_state_start)

gen int_`npi'_speed_dbl_state_lag`t' = `npi'_state_lag`t'*`npi'_speed_dbl_state
label var int_`npi'_speed_dbl_state "State `npi' (14 day lag) x # days btwn `npi' and 1st week-to-week infection doubling"
}
}

* Create variable that captures state-level non-COVID deaths
gen state_nonCOVID_deaths_pc = (state_total_deaths-covid_deaths)/state_pop*100000
gen state_test_results_pc=state_test_results/state_pop*100000

save COVIDstate, replace

* Non-COVID deaths
reghdfe state_nonCOVID_deaths_pc int_sah_bc_speed_dbl_state_lag14 state_test_results_pc $stateothernpis, absorb(start_week state) keepsing vce(cluster state) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: non-COVID deaths in state") label append

* Non-COVID deaths (exclude NY)
reghdfe state_nonCOVID_deaths_pc int_sah_bc_speed_dbl_state_lag14 state_test_results_pc $stateothernpis if state != "New York", absorb(start_week state) keepsing vce(cluster state) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: non-COVID deaths in state (excl NY)") label append

* Non-COVID deaths (exclude NE region)
reghdfe state_nonCOVID_deaths_pc int_sah_bc_speed_dbl_state_lag14 state_test_results_pc $stateothernpis if !inlist(state, "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont", "New Jersey", "New York", "Pennsylvania"), absorb(start_week state) keepsing vce(cluster state) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Table_5_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: non-COVID deaths in state (excl NE region)") label append


****
* Table 6: Heterogenous effects
***

use COVIDcounty, clear

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

use COVIDcounty, clear

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

use COVIDcounty, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* #1: Stemming contagion
* Predict infection rates (control for testing at state level)
reghdfe covid_cases_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14 state_test_results_pc $othernpis, absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) title("Exploring mechanisms") ctitle("Contagion: COVID infections per 100K") label replace

* Exclude NY
reghdfe covid_cases_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14 state_test_results_pc $othernpis if state != "New York", absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: COVID infections per 100K (excl NY)") label append

* Exclude NE region
reghdfe covid_cases_pc int_bc_speed_dbl_both_lag14 int_sah_speed_dbl_both_lag14 state_test_results_pc $othernpis if !inlist(state, "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont", "New Jersey", "New York", "Pennsylvania"), absorb(date grp_fips) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: COVID infections per 100K (excl NE region)") label append


* #2: Preventing overwhelmed healthcare system
use COVIDstate, clear

* Non-COVID deaths
reghdfe state_nonCOVID_deaths_pc int_bc_speed_dbl_state_lag14 int_sah_speed_dbl_state_lag14 state_test_results_pc $stateothernpis, absorb(start_week state) keepsing vce(cluster state) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: non-COVID deaths in state") label append

* Non-COVID deaths (exclude NY)
reghdfe state_nonCOVID_deaths_pc int_bc_speed_dbl_state_lag14 int_sah_speed_dbl_state_lag14  state_test_results_pc $stateothernpis if state != "New York", absorb(start_week state) keepsing vce(cluster state) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: non-COVID deaths in state (excl NY)") label append

* Non-COVID deaths (exclude NE region)
reghdfe state_nonCOVID_deaths_pc int_bc_speed_dbl_state_lag14 int_sah_speed_dbl_state_lag14  state_test_results_pc $stateothernpis if !inlist(state, "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont", "New Jersey", "New York", "Pennsylvania"), absorb(start_week state) keepsing vce(cluster state) summarize(mean sd)
outreg2 using "$path/Output/Regressions/Appendix_Table_B_exploring_mechanisms.xls", excel se bdec(4) sdec(4) ctitle("Contagion: non-COVID deaths in state (excl NE region)") label append


*****
* Appendix Table C: Restricted sample and alternative specification
*****

use COVIDcounty, clear

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
use COVIDcounty, clear

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

use COVIDcounty, clear

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

use COVIDcounty, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Creating vote share categories for more nuanced heterogenous effect analysis
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



****
* Identification checks
****

use COVIDcounty, clear

* Figure 4: Event study
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
tab nmiss

* Create dummy that captures when SAH and BC ended
gen sah_bc_both_end = (date >= sah_state_end & date >= bc_state_end)

* Create dummies for time periods
* Create dummies
gen  t0=(date==sah_bc_both_start) & !missing(sah_bc_both_start)

		foreach n in 3 7 10 14 17 21 24 28 31 35 38 {
		bys grp_fips date: gen byte timebefore`n'=(date==sah_bc_both_start -`n' & !missing(sah_bc_both_start))
		}

		foreach n in 3 7 10 14 17 21 24 28 31 35 38 {
		bys grp_fips date: gen byte timeafter`n'=(date==sah_bc_both_start +`n' & !missing(sah_bc_both_start))
		}

* Estimate coefs
local spec1 timebefore35 timebefore28 timebefore21 timebefore14 timebefore7 t0 timeafter7 timeafter14 timeafter21 timeafter28 timeafter35
 
local spec2 timebefore35 timebefore31 timebefore28 timebefore24 timebefore21 timebefore17 timebefore14 timebefore10 timebefore7 timebefore3 t0 timeafter3 timeafter7 timeafter10 timeafter14 timeafter17 timeafter21 timeafter24 timeafter28 timeafter31 timeafter35

* Identification Check #1: DV = COVID deaths per capita
reghdfe covid_deaths_pc state_test_results_pc int_other_speed_dbl_both_lag14 m50 `spec2' if nmiss==15, absorb(i.grp_fips i.date) keepsing vce(cluster i.grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Event study/id_any_check_event_study.xls", keep(`spec2') se bdec(3) excel ctitle("Effect of NPIs on COVID-19 deaths per capita") ti(Dependent Variable: Event Study) label replace

est sto mp
		
  			*draw graph
			coefplot, keep(`spec2') ///
					coeflabels(timebefore35 = "-35" ///
							   timebefore31 = " " ///
							   timebefore28 = "-28" ///
							   timebefore24 = " " ///
							   timebefore21 = "-21" ///
							   timebefore17 = " " ///
							   timebefore14 = "-14" ///
							   timebefore10 = " " ///
							   timebefore7 = "-7" ///
							   timebefore3 = " " ///
							   t0 = "0" ///
							   timeafter3 = " " ///
							   timeafter7 = "+7" ///
							   timeafter10 = " " ///
							   timeafter14 = "+14" ///
							   timeafter17 = " " ///
							   timeafter21 = "+21" ///
							   timeafter24 = " " ///
							   timeafter28 = "+28" ///
							   timeafter31 = " " ///
							   timeafter35 = "+35") ///  
					vertical 							 ///
					yline(0)							 ///
					/*xline(5.5, lpattern(dash))*/ 			///
					ytitle("Effect of NPIs on COVID-19 deaths per capita")				///
					xtitle("Days since the adoption of first NPI") ///
					addplot(line @b @at)				///
					ciopts(recast(rcap))				///
					/*rescale(100)*/						///
					scheme(s1mono)

					graph export "$path/Output/Event study/id_check_any_event_study.png", replace


					
* Figure A: Supplementary analysis excluding counties that adopted SAH/BC before March 26
use COVIDcounty, clear

* Restrict sample to period from 2/15 to 4/23 (first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")

* Drop counties that adopted before March 26
drop if sah_bc_both_start < date("20200326","YMD")

* Interpolating and extrapolating where mobility values are missing
sort grp_fips date
bys grp_fips: ipolate m50 date, gen(im50) epolate
replace im50 = . if date < date("20200301","YMD")
drop m50
ren im50 m50

egen miss = rmiss(m50)
bys grp_fips: egen nmiss = sum(miss)
tab nmiss

* Create dummy that captures when SAH and BC ended
gen sah_bc_both_end = (date >= sah_state_end & date >= bc_state_end)


* Create dummies
gen  t0=(date==sah_bc_both_start) & !missing(sah_bc_both_start)

		foreach n in 3 7 10 14 17 21 24 28 31 35 38 {
		bys grp_fips date: gen byte timebefore`n'=(date==sah_bc_both_start -`n' & !missing(sah_bc_both_start))
		}

		foreach n in 3 7 10 14 17 21 24 28 31 35 38 {
		bys grp_fips date: gen byte timeafter`n'=(date==sah_bc_both_start +`n' & !missing(sah_bc_both_start))
		}

* Estimate coefs
local spec1 timebefore35 timebefore28 timebefore21 timebefore14 timebefore7 t0 timeafter7 timeafter14 timeafter21 timeafter28 timeafter35 
 
local spec2 timebefore35 timebefore31 timebefore28 timebefore24 timebefore21 timebefore17 timebefore14 timebefore10 timebefore7 timebefore3 t0 timeafter3 timeafter7 timeafter10 timeafter14 timeafter17 timeafter21 timeafter24 timeafter28 timeafter31 timeafter35

* Identification Check #1: DV = COVID deaths per capita
reghdfe covid_deaths_pc state_test_results_pc int_other_speed_dbl_both_lag14 m50 `spec2' if nmiss==15, absorb(i.grp_fips i.date) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Event study/id_any_check_event_study_appendix.xls", keep(`spec2') se bdec(3) excel ctitle("Effect of NPIs on COVID-19 deaths per capita") ti(Dependent Variable: Event Study) label replace

est sto mp
		
  			*draw graph
			coefplot, keep(`spec2') ///
					coeflabels(timebefore35 = "-35" ///
							   timebefore31 = " " ///
							   timebefore28 = "-28" ///
							   timebefore24 = " " ///
							   timebefore21 = "-21" ///
							   timebefore17 = " " ///
							   timebefore14 = "-14" ///
							   timebefore10 = " " ///
							   timebefore7 = "-7" ///
							   timebefore3 = " " ///
							   t0 = "0" ///
							   timeafter3 = " " ///
							   timeafter7 = "+7" ///
							   timeafter10 = " " ///
							   timeafter14 = "+14" ///
							   timeafter17 = " " ///
							   timeafter21 = "+21" ///
							   timeafter24 = " " ///
							   timeafter28 = "+28" ///
							   timeafter31 = " " ///
							   timeafter35 = "+35") ///  
					vertical 							 ///
					yline(0)							 ///
					/*xline(5.5, lpattern(dash))*/ 			///
					ytitle("Effect of NPIs on COVID-19 deaths per capita")				///
					xtitle("Days since the adoption of first NPI") ///
					addplot(line @b @at)				///
					ciopts(recast(rcap))				///
					/*rescale(100)*/						///
					scheme(s1mono)

					graph export "$path/Output/Event study/id_any_check_event_study_appendix.png", replace
			
log close





