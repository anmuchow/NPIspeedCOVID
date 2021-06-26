clear

****
* Setup
***
cd "/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Data"
global path "/Users/amuchow/Dropbox/Caty&Neeraj&Ashley"

*cd "C:\Users\camuedo-dorantes\Dropbox\Caty&Neeraj&Ashley\Data\"
*global path "C:\Users\camuedo-dorantes\Dropbox\Caty&Neeraj&Ashley\"

cap log close
log using "$path/Logs/04.2.2 County-level event study.log", replace

********************************************************************************
* COVID-19 project
* County-level event study
* Created on: 14 July 2020
* Updated on: 8 Jan 2021
********************************************************************************

* Use dataset cleaned in "02.2 Clean county-level data.do"
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


* Create standardized time variable relative to date first SAH or BC was adopted
bys grp_fips date: gen timetotreat = date - sah_bc_both_start
sort grp_fips date

/*
* Declare panel dataset
xtset grp_fips date, daily
qui xtreg covid_deaths_pc state_test_results_pc int_other_speed_dbl_both_lag14 m50 i.date, fe cluster(grp_fips)

* Create event study plots
* Using all periods and showing all periods in plot
eventdd covid_deaths_pc state_test_results_pc int_other_speed_dbl_both_lag14 m50 , hdfe absorb(i.grp_fips i.date) timevar(timetotreat) cluster(grp_fips) graph_op(ytitle("COVID-19 Deaths per 100K")  xlabel(-50(5)15) xtitle("Time")) ci(rcap)
* Using all periods but only showing balanced periods in plot
eventdd covid_deaths_pc state_test_results_pc int_other_speed_dbl_both_lag14 m50 , hdfe absorb(i.grp_fips i.date) timevar(timetotreat) cluster(grp_fips) balanced graph_op(ytitle("COVID-19 Deaths per 100K") xtitle("Time")) ci(rcap)
* Using balanced observations in the specified period
eventdd covid_deaths_pc state_test_results_pc int_other_speed_dbl_both_lag14 m50 , hdfe absorb(i.grp_fips date) timevar(timetotreat) cluster(grp_fips) lags(15) leads(30) keepbal(grp_fips) graph_op(ytitle("COVID-19 Deaths per 100K") xtitle("Time")) ci(rcap)
*/

/*
** ORIGINAL GRAPH IN PAPER
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

					
* Identification Check #2: DV = COVID cases per capita
reghdfe covid_cases_pc state_test_results_pc int_other_speed_dbl_both_lag14 m50 `spec2' if nmiss==15, absorb(i.grp_fips i.date) keepsing vce(cluster i.grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Event study/id_any_check_event_study.xls", keep(`spec2') se bdec(3) excel ctitle("Effect of NPIs on COVID-19 infections per capita") ti(Dependent Variable: Event Study) label replace

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
					ytitle("Effect of NPIs on COVID-19 infections per capita")				///
					xtitle("Days since the adoption of first NPI") ///
					addplot(line @b @at)				///
					ciopts(recast(rcap))				///
					/*rescale(100)*/						///
					scheme(s1mono)

					graph export "$path/Output/Event study/id_cases_check_any_event_study.png", replace

*/

** Could we do some supplementary analysis taking out counties that adopted SAH/BC before March 26? 
drop if sah_bc_both_start < date("20200326","YMD")
count

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


/*				
** Before March 15				

* Create dummies
gen  t0=(date==date("20200315","YMD"))

		foreach n in 3 7 10 14 17 21 24 28 31 35 38 {
		bys grp_fips date: gen byte timebefore`n'=(date==date("20200315","YMD") -`n')
		}

		foreach n in 3 7 10 14 17 21 24 28 31 35 38 {
		bys grp_fips date: gen byte timeafter`n'=(date==date("20200315","YMD") +`n')
		}

* Estimate coefs

local spec2 timebefore35 timebefore31 timebefore28 timebefore24 timebefore21 timebefore17 timebefore14 timebefore10 timebefore7 timebefore3 t0 timeafter3 timeafter7 timeafter10 timeafter14 timeafter17 timeafter21 timeafter24 timeafter28 timeafter31 timeafter35

* Before March 15

reghdfe covid_deaths_pc state_test_results_pc int_other_speed_dbl_both_lag14 m50 `spec2'  if nmiss==15 & date < date("20200315","YMD"), absorb(i.grp_fips i.date) keepsing vce(cluster grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Event study/id_any_check_event_study_before0315.xls", keep(`spec2') se bdec(3) excel ctitle("Change in COVID-19 deaths per capita") ti(Dependent Variable: Event Study) label replace

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
					ytitle("Change in COVID-19 deaths per capita")				///
					xtitle("Days Prior to March 15") ///
					addplot(line @b @at)				///
					ciopts(recast(rcap))				///
					/*rescale(100)*/						///
					scheme(s1mono)

					graph export "$path/Output/Event study/id_any_check_event_study_before0315.png", replace
*/


***
** Extend analysis 2 weeks
***

* Use dataset cleaned in "02.2 Clean county-level data.do"
use working_county, clear
format *end %td 

* Restrict sample to period from 2/15 to 5/7 (14 days post first county reopening)
drop if date < date("20200215","YMD")
drop if date > date("20200423","YMD")+14

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
gen  t0=(date==sah_bc_both_start) & !missing(sah_bc_both_start)

		foreach n in 3 7 10 14 17 21 24 28 31 35 38 42 45 49 {
		bys grp_fips date: gen byte timebefore`n'=(date==sah_bc_both_start -`n' & !missing(sah_bc_both_start))
		
		}

		foreach n in 3 7 10 14 17 21 24 28 31 35 38 42 45 49 {
		bys grp_fips date: gen byte timeafter`n'=(date==sah_bc_both_start +`n' & !missing(sah_bc_both_start) /*& sah_bc_both_end != 1*/)
		}


* Estimate coefs 
local spec1 timebefore49 timebefore42 timebefore35 timebefore28 timebefore21 timebefore14 timebefore7 t0 timeafter7 timeafter14 timeafter21 timeafter28 timeafter35 timeafter42 timeafter49

local spec2 timebefore49 timebefore45 timebefore42 timebefore38 timebefore35 timebefore31 timebefore28 timebefore24 timebefore21 timebefore17 timebefore14 timebefore10 timebefore7 timebefore3 t0 timeafter3 timeafter7 timeafter10 timeafter14 timeafter17 timeafter21 timeafter24 timeafter28 timeafter31 timeafter35 timeafter38 timeafter42 timeafter45 timeafter49

* Restrict to states that didn't lift NPIs
keep if (sah_state_end>date("20200423","YMD")+14 | missing(sah_state_end)) & (bc_state_end>date("20200423","YMD")+14 | missing(bc_state_end))

* Identification Check #1: DV = COVID deaths per capita
reghdfe covid_cases_pc state_test_results_pc int_other_speed_dbl_both_lag14 m50 `spec2' if nmiss==15, absorb(i.grp_fips i.date) keepsing vce(cluster i.grp_fips) summarize(mean sd)
outreg2 using "$path/Output/Event study/id_any_check_event_study_extended.xls", keep(`spec2') se bdec(3) excel ctitle("Change in COVID-19 deaths per capita") ti(Dependent Variable: Event Study) label replace

est sto mp
		
  			*draw graph
			coefplot, keep(`spec2') ///
					coeflabels(timebefore49 = "-49" ///
							   timebefore45 = " " ///
							   timebefore42 = "-42" ///
							   timebefore38 = " " ///
							   timebefore35 = "-35" ///
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
							   timeafter35 = "+35" ///
							   timeafter38 = " " ///
							   timeafter42 = "+42" ///
							   timeafter45 = " " ///
							   timeafter49 = "+49") ///  
					vertical 							 ///
					yline(0)							 ///
					/*xline(5.5, lpattern(dash))*/ 			///
					ytitle("Change in COVID-19 infections per capita")				///
					xtitle("Days Since the Adoption of First NPI") ///
					addplot(line @b @at)				///
					ciopts(recast(rcap))				///
					/*rescale(100)*/						///
					scheme(s1mono)

					graph export "$path/Output/Event study/id_check_any_event_study_extended.png", replace


/*
** Could we do some supplementary analysis taking out counties that adopted SAH/BC before March 26? 
drop if sah_bc_both_start < date("20200326","YMD")
count


* Create dummies
gen  t0=(date==sah_bc_both_start) & !missing(sah_bc_both_start)

		foreach n in 3 7 10 14 17 21 24 28 31 35 38 42 45 49 {
		bys grp_fips date: gen byte timebefore`n'=(date==sah_bc_both_start -`n' & !missing(sah_bc_both_start))
		}

		foreach n in 3 7 10 14 17 21 24 28 31 35 38 42 45 49 {
		bys grp_fips date: gen byte timeafter`n'=(date==sah_bc_both_start +`n' & !missing(sah_bc_both_start))
		}

* Estimate coefs 
local spec1 timebefore49 timebefore42 timebefore35 timebefore28 timebefore21 timebefore14 timebefore7 t0 timeafter7 timeafter14 timeafter21 timeafter28 timeafter35 timeafter42 timeafter49

local spec2 timebefore49 timebefore45 timebefore42 timebefore38 timebefore35 timebefore31 timebefore28 timebefore24 timebefore21 timebefore17 timebefore14 timebefore10 timebefore7 timebefore3 t0 timeafter3 timeafter7 timeafter10 timeafter14 timeafter17 timeafter21 timeafter24 timeafter28 timeafter31 timeafter35 timeafter38 timeafter42 timeafter45 timeafter49

* Identification Check #1: DV = COVID deaths per capita
reghdfe covid_deaths_pc state_test_results_pc int_other_speed_dbl_both_lag14 m50 `spec2' if nmiss==15, absorb(i.grp_fips i.date) keepsing vce(cluster i.grp_fips) summarize(mean sd)
*outreg2 using "$path/Output/Event study/id_any_check_event_study_extended.xls", keep(`spec2') se bdec(3) excel ctitle("Change in COVID-19 deaths per capita") ti(Dependent Variable: Event Study) label replace

est sto mp
		
  			*draw graph
			coefplot, keep(`spec2') ///
					coeflabels(timebefore49 = "-49" ///
							   timebefore45 = " " ///
							   timebefore42 = "-42" ///
							   timebefore38 = " " ///
							   timebefore35 = "-35" ///
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
							   timeafter35 = "+35" ///
							   timeafter38 = " " ///
							   timeafter42 = "+42" ///
							   timeafter45 = " " ///
							   timeafter49 = "+49") ///  
					vertical 							 ///
					yline(0)							 ///
					/*xline(5.5, lpattern(dash))*/ 			///
					ytitle("Change in COVID-19 deaths per capita")				///
					xtitle("Days Since the Adoption of First NPI") ///
					addplot(line @b @at)				///
					ciopts(recast(rcap))				///
					/*rescale(100)*/						///
					scheme(s1mono)

					graph export "$path/Output/Event study/id_check_any_event_study_extended_appendix.png", replace
*/
					
log close
