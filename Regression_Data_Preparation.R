##############################
# This script is used to prepare data for a regression analysis on marginal emissions from power plants in Texas during 2010-2012
##############################

#load the emission files
#source: ftp://newftp.epa.gov/DMDnLoad/emissions/hourly/monthly/
#2010 - 2012 for Texas
library(data.table)
emissions <- list.files(path="./EPA2/2010_2011_2012/", full.names=TRUE)
dat <- lapply(emissions,read.csv)
emissions <- rbindlist(dat)
rm(dat)


#We want to know to which NERC regions the power plants belong. We have a fips2NERC crosswalk from Holland et al.(2016), but the emissions data set does not contain fips codes, only ORISPL plant codes. We can find a ORISPL-FIPS crosswalk in the NEEDS database.
#source: https://www.epa.gov/airmarkets/documentation-national-electric-energy-data-system-needs-v513
library(dplyr)
needs <- read.csv(file="./NEEDS/needs_v515.csv", header=TRUE, sep=";")
needs <- select(needs, ORISPL_CODE=ORIS.Plant.Code, fips=FIPS5)
needs <- unique(needs)
emissions <- merge(emissions, needs, by="ORISPL_CODE", all.x=TRUE)

#Some of the power stations did not get a fips code assigned via the previous procedure. We look at them and assign fips codes manually, if the plants have positive electricity production during the three years of observation; otherwise, we remove them.
unique(emissions$FACILITY_NAME[is.na(emissions$fips)]) #test which plants do not have a fips code
emissions %>%
  filter(FACILITY_NAME=="C E Newman") %>%
  summarise(bla=sum(GLOAD..MW., na.rm=TRUE))
emissions$fips[emissions$FACILITY_NAME=="Tradinghouse"] <- 48309
emissions$fips[emissions$FACILITY_NAME=="Calpine Hidalgo Energy Center"] <- 48215
emissions <- emissions[emissions$FACILITY_NAME!="C E Newman", ]
emissions <- emissions[emissions$FACILITY_NAME!="Sweetwater Generating Plant", ]
emissions <- emissions[emissions$FACILITY_NAME!="W B Tuttle", ]

#fips2NERC crosswalk and restrict to ERCOT (Texas) region
load("./Data/fips2NERC.Rda")
emissions <- merge(emissions, fips2NERC, "fips", all.x=TRUE)
emissions <- filter(emissions, NERC=="ercot")

#aggregate data to power plants, because it is seperate for each generation unit (can be multiple units per plant)
emissions <- emissions %>%
  select(fips, FACILITY_NAME, ORISPL_CODE, UNITID, OP_DATE, OP_HOUR, OP_TIME, SO2_MASS..lbs., NOX_MASS..lbs., CO2_MASS..tons., GLOAD..MW.) %>%
  group_by(OP_DATE, OP_HOUR, FACILITY_NAME) %>%
  summarize(SO2_lbs = sum(SO2_MASS..lbs.), NOX_lbs = sum(NOX_MASS..lbs.), CO2_tons = sum(CO2_MASS..tons.), gload_MWh=sum(GLOAD..MW.), fips = unique(fips), ORISPL_CODE=unique(ORISPL_CODE))

#import load data for ercot region, 2010 - 2012
#source: http://www.ercot.com/gridinfo/load/load_hist/
load2010 <- read.csv(file="./ERCOT/2010_ERCOT_Hourly_Load_Data.csv", header=TRUE, sep=";", dec=",")
load2011 <- read.csv(file="./ERCOT/2011_ERCOT_Hourly_Load_Data.csv", header=TRUE, sep=";", dec=",")
load2012 <- read.csv(file="./ERCOT/2012_ERCOT_Hourly_Load_Data.csv", header=TRUE, sep=";", dec=",")
load <- rbind(load2010, load2011, load2012)

#transform time format
load$date <- as.Date(substr(load$Hour_End, 1, 10), format="%d.%m.%Y")
load$hour <- as.integer(substr(load$Hour_End, 12, 13))-1
load$hour[load$hour==-1] <- 23 
load$time <- paste(load$date, "-", load$hour, sep="")
emissions$time <- paste(as.Date(emissions$OP_DATE, format="%m-%d-%Y"), "-", emissions$OP_HOUR, sep="")
load <- select(load, time, load=ERCOT)

#for 2010-11-07-1, there are two values in load. we take the mean of the two
load[7441:7442,2] <- mean(c(load[7441:7442,2]))
load <- unique(load)

#merge emissions with load
emissions <- merge(emissions, load, "time", all.x=TRUE)
emissions$OP_MONTH <- as.factor(as.integer(substring(emissions$OP_DATE, 1, 2))) #integer step (to get rid of leading 0)
emissions$OP_HOUR <- as.factor(emissions$OP_HOUR)
emissions$FACILITY_NAME <- as.character(emissions$FACILITY_NAME)


###this part is for adding PM2.5 values


#load the NEI PM2.5 data; here, plants are identified using EIS IDs, which can not be matched to ORIS plant codes automatically
#source: https://www.epa.gov/air-emissions-inventories/
nei <- read.csv(file="./NEI_2011/facility/2011neiv2_facility.csv")
nei <- filter(nei, description=="PM2.5 Primary (Filt + Cond)")
nei <- filter(nei, facility_source_description=="Electricity Generation via Combustion")
nei <- rename(nei, fips=state_and_county_fips_code) #could use by.x and by.y instead
load("./Data/fips2NERC.Rda")
nei <- merge(nei, fips2NERC, "fips", all.x=TRUE)
nei <- nei[nei$NERC=="ercot", ]
nei <- nei[!is.na(nei$fips), ]


#manually match ORIS Plant Code and EIS ID plants via names; I use Excel for convenience
library(xlsx)
work <- select(emissions, FACILITY_NAME, ORISPL_CODE, fips)
work <- unique(work)
write.xlsx(work, file="./work.xlsx")
work2 <- select(nei, facility_site_name, eis_facility_site_id, fips)
write.xlsx(work2, file="./work2.xlsx")
#here the manual work has to be done in Excel
oris_eis <- read.xlsx(file="./work_done.xlsx", 1)
oris_eis <- select(oris_eis, eis, ORISPL_CODE)
emissions <- merge(emissions, oris_eis, by="ORISPL_CODE")
nei <- select(nei, eis_facility_site_id, total_emissions)
emissions <- merge(emissions, nei, by.x="eis", by.y="eis_facility_site_id", all.x=TRUE)
emissions <- rename(emissions, pm25_tons=total_emissions)

#for the plants with no PM2.5 value (because they could not be matched to a EIS ID plant in the NEI Data), use average
#here the average is computed
sum1 <- emissions %>%
  select(FACILITY_NAME, gload_MWh, pm25_tons) %>%
  group_by(FACILITY_NAME) %>%
  summarize(total_gload = sum(gload_MWh, na.rm=TRUE), pm25_tons=unique(pm25_tons))
sum1 <- sum1[!is.na(sum1$pm25_tons), ]
avg_pm25_per_MWh = sum(sum1$pm25_tons)/sum(sum1$total_gload)

#this calculates hourly emissions from annual average, weighted with gross load
emissions <- emissions %>%
  group_by(FACILITY_NAME) %>%
  mutate(total = sum(gload_MWh, na.rm=TRUE)) %>%
  mutate(pm25_tons=pm25_tons*gload_MWh/total)

#here the average is set for the missing ones
emissions$pm25_tons[is.na(emissions$pm25_tons) & !is.na(emissions$gload_MWh)] <- emissions$gload_MWh[is.na(emissions$pm25_tons) & !is.na(emissions$gload_MWh)]*avg_pm25_per_MWh

#exclude weekends, as in Holland et al. (2016)
emissions$OP_DATE <- as.character(emissions$OP_DATE)
emissions$OP_DATE <- as.Date(emissions$OP_DATE, format="%m-%d-%Y")
emissions <- emissions[!(weekdays(emissions$OP_DATE) %in% c('Samstag','Sonntag')), ]

#saveRDS(emissions, file="./emissions.Rds")

#########################################################################
#now we should have all informationen needed for the actual regression...
#########################################################################

#preparation for RTutor
#emissions <- readRDS(file="./emissions.Rds")

emissions <- filter(emissions, FACILITY_NAME=="Coleto Creek") #example
emissions$time <- as.POSIXct(strptime(emissions$time, "%Y-%m-%d-%H"))
emissions <- emissions[order(emissions$time),]
rownames(emissions) <- 1:length(emissions$load)
emissions <- select(emissions, FACILITY_NAME, time, OP_DATE, OP_HOUR, OP_MONTH, grossgen_MWh=gload_MWh, CO2_tons, load)
emissions$load <- emissions$load*1000 #from MWh to kWh
#there is a NA value for load at 2010-01-01-23, replace with average load at 23:00
emissions$load[is.na(emissions$load)] <- 34517630 #this is average load for 23:00
#saveRDS(emissions, file="./reg_data.Rds") #this file is used in the problem set
