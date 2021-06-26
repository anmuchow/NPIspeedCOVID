##########################################################  
# COVID-19 project: Create maps
# Created on: 22 July 2020
# Updated on: 10 Dec 2020
##########################################################  

setwd("/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Data")

# Install pkgs
library(tidyverse)
library(ggplot2)
library(sf)
library(lubridate)

##########################################################  
# Create maps
########################################################## 

# Read in data being used for reg models
load("formaps_Dec10.Rda") 

# Create variable that captures type of NPI in place at different periods
formaps<- formaps %>%
  mutate(# Minimum of county and state adoption dates
    sah_start=pmin(sah_county_start, sah_state_start, na.rm=TRUE),
    bc_start=pmin(bc_county_start, bc_state_start, na.rm=TRUE),
    res_start=pmin(res_county_start, res_state_start, na.rm=TRUE),
    mask_start=pmin(mask_county_start, mask_state_start, na.rm=TRUE),
    k12_start=pmin(k12_county_start, k12_state_start, na.rm=TRUE),
    gym_start=gym_state_start,
    nh_start = nh_state_start) %>%
    # Indicators for map
    mutate(
      sah = ifelse(date >= sah_start,1,NA), 
      bc = ifelse(date >= bc_start, 1, NA),
      npi = ifelse(is.na(sah) & is.na(bc), "Neither SAH or BC",
                 ifelse(sah==1 & is.na(bc), "Only SAH",
                        ifelse(is.na(sah) & bc==1, "Only BC",
                               ifelse(sah == 1 & bc == 1, "Both SAH and BC",
                                      NA)))),
      res = ifelse(date >= res_start,1,NA),
      mask = ifelse(date >= mask_start,1,NA),
      k12 = ifelse(date >= k12_start,1,NA),
      gym = ifelse(date >= gym_start,1,NA),
      nh = ifelse(date >= nh_start,1,NA)) %>%
  select(state, county, fips, date, pop.jh:covid_deaths, sah, bc, npi, 
         starts_with(c("sah","bc","res","mask","k12","gym","nh")), 
         long, lat) %>%
  mutate(npi = factor(npi, levels = c("Both SAH and BC", "Only SAH", "Only BC", 
                                      "Neither SAH or BC")))

count(formaps, sah, bc, npi)


# Load Urban institute mapper to retrieve county boundaries
library(urbnmapr)
library(ggthemes) # to export maps

counties<-urbnmapr::counties %>%
  mutate(fips = as.numeric(county_fips))

# Load colorblind friendly palette
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", 
               "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

# From colorpicker (http://tristen.ca/hcl-picker):
# #532C1C,#7B4A28,#A06D33,#C1953E,#DBC04D,#EEEF63
# #1D8071,#3F9F74,#6FBC70,#AAD868,#EEEF63
# #B7637D,#9791C2,#3CC2D0,#6BE39C,#EEEF63


# Cut data to see snapshot of NPIs at given dates

# March 20
march.20<-formaps %>%
  filter(date=="2020-03-20") %>%
  left_join(counties, by="fips")
count(march.20, npi)

tiff("/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Output/Plots/NPI adoption as of March 20.jpg", units="in", width=10, height=10, res=300)

march.20 %>%
  ggplot(aes(long.y, lat.y, group = group, fill = npi)) +
  geom_polygon(color="black",size = 0.10) +
  labs(fill = "NPI adopted") +
  labs(title = "Non-pharmaceutical Interventions in Effect as of March 20, 2020") +
  theme(panel.background = element_blank(),
        axis.ticks = element_blank(),
        axis.text.x = element_blank(), 
        axis.text.y = element_blank(),
        axis.title.y=element_blank(),
        axis.title.x=element_blank()) +
  scale_fill_manual(values = c("#56B4E9", "#E69F00", "#F0E442", "white")) +
  #scale_x_continuous(limits = c(-124, -67))+
  #scale_y_continuous(limits = c(22, 49)) +
  theme(legend.position = c(0.9, 0.2)) +
  coord_map(projection = "gilbert") 

dev.off()


# March 30
march.30<-formaps %>%
  filter(date=="2020-03-30") %>%
  left_join(counties, by="fips")
count(march.30, npi)

tiff("/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Output/Plots/NPI adoption as of March 30.jpg", units="in", width=10, height=10, res=300)

march.30 %>%
  ggplot(aes(long.y, lat.y, group = group, fill = npi)) +
  geom_polygon(color="black",size = 0.10) +
  labs(fill = "NPI adopted") +
  labs(title = "Non-pharmaceutical Interventions in Effect as of March 30, 2020") +
  theme(panel.background = element_blank(),
        axis.ticks = element_blank(),
        axis.text.x = element_blank(), 
        axis.text.y = element_blank(),
        axis.title.y=element_blank(),
        axis.title.x=element_blank()) +
  scale_fill_manual(values = c("#56B4E9", "#E69F00", "#F0E442", "white")) +
  #scale_x_continuous(limits = c(-124, -67))+
  #scale_y_continuous(limits = c(22, 49)) +
  theme(legend.position = c(0.9, 0.2)) +
  coord_map(projection = "gilbert") 

dev.off()

# April 10
apr.10<-formaps %>%
  filter(date=="2020-04-10") %>%
  left_join(counties, by="fips")
count(apr.10, npi)

tiff("/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Output/Plots/NPI adoption as of April 10.jpg", units="in", width=10, height=10, res=300)

apr.10 %>%
  ggplot(aes(long.y, lat.y, group = group, fill = npi)) +
  geom_polygon(color="black",size = 0.10) +
  labs(fill = "NPI adopted") +
  labs(title = "Non-pharmaceutical Interventions in Effect as of April 10, 2020") +
  theme(panel.background = element_blank(),
        axis.ticks = element_blank(),
        axis.text.x = element_blank(), 
        axis.text.y = element_blank(),
        axis.title.y=element_blank(),
        axis.title.x=element_blank()) +
  scale_fill_manual(values = c("#56B4E9", "#E69F00", 
                               "#F0E442", "white")) +
  #scale_x_continuous(limits = c(-124, -67))+
  #scale_y_continuous(limits = c(22, 49)) +
  theme(legend.position = c(0.9, 0.2)) +
  coord_map(projection = "gilbert") 

dev.off()


# April 20
april.20<-formaps %>%
  filter(date=="2020-04-20") %>%
  left_join(counties, by="fips")
count(april.20, npi)

tiff("/Users/amuchow/Dropbox/Caty&Neeraj&Ashley/Output/Plots/NPI adoption as of April 20.jpg", units="in", width=10, height=10, res=300)

april.20 %>%
  ggplot(aes(long.y, lat.y, group = group, fill = npi)) +
  geom_polygon(color="black",size = 0.10) +
  labs(fill = "NPI adopted") +
  labs(title = "Non-pharmaceutical Interventions in Effect as of April 20, 2020") +
  theme(panel.background = element_blank(),
        axis.ticks = element_blank(),
        axis.text.x = element_blank(), 
        axis.text.y = element_blank(),
        axis.title.y=element_blank(),
        axis.title.x=element_blank()) +
  scale_fill_manual(values = c("#56B4E9", "#E69F00", 
                               "#F0E442", "white")) +
  #scale_x_continuous(limits = c(-124, -67))+
  #scale_y_continuous(limits = c(22, 49)) +
  theme(legend.position = c(0.9, 0.2)) +
  coord_map(projection = "gilbert") 

dev.off()

