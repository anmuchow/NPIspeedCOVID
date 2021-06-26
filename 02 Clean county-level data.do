****
* Setup
***
cd "/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Data"
global path "/Users/amuchow/Dropbox/Caty&Neeraj&Ashley"

cap log close
log using "$path/Logs/02.2 Clean county-level data.log", replace

********************************************************************************
* COVID-19 project
* Prepare county-level data for analysis
* Created on: 12 May 2020
* Updated on: 4 Jan 2021
********************************************************************************

* Read in analytic file created here: "Create analytic file.R"
use county_analytic_Jan4.dta, clear

ren *_county_* *_cnty_*

* Restrict period for speed calculations
drop if date > date("20200727","YMD")


***
* Create NPI measures
***

* SAH only relevant if restricted movement
* replace sah_state_start = . if sah_rest_move==0

* Basic binary indicator signaling when policy went into effect
* County
foreach var in sah bc res mask k12 {

gen `var'_cnty = 0
	replace `var'_cnty = 1 if date > `var'_cnty_start & !missing(`var'_cnty_start)

}
gen sah_bc_cnty = max(sah_cnty, bc_cnty)
	
* State
gen other_state_start = min(res_state_start, mask_state_start, k12_state_start, nh_state_start, gym_state_start)

foreach var in sah bc res mask k12 nh gym other {

gen `var'_state = 0
	replace `var'_state = 1 if date > `var'_state_start & !missing(`var'_state_start)

}
gen sah_bc_state = max(sah_state, bc_state)



* Create one date var that captures the earlier of the county or state NPI dates
foreach var in sah bc res mask k12 {

gen `var'_both_start = min(`var'_state_start, `var'_cnty_start)

}
gen sah_bc_both_start = min(bc_both_start, sah_both_start)
gen sah_bc_cnty_start = min(sah_cnty_start, bc_cnty_start)
gen sah_bc_state_start = min(sah_state_start, bc_state_start)

* To ease references, creating variables for NPIs with only state-level data
foreach var in nh gym {

gen `var'_both_start = `var'_state_start

}
* Create date var that captures the day that both SAH and BC were adopted
gen cmbd_both_start = .
	replace cmbd_both_start = max(sah_both_start, bc_both_start) if !missing(sah_both_start) & !missing(bc_both_start)

* Create earliest adoption data for other NPIs (not SAH or BC)
gen other_both_start = .
	replace other_both_start = min(res_both_start, mask_both_start, nh_both_start, k12_both_start, gym_both_start)
	
* Create one indicator that captures both county and state policies
foreach var in sah bc res mask k12 nh gym other {

gen `var'_both = 0
	replace `var'_both = 1 if date > `var'_both_start & !missing(`var'_both_start)

}
gen sah_bc_both = max(sah_both, bc_both)


* Create indicator for combined SAH and BC
gen cmbd_both = (sah_both == 1 & bc_both == 1)	

* Create lagged indicator for death outcomes
foreach t in 1 5 10 14 {
foreach var in sah bc res mask k12 nh gym cmbd other {

gen `var'_both_lag`t' = 0
	replace `var'_both_lag`t' = 1 if date > (`var'_both_start + `t') & !missing(`var'_both_start)
	
}
}

* Any NPI (SAH or BC)
foreach t in 1 5 10 14 {

gen sah_bc_both_lag`t' = min(sah_both_lag`t', bc_both_lag`t')	

}

* Format date vars
format start_week date *start %td


***
* Calculate speed variables
***

* County NPI speed (3 operationalizations)

* 1. # of days between when case rate exceeded twice its baseline case rate and day county officials rolled out the NPI

* Capture rate of change in confirmed cases pc day over day
sort grp_fips date
bys grp_fips: gen case_pc_change = covid_cases_pc/covid_cases_pc[_n-1]
*br state county grp_fips date covid_cases* covid_cases_pc case_pc_change

* Create indicator for first day when case rates were 2x previous day
gen cases_doubled = (case_pc_change > 2 & !missing(case_pc_change))
gen day_cases_doubled_ = date if cases_doubled==1
bys grp_fips: egen day_cases_doubled = min(day_cases_doubled_)
* 42.6% did not have a day where pc cases doubled
format day_cases_doubled %td

* County NPI and County and state NPI
* Multiplying number by (-1) so higher values indicate faster response
* If no NPI, then use last day (end 4/23)
* If cases always 0 then assign 0 as speed
foreach npi in sah bc sah_bc res mask k12 nh gym cmbd other {

gen `npi'_speed_dbl_both = (`npi'_both_start - day_cases_doubled)*-1
	replace `npi'_speed_dbl_both = (date("20200423","YMD") - day_cases_doubled)*-1 if missing(`npi'_both_start)
	replace `npi'_speed_dbl_both = 0 if missing(day_cases_doubled)
}

drop *doubled* case_pc_change


* 2. # of days between when case rate reached average number of cases between 1/21 (first recorded COVID case) and 3/7 (week before first NPI) = 7.304348 

* Create indicator for first day when cases => 7.3
gen cases_outbreak_nat = (covid_cases > 7.3)
gen cases_outbreak_nat_ = date if cases_outbreak_nat==1
bys grp_fips: egen day_outbreak_nat = min(cases_outbreak_nat_)

* collapse (max) covid_cases_pc, by(grp_fips)
* 55.4% never experienced cases > 7.3

format day_outbreak_nat %td

* County NPI and County and state NPI
* Multiplying number by (-1) so higher values indicate faster response
* If no NPI, then use last day (end 4/23)
* If cases always 0 then assign 0 as speed
foreach npi in sah bc sah_bc res mask k12 nh gym cmbd other {

gen `npi'_speed_nat_both = (`npi'_both_start - day_outbreak_nat)*-1
	replace `npi'_speed_nat_both = (22028 - day_outbreak_nat)*-1 if missing(`npi'_both_start)
	replace `npi'_speed_nat_both = 0 if missing(day_outbreak_nat)
}

drop *outbreak* 

* 3. # of days between when case rate reached the lowest infection threshold among counties that adopted a SAH or BC = 1.85

* Create var that captures earlier of two dates (SAH or BC)
* gen min = (sah_cnty_start > bc_cnty_start)
*	replace min = 0 if  missing(sah_cnty_start) 
*	replace min = 0 if missing(bc_cnty_start)

*	replace sah_cnty_start = bc_cnty_start if min==1
*	keep if sah_cnty_start==date | bc_cnty_start==date
*	sum covid_cases_pc

* Create indicator for first day when cases => 1.85
gen cases_outbreak_cnty = (covid_cases_pc > 1.85)
gen cases_outbreak_cnty_ = date if cases_outbreak_cnty==1
bys grp_fips: egen day_outbreak_cnty = min(cases_outbreak_cnty_)
* 5.2% never experienced cases > 1.85

format day_outbreak_cnty %td

* County NPI and County and State NPI
* Multiplying number by (-1) so higher values indicate faster response
* If no NPI, then use last day (end 4/23)
* If cases always 0 then assign 0 as speed
foreach npi in sah bc sah_bc res mask k12 nh gym cmbd other {

gen `npi'_speed_cnty_both = (`npi'_both_start - day_outbreak_cnty)*-1
	replace `npi'_speed_cnty_both = (22028 - day_outbreak_cnty)*-1 if missing(`npi'_both_start)
	replace `npi'_speed_cnty_both = 0 if missing(day_outbreak_cnty)
}

drop *outbreak* 

***
* Prep data for analysis
***

* Log median hhld income 
gen ln_med_income=ln(med_income)
drop med_income

* Transform outcome vars
ihstrans covid_cases_pc, prefix(ihs_)
ihstrans covid_deaths_pc, prefix(ihs_)
ihstrans state_total_deaths_pc, prefix(ihs_)

* Create combined non-physican clinician variable
gen npc_pc = aprn_pc + pa_pc + np_pc
drop aprn_pc pa_pc np_pc

* Total number of other NPIs
egen other_npis_n = rowtotal(mask_both k12_both nh_both gym_both res_both)

****
* Create interactions
***

* Republican county (dummy)
gen rep = (rep_vote_share_2016>50)
	replace rep = . if missing(rep_vote_share_2016)

* Adoption timing dummies
gen early = (sah_bc_speed_dbl_both>=0 & !missing(sah_bc_both_start))
gen late = (sah_bc_speed_dbl_both<0 & !missing(sah_bc_both_start))
gen never = (missing(sah_bc_both_start))

* Create comorbitity index
egen comorbid_mean = rowtotal(copd asthma atrial_fib heart_failure ischemic_heart_disease cancer hypertension hiv_aids diabetes chronic_kidney_diease hepatitis)
sum comorbid_mean, d
gen comorbid_index = (comorbid_mean - `r(mean)')/`r(sd)'

label var comorbid_index "Comorbity index N(0,1)"


* Create interaction needed for temporal variation
foreach npi in sah bc sah_bc res mask k12 nh gym cmbd other {
foreach type in dbl nat cnty {
gen int_`npi'_speed_`type'_both = `npi'_both*`npi'_speed_`type'_both
}
}


* Create interaction needed for lagged variables
foreach npi in sah bc sah_bc res mask k12 nh gym cmbd other {
foreach type in dbl nat cnty {
foreach t in 1 5 10 14 {
gen int_`npi'_speed_`type'_both_lag`t' = `npi'_both_lag`t'*`npi'_speed_`type'_both
}
}
}

* Label interactions
foreach type in sah bc sah_bc res mask k12 nh gym cmbd other {
label var int_`type'_speed_dbl_both "`type' x # days btwn `type' and 1st day-to-day infection doubling"

label var int_`type'_speed_nat_both "`type' x # days btwn `type' and 1st day cases > 7.3 (nat avg)"

label var int_`type'_speed_cnty_both "`type' x # days btwn `type' and 1st day cases pc > 1.85 (cnty avg)"
}


* Lagged
foreach type in sah bc sah_bc res mask k12 nh gym cmbd other {
foreach t in 1 5 10 14 {
label var int_`type'_speed_dbl_both_lag`t' "`type' (`t' day lag) x # days btwn `type' and 1st day-to-day infection doubling"

label var int_`type'_speed_nat_both_lag`t' "`type' (`t' day lag) x # days btwn `type' and 1st day cases > 7.3 (nat avg)"

label var int_`type'_speed_cnty_both_lag`t' "`type' (`t' day lag) x # days btwn `type' and 1st day cases pc > 1.85 (cnty avg)"
}
}

****
* Add variable labels
***

* NPI vars sourced from BU SPH COVID-19 US state policy database (https://ce.naco.org/?dset=COVID-19&ind=Emergency%20Declaration%20Types)
label var sah_cnty_start "Effective date of county Safe at Home policy"
label var sah_state_start "Effective date of state Stay at Home/Shelter in Place"
label var sah_both_start  "Effective date of county or state Stay at Home/Shelter in Place"
label var sah_cnty "County Safer at Home policy in place"
label var sah_state "State Stay at Home/Shelter in Place policy in place"
label var sah_both "County or state Safer at Home policy in place"
label var sah_state "County or state SAH Safer at Home policy in place"
label var sah_speed_dbl_both "# days btwn any SAH and first day-to-day infection doubling"
label var sah_speed_nat_both "# days btwn any SAH and first day cases exceeded 7.3 cases (1/21-3/7 national avg)"
label var sah_speed_cnty_both "# days btwn any SAH and first day cases exceeded average per capita infection threshold in counties w/ SAH or BC (1.85)"

label var bc_cnty_start "Effective date of county business closures"
label var bc_state_start "Effective date of state business closures"
label var bc_both_start "Effective date of county or state business closures"

label var bc_cnty "County non-essential business closure in effect"
label var bc_state "State non-essential business closure in effect"
label var bc_both "County or state non-essential business closure in effect"
label var bc_speed_dbl_both "# days btwn any BC and first day-to-day doubling of infections"
label var bc_speed_nat_both "# days btwn any BC and first day cases exceeded 7.3 cases (1/21-3/7 national avg)"
label var bc_speed_cnty_both "# days btwn any BC and first day cases exceeded average per capita infection threshold in counties w/ SAH or BC (1.85)"


* 2016 Republican vote shares sourced from MIT Election Data and Science Lab (https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ)
label var rep_vote_share_2016 "Republican vote share in 2016 pres election"

* COVID-19 cases and deaths sourced from NYT (https://github.com/nytimes/covid-19-data/blob/master/us-counties.csv)
label var covid_deaths_pc "County COVID-19 deaths per 100,000"
label var covid_deaths "County COVID-19 deaths"

label var covid_cases_pc "County COVID-19 cases per 100,000"
label var covid_cases "County COVID-19 cases"

* State-level demographic and socioeconomic characteristics (ACS 1-yr estimates)
label var pop "Population (2019)"
label var pct_white "Pct white (2018)"
label var pct_black "Pct black (2018)"
label var pct_hisp "Pct Hispanic/Latino (2018)"
label var pct_asian "Pct Asian (2018)"
label var pct_fb "Pct foreign born (2018)"
label var pct_noncit "Pct noncitizen (2018)"
label var pct_below_fpl "Pct living below FPL (2018)"
label var pct_over65 "Pct over age 65 (2018)"
label var pct_under18 "Pct under 18 (2018)"
label var pct_unemp "Pct in labor force unemployed (2018)"
label var pct_unins "Pct with no health insurance (2018)"
label var pct_male "Pct male (2018)"
label var pct_nohs "Pct with less than a HS degree (2018)"
label var pct_bachelorplus "Pct bachelors degree or higher (2018)"
label var pct_bachelorplus "Pct with bachelors or higher (2018)"
label var ln_med_income "Logged median household income (2018)"

* CMS chronic disease prevalence (https://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Chronic-Conditions/CC_Main)
label var copd "Pct Medicare w/ COPD (2017)"
label var asthma "Pct Medicare w/ asthma (2017)"
label var atrial_fib "Pct Medicare w/ atrial fibrillation(2017)"
label var heart_failure "Pct Medicare w/ heart failure (2017)"
label var ischemic_heart_disease "Pct Medicare w/ ischemic heart disease (2017)"
label var cancer "Pct Medicare w/ cancer (2017)"
label var hypertension "Pct Medicare w/ hypertension (2017)"
label var hiv_aids "Pct Medicare w/ HIV/AIDS (2017)"
label var diabetes "Pct Medicare w/ diabetes (2017)"
label var chronic_kidney_diease "Pct Medicare w/ kidney disease (2017)"
label var hepatitis "Pct Medicare w/ hepatitis (2017)"

* Health infrastructure sourced from HRSA AHRF (https://data.hrsa.gov/data/download)
label var pcp_pc "Primary care physicians per 1,000 (2017)"
label var hosp_pc "Hospitals per 1,000 (2017)"
label var md_pc "Medical doctors per 1,000 (2017)"
label var hosp_beds_pc "Hospital beds per 1,000 (2017)"
label var npc_pc "Non-physician clinicians per 1,000 (2018)"
label var chc_pc "Community health centers per 1,000 (2019)"

* Mobility (https://github.com/descarteslabs/DL-COVID-19)
label var m50 "Mobility: Median maximum distance traveled"     

label var m_res "Residential Mobility (Google)"
label var m_retrec "Recreational Mobility (Google)"
label var m_grocpharm "Grocery/Pharma Mobility (Google)"
label var m_park "Park Mobility (Google)"
label var m_trans "Transit Mobility (Google)"
label var m_work "Work Mobility (Google)"

label var m_res_nomiss "Residential Mobility (Google)"
label var m_retrec_nomiss "Recreational Mobility (Google)"
label var m_grocpharm_nomiss "Grocery/Pharma Mobility (Google)"
label var m_park_nomiss "Park Mobility (Google)"
label var m_trans_nomiss "Transit Mobility (Google)"
label var m_work_nomiss "Work Mobility (Google)"     

* Testing (https://covidtracking.com/data/download)
label var state_test_results "Total tests by state"
label var state_test_results_pc "Total tests by state per 100,000"

* Overall mortality (https://data.cdc.gov/NCHS/Weekly-counts-of-death-by-jurisdiction-and-cause-o/u6jv-9ijr)
label var state_total_deaths "Total deaths per week by state"
label var state_total_deaths_pc "Total deaths per week by state per 100,000"

save working_county, replace


log close


* Exploring policy counts
use working_county, clear

collapse (max) sah* bc*, by(state county)

tab sah_cnty sah_state if sah_both==1
tab sah_both // 73% with SAH

tab bc_cnty bc_state if bc_both==1
tab bc_both // 74% with bus closure


