##########################################################  
# COVID-19 project: Prepare data for county-level analysis
# Created on: 30 May 2020
# Updated on: 4 Jan 2021
##########################################################  

setwd("/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Data")

# Install pkgs
library(tidyverse)
library(RSocrata)
library(lubridate)
library(tidycensus)
library(lubridate)

##########################################################  
# Complete list of counties and select sociodemographic characterstics
##########################################################  

# Check to see if 2019 population estimates available at state level by race/ethnicity
library(censusapi)

# View apis available
apis <- listCensusApis()

# Inspect meta data to see what variables can be identified
census_vars <- listCensusMetadata(name = "2019/pep/charagegroups", 
                                 type = "variables")

# Inspect available geographies
listCensusMetadata(name = "2019/pep/charage", 
                   type = "geography")
# Race population estimates for 2019 not available at state level


# Downloading U.S. Census data
# 2015-2019 API won't be made available until late 2020
varlookup <- load_variables(2018, "acs1", cache = TRUE)

census_api_key("e4c9e6dc019590c6779a0975e12405cdba5d33cd")

dem<-get_acs(
  geography="county",
  variables=c("B05003_005", "B05003_010", "B05003_016", "B05003_021", #fb: male u18/o18, female u18/o18
              "B05003_007", "B05003_012", "B05003_018", "B05003_023", #noncit:  male u18/o18, female u18/o18 ,
              "B01001_006", "B01001_007", "B01001_008", "B01001_009", "B01001_010", #male: 15-17/18-19/20/21/22-24
              "B02001_001", #total
              "B03002_003", #not hisp white
              #"B02001_002",#white alone
              "B02001_003", #black alone
              "B02001_005", #asian alone
              "B05002_026", #fb, noncit from Latin America
              "B03002_012", #hispanic/latino
              "B17005_002", #income in past 12 months below 100% FPL
              "B06011_001", #med income in past 12 months
              "B01001_020", "B01001_021", "B01001_022", "B01001_023", "B01001_024", "B01001_025", #male: 65-66/67-69/70-74/75-79/80-84/85+
              "B01001_044", "B01001_045", "B01001_046", "B01001_047", "B01001_048", "B01001_049", #female: 65-66/67-69/70-74/75-79/80-84/85+
              "B01001_003", "B01001_004", "B01001_005", "B01001_006", #male: u5/5-9/10-14/15-17
              "B01001_027", "B01001_028", "B01001_029", "B01001_030", #female: u5/5-9/10-14/15-17
              #"B16010_002", #less than hs degree (among 25+)
              "C23002A_008", "C23002B_021", #male/female 16-64 in civilian labor force and unemployed
              "B27011_007", "B27011_012","B27011_017", #employed/unemployed/NILF with no health insurance 
              "B01001_026", "B01001_002", #female/male
              #"B27011_008", #in LF unemployed
              "B15002_003",  "B15002_004", "B15002_005", "B15002_006", "B15002_007", "B15002_008", "B15002_009", "B15002_010",
              #male: no schooling/nursery to 4th/5-6/7-8/9/10/11/12 (no diploma)
              "B15002_020","B15002_021","B15002_022","B15002_023","B15002_024","B15002_025","B15002_026","B15002_027",
              #female: no schooling/nursery to 4th/5-6/7-8/9/10/11/12 (no diploma)
              "B15002_015", "B15002_016", "B15002_017", "B15002_018", #male: bachelors/masters/professional/doctorate
              "B15002_032", "B15002_033", "B15002_034", "B15002_035"), #female: bachelors/masters/professional/doctorate
  output = "tidy",
  survey="acs5",
  year = 2018)

# Vectorize variables
dem.2 <- dem %>%
  mutate(cat = case_when(
    variable %in% c("B01001_020", "B01001_021", "B01001_022", "B01001_023", "B01001_024", "B01001_025", 
                    "B01001_044", "B01001_045", "B01001_046", "B01001_047", "B01001_048", "B01001_049") ~ "over65",
    variable %in% c("B01001_003", "B01001_004", "B01001_005", "B01001_006", 
                    "B01001_027", "B01001_028", "B01001_029", "B01001_030") ~ "under18",
    variable %in% c("B01001_006", "B01001_007",  "B01001_008", "B01001_009", "B01001_010") ~ "male.15.14",
    variable %in% "B02001_001" ~ "pop",
    variable %in% "B03002_003" ~ "white",
    variable %in% "B02001_003" ~ "black",
    variable %in% "B02001_005" ~ "asian",
    variable %in% "B03002_012" ~ "hisp",
    variable %in% "B05002_026" ~ "latnoncit", 
    variable %in% c("B05003_005","B05003_010","B05003_016","B05003_021") ~ "fb",
    variable %in% c("B05003_007","B05003_012", "B05003_018","B05003_023") ~ "noncit", 
    variable %in% "B17005_002" ~ "below.fpl",
    variable %in% "B06011_001" ~ "med.income",
    variable %in% c("C23002A_008", "C23002B_021") ~ "unemp",
    variable %in% c("B27011_007", "B27011_012","B27011_017") ~ "uninsured",
    variable %in% "B01001_026" ~ "female",
    variable %in% "B01001_002" ~ "male",
    variable %in% c("B15002_003","B15002_004", "B15002_005", "B15002_006", "B15002_007", "B15002_008", 
                    "B15002_009", "B15002_010", "B15002_020","B15002_021","B15002_022","B15002_023",
                    "B15002_024","B15002_025","B15002_026","B15002_027") ~ "edu.nohs",
    variable %in% c("B15002_015", "B15002_016", "B15002_017", "B15002_018", 
                    "B15002_032", "B15002_033", "B15002_034", "B15002_035") ~ "edu.bachelor.plus"))

# Group the data by our new categories and sum
dem.3 <- dem.2 %>%
  group_by(GEOID, NAME, cat) %>%
  summarize(estimate = sum(estimate)) %>%
  ungroup() %>%
  spread(cat, estimate) %>%
  rename(fips = GEOID)

# Calculate percentages
dem.4 <- dem.3 %>%
  mutate(pct.noncit =  noncit/pop*100,
         pct.fb = fb/pop*100,
         pct.white = white/pop*100,
         pct.black = black/pop*100,
         pct.hisp = hisp/pop*100,
         pct.asian = asian/pop*100,
         pct.below.fpl = below.fpl/pop*100,
         pct.over65 = over65/pop*100,
         pct.under18 = under18/pop*100,
         pct.unemp = unemp/pop*100,
         pct.unins = uninsured/pop*100,
         pct.male = male/pop*100,
         pct.nohs = edu.nohs/pop*100,
         pct.latnoncit = latnoncit/pop*100,
         pct.bachelorplus = edu.bachelor.plus/pop*100)

# Pulling in state population to standardize total death counts for mechanism check (contagion)
dem.state<-get_acs(
  geography="state",
  variables="B02001_001",
  output = "tidy",
  survey="acs1",
  year = 2018)  %>%
  mutate(cat = case_when(variable %in% "B02001_001" ~ "pop")) %>% # Vectorize variables
  group_by(GEOID, NAME, cat) %>% # group by new category and sum
  summarize(estimate = sum(estimate)) %>%
  ungroup() %>%
  spread(cat, estimate) %>%
  rename(state.pop=pop,
         state.fips=GEOID) %>%
  select(state.pop, state.fips)

# Merge county data with state population totals
acs.dem <- dem.4 %>%
  mutate(state.fips=substr(fips,1,2),
         fips = as.integer(fips)) %>%
  filter(state.fips != 72) %>% # remove Puerto Rico
  select(fips, state.fips, pop, pct.noncit:pct.bachelorplus, med.income) %>%
  left_join(dem.state, by="state.fips")

# COVID data for certain states/counties are grouped differently 
# Creating demographic detail for these aggregated groupings

# #1: NY boroughs all loaded onto NY county (Manhattan)
# Need population and demographics to be representative of all 5 boroughs

# Trim dem data to just include 5 boroughs for reweighting
acs.dem.nyb <- acs.dem %>%
  filter(fips %in% c("36005","36047","36061","36081","36085"))  %>%
  mutate(total = sum(pop),
         prop=pop/total)

# Apply weights so NY county total reflects 5 boroughs as a whole
fin.acs.dem.nyb <- acs.dem.nyb %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~.*prop) %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~sum(., na.rm=TRUE)) %>%
  filter(fips=="36061") %>%
  select(-pop, -prop) %>%
  rename(pop=total)

# #2: Rhode Island deaths recorded at state level
# Need population and demographics to be representative of entire state

# Trim dem data to just include Rhode Island counties for reweighting
acs.dem.ri <- acs.dem %>%
  filter(state.fips == "44") %>%
  mutate(total = sum(pop),
         prop=pop/total)

# Apply weights so NY county total reflects 5 boroughs as a whole
fin.acs.dem.ri <- acs.dem.ri %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~.*prop) %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~sum(., na.rm=TRUE)) %>%
  filter(fips=="44007") %>%
  select(-pop, -prop) %>%
  rename(pop=total)


# #3: Massachusetts counties Dukes and Nantucket combined
# Need population and demographics to be representative of both counties

# Trim dem data to just include 2 counties for reweighting
acs.dem.ma <- acs.dem %>%
  filter(fips %in% c("25007", "25019")) %>%
  mutate(total = sum(pop),
         prop=pop/total)

# Apply weights so NY county total reflects 5 boroughs as a whole
fin.acs.dem.ma <- acs.dem.ma %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~.*prop) %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~sum(., na.rm=TRUE)) %>%
  filter(fips=="25007") %>%
  select(-pop, -prop) %>%
  rename(pop=total)


# #4: Utah counties combined in DPH regions
# Need population and demographics to be representative of regions

# Bear River
# Trim dem data to just include 2 counties for reweighting
acs.dem.ut.br <- acs.dem %>%
  filter(fips %in% c("49005", "49003", "49033")) %>% 
  mutate(total = sum(pop),
         prop=pop/total)

# Apply weights so largest county reflects all counties in DPH region
fin.acs.dem.ut.br <- acs.dem.ut.br %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~.*prop) %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~sum(., na.rm=TRUE)) %>%
  filter(fips=="49005") %>%
  select(-pop, -prop) %>%
  rename(pop=total)

# Central
# Trim dem data to just include 2 counties for reweighting
acs.dem.ut.c <- acs.dem %>%
  filter(fips %in% c("49039", "49041", "49023", "49027", "49031", "49055")) %>% 
  mutate(total = sum(pop),
         prop=pop/total)

# Apply weights so largest county reflects all counties in DPH region
fin.acs.dem.ut.c <- acs.dem.ut.c %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~.*prop) %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~sum(., na.rm=TRUE)) %>%
  filter(fips=="49039") %>%
  select(-pop, -prop) %>%
  rename(pop=total)

# SE
# Trim dem data to just include 2 counties for reweighting
acs.dem.ut.se <- acs.dem %>%
  filter(fips %in% c("49007", "49015", "49019")) %>% 
  mutate(total = sum(pop),
         prop=pop/total)

# Apply weights so largest county reflects all counties in DPH region
fin.acs.dem.ut.se <- acs.dem.ut.se %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~.*prop) %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~sum(., na.rm=TRUE)) %>%
  filter(fips=="49007") %>%
  select(-pop, -prop) %>%
  rename(pop=total)

# SW
# Trim dem data to just include 2 counties for reweighting
acs.dem.ut.sw <- acs.dem %>%
  filter(fips %in% c("49053", "49017", "49021", "49025", "49001")) %>%
  mutate(total = sum(pop),
         prop=pop/total)

# Apply weights so largest county reflects all counties in DPH region
fin.acs.dem.ut.sw <- acs.dem.ut.sw %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~.*prop) %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~sum(., na.rm=TRUE)) %>%
  filter(fips=="49053") %>%
  select(-pop, -prop) %>%
  rename(pop=total)

# Tri County
# Trim dem data to just include 2 counties for reweighting
acs.dem.ut.tri <- acs.dem %>%
  filter(fips %in% c("49047", "49009", "49013")) %>%
  mutate(total = sum(pop),
         prop=pop/total)

# Apply weights so largest county reflects all counties in DPH region
fin.acs.dem.ut.tri <- acs.dem.ut.tri %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~.*prop) %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~sum(., na.rm=TRUE)) %>%
  filter(fips=="49047") %>%
  select(-pop, -prop) %>%
  rename(pop=total)

# Weber-Morgan
# Trim dem data to just include 2 counties for reweighting
acs.dem.ut.wm <- acs.dem %>%
  filter(fips %in% c("49057", "49029")) %>% 
  mutate(total = sum(pop),
         prop=pop/total)

# Apply weights so largest county reflects all counties in DPH region
fin.acs.dem.ut.wm <- acs.dem.ut.wm %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~.*prop) %>%
  mutate_at(vars(c("pct.noncit", "pct.fb", "pct.white", "pct.black", "pct.hisp", "pct.asian",
                   "pct.below.fpl", "pct.over65", "pct.under18", "pct.unemp", "pct.unins", 
                   "pct.male", "pct.nohs", "pct.latnoncit", "pct.bachelorplus",
                   "med.income")), ~sum(., na.rm=TRUE)) %>%
  filter(fips=="49057") %>%
  select(-pop, -prop) %>%
  rename(pop=total)

# Append new detail to original data
fin.acs.dem <- acs.dem %>%
  filter(fips != "36005" & fips != "36047" & fips != "36061" & fips != "36081" & fips != "36085" &
           fips != "44001" & fips != "44003" & fips != "44005" & fips != "44009" & fips != "44007" & 
           fips != "25007" & fips != "25019" &
           fips != "49005" & fips != "49003" & fips != "49033" &
           fips != "49039" & fips != "49041" & fips != "49023" & fips != "49027" & fips != "49031" & fips != "49055" &  
           fips != "49007" & fips != "49015" & fips != "49019" &
           fips != "49053" & fips != "49017" & fips != "49021" & fips != "49025" & fips != "49001" & 
           fips != "49047" & fips != "49009" & fips != "49013" &
           fips != "49057" & fips != "49029") %>%
  rbind(fin.acs.dem.nyb) %>%
  rbind(fin.acs.dem.ri) %>%
  rbind(fin.acs.dem.ma) %>%
  rbind(fin.acs.dem.ut.br) %>%
  rbind(fin.acs.dem.ut.c) %>%
  rbind(fin.acs.dem.ut.se) %>%
  rbind(fin.acs.dem.ut.sw) %>%
  rbind(fin.acs.dem.ut.tri) %>%
  rbind(fin.acs.dem.ut.wm) %>%
  rename(grp.fips=fips)

# Create a file that combines the population proportions for necessary reweighting of other measures
cnty.wghts <- rbind(acs.dem.nyb, acs.dem.ri, acs.dem.ma, acs.dem.ut.br, acs.dem.ut.c,
                    acs.dem.ut.se, acs.dem.ut.sw, acs.dem.ut.tri, acs.dem.ut.wm) %>%
  mutate(grp.fips = case_when(
    state.fips == "44" ~ 44007,
    state.fips=="36" ~ 36061,
    state.fips=="25" ~ 25007,
    fips %in% c(49003, 49033) ~ 49005,
    fips %in% c(49041, 49023, 49027, 49031,49055) ~ 49039,
    fips %in% c(49015, 49019) ~ 49007,
    fips %in% c(49017, 49021, 49025, 49001) ~ 49053,
    fips %in% c(49009, 49013) ~ 49047,
    fips == 49029 ~ 49057),
    grp.fips=ifelse(is.na(grp.fips), fips, grp.fips)) %>%
  select(fips, prop, grp.fips) 

remove(dem.4, dem.3, dem.2, dem, apis, census_vars, varlookup, dem.state, acs.dem, acs.dem.nyb, 
       fin.acs.dem.nyb, acs.dem.ri, fin.acs.dem.ri, acs.dem.ma, fin.acs.dem.ma, 
       acs.dem.ut.br, acs.dem.ut.c, acs.dem.ut.se, acs.dem.ut.sw, acs.dem.ut.tri, acs.dem.ut.wm,
       fin.acs.dem.ut.br, fin.acs.dem.ut.c, fin.acs.dem.ut.se, fin.acs.dem.ut.sw, fin.acs.dem.ut.tri, 
       fin.acs.dem.ut.wm)






##########################################################  
# Weekly COVID cases and deaths at the national and county level
##########################################################  

# Johns Hopkins daily COVID-19 deaths
# https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_time_series
covid.deaths.jh<-read.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv")
save(covid.deaths.jh, file="COVID/Johns Hopkins COVID-19 death data.Rda")

# Clean data
covid.deaths.jh.long<-covid.deaths.jh %>%
  gather(date, covid_deaths, X1.22.20:X12.10.20, factor_key=TRUE) %>%
  mutate(date=mdy(str_replace(date, "X", ""))) %>%
  rename(state = Province_State,
         county = Admin2,
         pop.jh=Population,
         lat = Lat, 
         long = Long_,
         fips = FIPS) %>%
  select(state, county, fips, date, covid_deaths, pop.jh, lat, long) %>%
  filter(state != "American Samoa" & state != "Guam" & state != "Northern Mariana Islands" &
           state != "Puerto Rico" & state != "Virgin Islands" & state != "Diamond Princess" & 
           state != "Grand Princess")

# Johns Hopkins daily COVID-19 confirmed cases
# https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_time_series
covid.cases.jh<-read.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv")
save(covid.cases.jh, file="COVID/Johns Hopkins COVID-19 case data.Rda")

# Clean data
covid.cases.jh.long<-covid.cases.jh %>%
  gather(date, covid_cases, X1.22.20:X12.10.20, factor_key=TRUE) %>%
  mutate(date=mdy(str_replace(date, "X", ""))) %>%
  rename(state = Province_State,
         county = Admin2,
         lat = Lat, 
         long = Long_,
         fips = FIPS) %>%
  select(state, county, fips, date, covid_cases) %>%
  filter(state != "American Samoa" & state != "Guam" & state != "Northern Mariana Islands" &
           state != "Puerto Rico" & state != "Virgin Islands" & state != "Diamond Princess" & 
           state != "Grand Princess")

# Bring death and case data together
covid.jh.join <- merge(covid.deaths.jh.long, 
                       covid.cases.jh.long,
                       by = c("state", "county", "fips", "date")) 

# COVID case and death counts are grouped together in some instances
# Rename counties so aggregated figures load onto representative county (typically the most populus)
covid.jh.long <- covid.jh.join %>%
  mutate(grp.fips = ifelse(fips %in% c("36005", "36047", "36081", "36085"), "36061", 
                           ifelse(fips %in% c("44001", "44003", "44005", "44009"), "44007",
                                  ifelse(fips == "25019", "25007",
                                         ifelse(fips %in% c("49003", "49033"), "49005",
                                                ifelse(fips %in% c("49041", "49023", "49027", "49031","49055"), "49039",
                                                       ifelse(fips %in% c("49015", "49019"), "49007",
                                                              ifelse(fips %in% c("49017", "49021", "49025", "49001"), "49053",
                                                                     ifelse(fips %in% c("49009", "49013"), "49047",
                                                                            ifelse(fips == "49029", "49057",fips)))))))))) %>%
  filter(fips==grp.fips) %>%
  select(-fips) %>%
  # Dropping cases where cannot distinguish the exact county where cases/deaths occurred
  filter(!is.na(grp.fips) & !grepl("Out of", county) & county != "Unassigned") 


# Create daily case and death count variables
covid.jh.long.1 <- covid.jh.long %>%
  mutate(start_week = floor_date(date, "week"),
         grp.fips=as.integer(grp.fips)) %>%
  arrange(state, grp.fips, date) %>% 
  group_by(state, grp.fips) %>%
  mutate(covid_deaths_n = covid_deaths - lag(covid_deaths, default = nth(covid_deaths, 1)),
         covid_deaths_n = ifelse(covid_deaths_n < 0, 0, covid_deaths_n),
         covid_cases_n = covid_cases - lag(covid_cases, default = nth(covid_cases, 1)),
         covid_cases_n = ifelse(covid_cases_n < 0, 0, covid_cases_n)) %>%
  select(state, county, grp.fips, date, start_week,  
         covid_cases_n, covid_deaths_n, lat, long, -covid_deaths, -covid_cases) %>%
  rename(covid_deaths = covid_deaths_n,
         covid_cases = covid_cases_n) %>%
  as.data.frame()

# Collapse population at region level 
jh.pop<-covid.jh.join %>%
  mutate(grp.fips = ifelse(fips %in% c("36005", "36047", "36081", "36085"), "36061", 
                           ifelse(fips %in% c("44001", "44003", "44005", "44009"), "44007",
                                  ifelse(fips == "25019", "25007",
                                         ifelse(fips %in% c("49003", "49033"), "49005",
                                                ifelse(fips %in% c("49041", "49023", "49027", "49031","49055"), "49039",
                                                       ifelse(fips %in% c("49015", "49019"), "49007",
                                                              ifelse(fips %in% c("49017", "49021", "49025", "49001"), "49053",
                                                                     ifelse(fips %in% c("49009", "49013"), "49047",
                                                                            ifelse(fips == "49029", "49057",fips)))))))))) %>%
  group_by(fips) %>%
  mutate(pop.jh=max(pop.jh, na.rm = TRUE),
         grp.fips=as.integer(grp.fips)) %>%
  select(grp.fips, fips, pop.jh) %>%
  distinct() %>%
  group_by(grp.fips) %>%
  summarize(pop.jh=sum(pop.jh, na.rm=TRUE))
  
# Merge JH pop figures on COVID data
fin.covid.county<-covid.jh.long.1 %>%
  left_join(jh.pop, by="grp.fips")
  
fin.covid.county %>% summarize(n_distinct(grp.fips)) # 3117 counties
fin.covid.county %>% summarize(n_distinct(date)) # 101 days


# Creating a shell that includes all counties (not grouped) for mapping purposes 
jh.counties <- covid.jh.join %>%
  filter(!is.na(fips) & !grepl("Out of", county) & county != "Unassigned") %>%
  mutate(start_week = floor_date(date, "week"),
         grp.fips=as.integer(fips)) %>%
  arrange(state, fips, date) %>% 
  group_by(state, fips) %>%
  mutate(covid_deaths_n = covid_deaths - lag(covid_deaths, default = nth(covid_deaths, 1)),
         covid_deaths_n = ifelse(covid_deaths_n < 0, 0, covid_deaths_n),
         covid_cases_n = covid_cases - lag(covid_cases, default = nth(covid_cases, 1)),
         covid_cases_n = ifelse(covid_cases_n < 0, 0, covid_cases_n),
         pop.jh=sum(pop.jh, na.rm=T))  %>%
  select(state, county, fips, date, start_week, pop.jh,  
         covid_cases_n, covid_deaths_n, lat, long, -covid_deaths, -covid_cases) %>%
  rename(covid_deaths = covid_deaths_n,
         covid_cases = covid_cases_n) %>%
  as.data.frame()

jh.counties %>% summarize(n_distinct(fips)) # 3142 counties

remove(covid.jh.long, covid.jh.join, covid.cases.jh.long, covid.cases.jh, covid.deaths.jh.long, 
       covid.deaths.jh, jh.pop, covid.jh.long.1)





##########################################################  
# State presidential returns
##########################################################  

# Retreived from MIT election data (https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ)
# Load data
load("Presidential returns/countypres2000to2016.RData")

# Raname dataframe
pres.rtns<-x
remove(x)

# Collapse at state-level and create data frame that include Republican vote share in 2016
pres.rtns <- pres.rtns %>%
  filter(party=="republican" & year==2016)  %>%
  mutate(rep_vote_share_2016 = candidatevotes/totalvotes*100,
         fips=as.numeric(FIPS)) %>%
  select(fips, rep_vote_share_2016) %>%
  as.data.frame()

# Derive grouped rep shares for counties that reflect regions
pres.rtns.wt <- pres.rtns %>%
  right_join(cnty.wghts, by="fips") %>%
  select(-fips) %>%
  group_by(grp.fips) %>%
  summarize(rep_vote_share_2016_wt = sum(rep_vote_share_2016*prop, na.rm=TRUE)) %>%  
  rename(rep_vote_share_2016=rep_vote_share_2016_wt,
         fips=grp.fips) %>% 
  select(fips, rep_vote_share_2016) 

# Append new detail to original data
fin.pres.rtns <- pres.rtns %>%
  filter(fips != "36005" & fips != "36047" & fips != "36061" & fips != "36081" & fips != "36085" &
           fips != "44001" & fips != "44003" & fips != "44005" & fips != "44009" & fips != "44007" & 
           fips != "25007" & fips != "25019" &
           fips != "49005" & fips != "49003" & fips != "49033" &
           fips != "49039" & fips != "49041" & fips != "49023" & fips != "49027" & fips != "49031" & fips != "49055" &  
           fips != "49007" & fips != "49015" & fips != "49019" &
           fips != "49053" & fips != "49017" & fips != "49021" & fips != "49025" & fips != "49001" & 
           fips != "49047" & fips != "49009" & fips != "49013" &
           fips != "49057" & fips != "49029") %>%
  rbind(pres.rtns.wt) %>%
  rename(grp.fips=fips)

remove(pres.rtns, pres.rtns.wt)





##########################################################  
# NPIs
##########################################################  

##########
# State-level NPIs
##########

# Retreived from BU SPH CUSP database
# https://docs.google.com/spreadsheets/d/1zu9qEWI8PsOI_i8nI_S29HDGHlIp2lfVMsGxpQ5tvAQ/edit#gid=1357478819

# Import directly from Google docs to retrieve latest info
# library(gsheet)

# Closures
# npi.closures<-gsheet2tbl('https://docs.google.com/spreadsheets/d/1zu9qEWI8PsOI_i8nI_S29HDGHlIp2lfVMsGxpQ5tvAQ/edit#gid=1357478819')

# Dates different from first iteration; loading data retrieved on 6/7
library(readxl)
npi.closures<-read_excel("NPIs/COVID-19 US state policy database (CUSP) 7June2020.xlsx",
                         sheet = "Physical Distance Closures")

npi.closures.1 <- npi.closures[1:51, ] %>%
  rename(k12_state_start = date.school,
         nh_state_start =date.nursing.home,
         bc_state_start = date.bus,
         res_state_start = date.rest,
         gym_state_start = date.gyms,
         state=`State`) %>%
  mutate_at(vars(contains("start")), ~ymd(.)) %>%
  select(state, ends_with("start"))

# Stay at home/shelter in place
# npi.sah<-gsheet2tbl('https://docs.google.com/spreadsheets/d/1zu9qEWI8PsOI_i8nI_S29HDGHlIp2lfVMsGxpQ5tvAQ/edit#gid=1894978869')

# Dates different from first iteration; loading data retrieved on 6/7
npi.sah<-read_excel("NPIs/COVID-19 US state policy database (CUSP) 7June2020.xlsx",
                    sheet = "Stay at Home")

npi.sah.1 <- npi.sah[1:51, ] %>%
  rename(sah_state_start = date.sah,
         state=`State`) %>%
  mutate_at(vars(contains("start")), ~ymd(.)) %>%
  select(state, ends_with("start"))

# Masks
npi.mask<-read_excel("NPIs/COVID-19 US state policy database (CUSP) 7June2020.xlsx",
                              sheet = "Face Masks")

npi.mask.1 <- npi.mask[1:51, ] %>%
  rename(mask_state_start = date.mask.all,
         state=`State`) %>%
  mutate_at(vars(mask_state_start), ~ymd(.)) %>%
  select(state, mask_state_start)

# Reopening
npi.reopen<-read_excel("NPIs/COVID-19 US state policy database (CUSP) 7June2020.xlsx",
                        sheet = "Reopening")

npi.reopen.1 <- npi.reopen[1:51, ] %>%
  rename(sah_state_end=end.sah,
         bc_state_end = reopen.bus,
         res_state_end = reopen.rest,
         gym_state_end = reopen.gyms,
         state=`State`) %>%
  mutate_at(vars(contains("end")), ~ymd(.)) %>%
  select(state, ends_with("end"))


# Merge files to create one NPI dataset
fin.npi.state <- left_join(npi.closures.1,
                           npi.sah.1,
                           by="state") %>%
  left_join(npi.mask.1, by="state") %>%
  left_join(npi.reopen.1, by="state")

save(fin.npi.state, file="NPIs/Final state NPIs.Rda")

remove(npi.closures, npi.closures.1, npi.sah, npi.sah.1, npi.mask, npi.mask.1, npi.reopen, npi.reopen.1)


##########
# County-level NPIs
##########

# Retreived from NACo (https://ce.naco.org/?dset=COVID-19&ind=Emergency%20Declaration%20Types)
# Import data
npi.county.naco<-read.csv("NPIs/County_Declaration_and_Policies.csv")

# Note: 5 boroughs of NYC (Kings (36047), Queens (36081), Bronx (36005), Richmond (36085) 
# consolidated to NY (36061)

# Prepare for merge
npi.county.naco <- npi.county.naco %>%
  mutate(sah_county_start = ymd(Safer.at.Home.Policy.Date),
         bc_county_start = ymd(Business.Closure.Policy.Date),
         fips=as.numeric(FIPS)) %>%
  select(fips, sah_county_start, bc_county_start) %>%
  mutate(fips=as.numeric(fips))


### DHHS database (BU CUSP on State Policies, Stay At Home Policies Queried from WikiData, Virtual Student Federal Service Interns manual curation)
## https://healthdata.gov/dataset/covid-19-state-and-county-policy-orders

# Import
npis<-read.csv("https://healthdata.gov/sites/default/files/state_policy_updates_20201206_0721.csv")

policy.types<-npis %>%
  mutate(date=as.POSIXct(date)) %>%
  filter(date<"2020-04-24") %>%
  count(policy_level, policy_type, sort=T) 

#write.csv(policy.types, row.names=FALSE, file="Policy types before 4.24.2020.csv")

npi.county.dhhs<-npis %>%
  filter(policy_level=="county") %>%
  distinct(state_id, county, fips_code, policy_type, start_stop, date) %>%
  pivot_wider(id_cols=c(state_id, county, fips_code),
              names_from=c(policy_type,start_stop), values_from=date) %>%
  rename(res_county_start=`Food and Drink_start`,
        k12_county_start=`Childcare (K-12)_start`,
        mask_county_start=`Mask Requirement_start`,
        fips=fips_code) %>%
  select(fips, starts_with(c("res","mask","k12")),
         -starts_with(c("Resu", "Resid", "Mask Req"))) %>%
  mutate_at(vars(ends_with(c("end", "start"))), ~str_replace(., "0020", "2020")) %>%
  mutate_at(vars(ends_with(c("end", "start"))), ~ymd(.)) %>%
  group_by(fips) %>%
  summarize_at(vars(res_county_start, k12_county_start, mask_county_start), 
               ~min(., na.rm=TRUE))

## Merge datasets and consolidate dates
fin.npi.county <- npi.county.naco %>%
  left_join(npi.county.dhhs, by="fips") %>%
  as.data.frame()

# Set earliest NPI for counties that reflect regions
county.npi.wt <- fin.npi.county %>%
  right_join(cnty.wghts, by="fips") %>%
  select(-fips) %>%
  group_by(grp.fips) %>%
  summarize_at(vars(sah_county_start:mask_county_start), ~min(., na.rm = TRUE)) %>%  
  rename(fips=grp.fips)

# Append new detail to original data
fin.npi.county.grp <- fin.npi.county %>%
  filter(fips != "36005" & fips != "36047" & fips != "36061" & fips != "36081" & fips != "36085" &
           fips != "44001" & fips != "44003" & fips != "44005" & fips != "44009" & fips != "44007" & 
           fips != "25007" & fips != "25019" &
           fips != "49005" & fips != "49003" & fips != "49033" &
           fips != "49039" & fips != "49041" & fips != "49023" & fips != "49027" & fips != "49031" & fips != "49055" &  
           fips != "49007" & fips != "49015" & fips != "49019" &
           fips != "49053" & fips != "49017" & fips != "49021" & fips != "49025" & fips != "49001" & 
           fips != "49047" & fips != "49009" & fips != "49013" &
           fips != "49057" & fips != "49029") %>%
  full_join(county.npi.wt) %>%
  # Duplicate fips -- consolidating dates
  group_by(fips) %>%
  summarize_at(vars(sah_county_start:mask_county_start), ~min(., na.rm=TRUE)) %>% 
  rename(grp.fips=fips)

remove(npi.county.dhhs, npi.county.naco, npis, policy.types, county.npi.wt)






##########################################################  
# HRSA Area Resource File information
########################################################## 

# Data retrieved from HRSA: https://data.hrsa.gov/data/download
library(haven)
ahrf<-read_sas("HRSA AHRF/ahrf2019.sas7bdat")

ahrf<-ahrf %>%
  rename(fips=f00002,
         pcp=f1467517,
         under65=f1547117,
         #under65.unins=f1547417, 
         hosp=f0886817,
         hosp.beds=f0892117,
         #er.visits=f0957217,
         chc=f1525319,
         pa=f1464118, 
         aprn=f1464618, 
         np=f1464218, 
         md=f1212917,
         woins=f1547317) %>% 
  mutate(fips=as.integer(fips)) %>%
  select(fips, pcp, under65, hosp, hosp.beds, chc, pa, aprn, np, md) 

# Derive grouped totals for counties that reflect regions
ahrf.wt <- ahrf %>%
  right_join(cnty.wghts, by="fips") %>%
  select(-fips) %>%
  group_by(grp.fips) %>%
  summarize_at(c("pcp", "under65", "hosp", "hosp.beds", "chc", "pa", "aprn", "np", "md"),
            sum, na.rm = TRUE) %>%  
  rename(fips=grp.fips)

# Append new detail to original data
fin.ahrf <- ahrf %>%
  filter(fips != "36005" & fips != "36047" & fips != "36061" & fips != "36081" & fips != "36085" &
           fips != "44001" & fips != "44003" & fips != "44005" & fips != "44009" & fips != "44007" & 
           fips != "25007" & fips != "25019" &
           fips != "49005" & fips != "49003" & fips != "49033" &
           fips != "49039" & fips != "49041" & fips != "49023" & fips != "49027" & fips != "49031" & fips != "49055" &  
           fips != "49007" & fips != "49015" & fips != "49019" &
           fips != "49053" & fips != "49017" & fips != "49021" & fips != "49025" & fips != "49001" & 
           fips != "49047" & fips != "49009" & fips != "49013" &
           fips != "49057" & fips != "49029") %>%
  rbind(ahrf.wt) %>%
  rename(grp.fips=fips)

#fin.ahrf %>% select(fips, pcp, under65, under65.unins, hosp, hosp.beds, er.visits,
#                   chc, pa, aprn, np, md) %>% View()

remove(ahrf, ahrf.wt)





##########################################################  
# CMS Chronic Disease Prevalence
########################################################## 

# https://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Chronic-Conditions/CC_Main
chronic <- read.csv("CMS chronic conditions/County_Table_Chronic_Conditions_Prevalence_2017.csv",
                    na.strings = c("", " "),
                    stringsAsFactors = FALSE)

# Keep prevalence rates for just those chronic dieases associated with poor COVID outcomes
chronic <- select(chronic,
                  State.County.FIPS.Code, COPD, Asthma, Atrial.Fibrillation, Heart.Failure, Ischemic.Heart.Disease, Cancer, 
                  Hypertension, HIV.AIDS, Diabetes, Chronic.Kidney.Disease, Hepatitis) %>%
  rename(fips=State.County.FIPS.Code,
         copd = COPD,
         asthma = Asthma, 
         atrial.fib = Atrial.Fibrillation, 
         heart.failure = Heart.Failure, 
         ischemic.heart.disease = Ischemic.Heart.Disease, 
         cancer = Cancer, 
         hypertension = Hypertension, 
         hiv.aids = HIV.AIDS, 
         diabetes = Diabetes, 
         chronic.kidney.diease = Chronic.Kidney.Disease, 
         hepatitis = Hepatitis) %>%
  mutate_all(~as.numeric(.)) %>%
  filter(!is.na(fips))

# Derive grouped shares for counties that reflect regions
chronic.wt <- chronic %>%
  right_join(cnty.wghts, by="fips") %>%
  select(-fips) %>%
  group_by(grp.fips) %>%
  mutate_at(c("copd", "asthma", "atrial.fib", "heart.failure", "ischemic.heart.disease", 
                 "cancer", "hypertension", "hiv.aids", "diabetes", "chronic.kidney.diease", 
                 "hepatitis"), ~.*prop) %>%  
  summarize_at(c("copd", "asthma", "atrial.fib", "heart.failure", "ischemic.heart.disease", 
              "cancer", "hypertension", "hiv.aids", "diabetes", "chronic.kidney.diease", 
              "hepatitis"), sum, na.rm=TRUE) %>%  
  rename(fips=grp.fips)

# Append new detail to original data
fin.chronic <- chronic %>%
  filter(fips != "36005" & fips != "36047" & fips != "36061" & fips != "36081" & fips != "36085" &
           fips != "44001" & fips != "44003" & fips != "44005" & fips != "44009" & fips != "44007" & 
           fips != "25007" & fips != "25019" &
           fips != "49005" & fips != "49003" & fips != "49033" &
           fips != "49039" & fips != "49041" & fips != "49023" & fips != "49027" & fips != "49031" & fips != "49055" &  
           fips != "49007" & fips != "49015" & fips != "49019" &
           fips != "49053" & fips != "49017" & fips != "49021" & fips != "49025" & fips != "49001" & 
           fips != "49047" & fips != "49009" & fips != "49013" &
           fips != "49057" & fips != "49029") %>%
  rbind(chronic.wt) %>%
  rename(grp.fips=fips)

remove(chronic, chronic.wt)






##########################################################  
# Mobility
########################################################## 

# Google
# https://github.com/datasciencecampus/google-mobility-reports-data

mobility<-read.csv("/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Data/Mobility/Global_Mobility_Report.csv",
                   stringsAsFactors = FALSE,
                   na.strings = c("", " ")) %>%
  filter(country_region=="United States" & !is.na(sub_region_2)) %>%
  mutate(date=mdy(date)) %>%
  rename(fips = census_fips_code,
         m_res = residential_percent_change_from_baseline, 
         m_work = workplaces_percent_change_from_baseline,
         m_retrec = retail_and_recreation_percent_change_from_baseline,
         m_grocpharm = grocery_and_pharmacy_percent_change_from_baseline,
         m_trans = transit_stations_percent_change_from_baseline,
         m_park = parks_percent_change_from_baseline)
         
miss <- mobility %>%
  group_by(fips) %>%
  summarize(miss_m_res = sum(is.na(m_res)),
            miss_m_work = sum(is.na(m_work)),
            miss_m_retrec = sum(is.na(m_retrec)),
            miss_m_grocpharm = sum(is.na(m_grocpharm)),
            miss_m_trans = sum(is.na(m_trans)),
            miss_m_park = sum(is.na(m_park)))

mobility2<-mobility %>%
  left_join(miss, by="fips") %>%
  mutate(m_res_nomiss = ifelse(miss_m_res == 0, m_res, NA),
         m_work_nomiss = ifelse(miss_m_work == 0, m_res, NA),
         m_retrec_nomiss = ifelse(miss_m_retrec == 0, m_res, NA),
         m_grocpharm_nomiss = ifelse(miss_m_grocpharm == 0, m_res, NA),
         m_trans_nomiss = ifelse(miss_m_trans == 0, m_res, NA),
         m_park_nomiss = ifelse(miss_m_park == 0, m_res, NA)) %>%
  select(fips, date, m_retrec:m_res, m_res_nomiss:m_park_nomiss)

remove(mobility)

# Descartes Labs
# https://github.com/descarteslabs/DL-COVID-19
# Technical paper describing measure: https://arxiv.org/pdf/2003.14228.pdf

mobility<-read.csv("https://raw.githubusercontent.com/descarteslabs/DL-COVID-19/master/DL-us-mobility-daterow.csv",
                   stringsAsFactors = FALSE,
                   na.strings = c("", " ")) %>%
  mutate(date=ymd(date)) %>%
  select(date, fips, m50, m50_index)

merge.mobility<-left_join(mobility2, mobility, by=c("date","fips"))

# Derive grouped rep shares for counties that reflect regions
merge.mobility.wt <- merge.mobility %>%
  right_join(cnty.wghts, by="fips") %>%
  select(-fips) %>%
  group_by(grp.fips, date) %>%
  mutate_at(vars(starts_with("m")), ~.*prop) %>%  
  summarize_at(vars(starts_with("m")), sum, na.rm=TRUE) %>%  
  rename(fips=grp.fips) %>%
  filter(!is.na(date)) %>%
  as.data.frame()

# Append new detail to original data
fin.mobility <- merge.mobility %>%
  filter(fips != "36005" & fips != "36047" & fips != "36061" & fips != "36081" & fips != "36085" &
           fips != "44001" & fips != "44003" & fips != "44005" & fips != "44009" & fips != "44007" & 
           fips != "25007" & fips != "25019" &
           fips != "49005" & fips != "49003" & fips != "49033" &
           fips != "49039" & fips != "49041" & fips != "49023" & fips != "49027" & fips != "49031" & fips != "49055" &  
           fips != "49007" & fips != "49015" & fips != "49019" &
           fips != "49053" & fips != "49017" & fips != "49021" & fips != "49025" & fips != "49001" & 
           fips != "49047" & fips != "49009" & fips != "49013" &
           fips != "49057" & fips != "49029") %>%
  rbind(merge.mobility.wt) %>%
  rename(grp.fips=fips)

save(fin.mobility, file="Mobility.Rda")
remove(mobility, mobility2, miss, merge.mobility, merge.mobility.wt)






##########################################################  
# State-level testing data
########################################################## 

# Source: COVID Tracking Project
# https://covidtracking.com/data/download

testing<-read.csv("https://covidtracking.com/api/v1/states/daily.csv",
                  na.strings = c("", " "),
                  stringsAsFactors = FALSE)

# Add state names
data(state)  
state<-as.data.frame(cbind(state.abb, state.name))
state[nrow(state) + 1,] = c("DC","District of Columbia")
state<-state %>% rename(state=state.name) 

fin.testing<-testing %>%
  mutate(date=ymd(as.character(date))) %>%
  select(state, date, totalTestResults) %>%
  rename(total.test.results=totalTestResults) %>%
  rename(state.abb=state) %>%
  left_join(state, by="state.abb") %>%
  select(-state.abb) %>%
  filter(!is.na(state))

save(fin.testing, file="Final testing.Rda")

remove(testing)





##########################################################  
# State-level non-COVID mortality data
########################################################## 

# Source: CDC NCHS
# Weekly counts of death by jurisdiction and cause of death
# https://data.cdc.gov/NCHS/Weekly-counts-of-death-by-jurisdiction-and-cause-o/u6jv-9ijr
state.alldeaths <- read.socrata("https://data.cdc.gov/resource/u6jv-9ijr.json",
                                app_token = "tXkSqMTSz3Tajj8me7DpqJRIN",
                                email     = "muchow2@uic.edu",
                                password  = "Rodney12#")

# Capture mortality over study period in 2019 (for use in placebo check to identify diff pre-trends)
state.alldeaths.2019<-state.alldeaths %>%
  mutate(date=ymd(week_ending_date),
         start_week = date - 6,
         number_of_deaths=as.numeric(number_of_deaths)) %>%
  rename(state=jurisdiction) %>%
  filter(date < "2020-12-08" & date > "2019-01-19") %>%
  group_by(state, start_week) %>%
  summarize(total.deaths.2019 = sum(number_of_deaths)) %>%
  mutate(new_start_week=start_week+364) %>%
  select(-start_week) %>%
  rename(start_week=new_start_week)

# Capture mortality in 2020 and append 2019 figure to 2020 dates for easy use
fin.state.alldeaths<-state.alldeaths %>%
  mutate(date=ymd(week_ending_date),
         start_week = date - 6,
         number_of_deaths=as.numeric(number_of_deaths)) %>%
  rename(state=jurisdiction) %>%
  filter(date > "2020-01-19") %>%
  group_by(state, start_week) %>%
  summarize(total.deaths = sum(number_of_deaths)) %>%
  left_join(state.alldeaths.2019, by=c("state","start_week")) %>%
  as.data.frame() 

save(fin.state.alldeaths, file="Final state deaths.Rda")
remove(state.alldeaths, state.alldeaths.2019)





##########################################################  
# Population density
########################################################## 

# Retrieved informaiton on land area from US Census Bureau
# https://www.census.gov/library/publications/2011/compendia/usa-counties-2011.html#LND

land.area<-read.csv("/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Data/Land area/landareabycounty.csv")

# No data dictionary to make sense of the variables, but used references from 10 counties
# (NY, Cook, Harris, LA, Kings NY, Suffolk, St. Charles MO, Cumberland IL, Riverside, Napa)
# and confirmed that LND110210D is the 2010 land area
land.area <- land.area %>%
  rename(sq.mi=LND110210D) %>%
  select(fips, sq.mi) %>%
  # Replacing counties with 0 sq mi with 1 to avoid undefined measures
  mutate(sq.mi=ifelse(sq.mi==0, 1, sq.mi))

# Derive aggregate sq mi for counties that reflect regions
land.area.wt <- land.area %>%
  right_join(cnty.wghts, by="fips") %>%
  select(-fips) %>%
  group_by(grp.fips) %>%
  summarize(sq.mi=sum(sq.mi, na.rm=T)) %>%  
  rename(fips=grp.fips) %>%
  select(fips, sq.mi) %>%
  as.data.frame()

# Append new detail to original data
fin.land.area <- land.area %>%
  filter(fips != "36005" & fips != "36047" & fips != "36061" & fips != "36081" & fips != "36085" &
           fips != "44001" & fips != "44003" & fips != "44005" & fips != "44009" & fips != "44007" & 
           fips != "25007" & fips != "25019" &
           fips != "49005" & fips != "49003" & fips != "49033" &
           fips != "49039" & fips != "49041" & fips != "49023" & fips != "49027" & fips != "49031" & fips != "49055" &  
           fips != "49007" & fips != "49015" & fips != "49019" &
           fips != "49053" & fips != "49017" & fips != "49021" & fips != "49025" & fips != "49001" & 
           fips != "49047" & fips != "49009" & fips != "49013" &
           fips != "49057" & fips != "49029") %>%
  rbind(land.area.wt) %>%
  rename(grp.fips=fips)

remove(land.area, land.area.wt)




##########################################################  
# Merge datasets
########################################################## 

merged<-right_join(fin.covid.county, 
                  fin.acs.dem,
                  by="grp.fips") %>%
  left_join(fin.npi.state,
            by="state") %>%
  left_join(fin.npi.county.grp, 
            by="grp.fips") %>%
  left_join(fin.state.alldeaths, 
            by=c("state","start_week")) %>%
  # Replace missing death totals to 0 as these signal no deaths occured
  mutate(total.deaths=ifelse(is.na(total.deaths),0,total.deaths),
         total.deaths.2019=ifelse(is.na(total.deaths.2019),0,total.deaths.2019)) %>%
  left_join(fin.pres.rtns, 
            by="grp.fips") %>% 
  left_join(fin.ahrf,
            by="grp.fips") %>%
  left_join(fin.chronic,
            by="grp.fips") %>%
  left_join(fin.testing,
            by=c("state","date")) %>%
  # Replace missing test days to 0 as these signal no covid tests
  mutate(total.test.results=ifelse(is.na(total.test.results),0,total.test.results)) %>% 
  left_join(fin.mobility,
            by=c("grp.fips","date")) %>%
  left_join(fin.land.area, by="grp.fips")


# Checking for missings
colnames(merged)[colSums(is.na(merged)) > 0]

merged %>% group_by(county) %>% filter(is.na(copd)) %>% summarize() # 14 counties w/o chronic disease info
merged %>% group_by(county) %>% filter(is.na(asthma)) %>% summarize() # 86 counties w/o chronic disease info
merged %>% group_by(county) %>% filter(is.na(atrial.fib)) %>% summarize() # 27 counties w/o chronic disease info
merged %>% group_by(county) %>% filter(is.na(heart.failure)) %>% summarize() # 10 counties w/o chronic disease info
merged %>% group_by(county) %>% filter(is.na(ischemic.heart.disease)) %>% summarize() # 4 counties w/o chronic disease info
merged %>% group_by(county) %>% filter(is.na(cancer)) %>% summarize() # 30 counties w/o chronic disease info
merged %>% group_by(county) %>% filter(is.na(hiv.aids)) %>% summarize() # 1031 counties w/o chronic disease info
merged %>% group_by(county) %>% filter(is.na(diabetes)) %>% summarize() # 3 counties w/o chronic disease info
merged %>% group_by(county) %>% filter(is.na(chronic.kidney.diease)) %>% summarize() # 4 counties w/o chronic disease info
merged %>% group_by(county) %>% filter(is.na(hepatitis)) %>% summarize() # 682 counties w/o chronic disease info

merged %>% group_by(grp.fips) %>% filter(is.na(rep_vote_share_2016)) %>% summarize() # 28 counties missing vote share info

merged %>% group_by(grp.fips) %>% filter(is.na(pct.below.fpl)) %>% summarize() # 1 county missing detail (Rio Arriba in NM)
merged %>% group_by(grp.fips) %>% filter(is.na(pct.unemp)) %>% summarize() # 1 county missing detail (Rio Arriba in NM)
merged %>% group_by(grp.fips) %>% filter(is.na(pct.unins)) %>% summarize() # 1 county missing detail (Rio Arriba in NM)
merged %>% group_by(grp.fips) %>% filter(is.na(med.income)) %>% summarize() # 2 counties missing detail (Rio Arriba in NM and Daggett in UT)

merged %>% filter(is.na(m50)) %>% summarize(n_distinct(date, grp.fips))/
  merged %>% summarize(n_distinct(date, grp.fips)) # 52% county/date combos missing mobility info (doesn't start until 3/1)



##########################################################  
# Create analytic files 
########################################################## 

analytic.file <- merged %>%
  arrange(grp.fips, date) %>%
  rename(state_total_deaths = total.deaths,
         state_test_results = total.test.results) %>%
  mutate(covid_deaths_pc = covid_deaths/pop.jh*100000,
         covid_cases_pc = covid_cases/pop.jh*100000,
         state_total_deaths_pc = state_total_deaths/state.pop*100000,
         state_test_results_pc = state_test_results/state.pop*100000,
         pcp_pc = pcp/pop*1000,
         hosp_pc = hosp/pop*1000,
         hosp_beds_pc=hosp.beds/pop*1000,
         chc_pc=chc/pop*1000,
         pa_pc = pa/pop*1000,
         aprn_pc=aprn/pop*1000,
         np_pc=np/pop*1000,
         md_pc=md/pop*1000,
         pop.density=pop/sq.mi) %>%
  select(state:start_week, grp.fips, state.fips, pop.jh, pop.density, state.pop, covid_cases, 
         covid_cases_pc, covid_deaths, covid_deaths_pc, state_total_deaths, state_total_deaths_pc, 
         state_test_results, state_test_results_pc, 
         starts_with(c("sah", "bc","res","mask","k12","gym","nh")), 
         pcp_pc:md_pc, copd:hepatitis, pct.noncit:med.income, rep_vote_share_2016, 
         m_retrec:m50_index, lat, long, sq.mi) %>%
  rename(pop=pop.jh) %>%
  as.data.frame()

# Spot check data before export
library(stargazer)
stargazer(analytic.file, 
          type = "text", 
          title="Descriptive statistics", digits=1)

save(analytic.file, file="analytic_file_Jan4.Rda")

# Export to .dta file
library(foreign)
write.dta(analytic.file, "county_analytic_Jan4.dta")

### 
# File for mapping
###
formaps<-left_join(jh.counties, fin.npi.county, by="fips") %>%
  left_join(fin.npi.state, by="state")

save(formaps, file="formaps_Jan4.Rda")



####
# Graphical diversion -- overall mortality compared (shoudl really be rates)
###

fin.state.alldeaths %>%
  group_by(start_week) %>%
  summarize(total.deaths.2020=sum(total.deaths, na.rm=T),
            total.deaths.2019=sum(total.deaths.2019, na.rm=T)) %>%
  pivot_longer(total.deaths.2019:total.deaths.2020) %>%
  ggplot(aes(x=start_week, y=value)) +
  geom_line(aes(color=name, linetype=name))
