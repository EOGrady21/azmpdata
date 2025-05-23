## code to prepare `Derived_Annual_Stations` dataset
cat('Sourcing Derived_Annual_Stations.R', sep = '\n')
library(dplyr)
library(tidyr)
library(readr)
library(usethis)
library(RCurl)
source('inst/extdata/read_physical.R')

# load biochemical data
# HL2
cat('    reading in station2 biochemical data', sep = '\n')
HL2_env <- new.env()
con <- url("ftp://ftp.dfo-mpo.gc.ca/AZMP_Maritimes/azmpdata/data/biochemical/Halifax-2/Means&Anomalies_Annual.RData")
load(con, envir=HL2_env)
close(con)
# P5
cat('    reading in prince5 biochemical data', sep = '\n')
P5_env <- new.env()
con <- url("ftp://ftp.dfo-mpo.gc.ca/AZMP_Maritimes/azmpdata/data/biochemical/Prince-5/Means&Anomalies_Annual.RData")
load(con, envir=P5_env)
close(con)

# load physical data
cat('    reading in station2 physical integrated data', sep = '\n')

# integrated variables
url_name <- 'ftp://ftp.dfo-mpo.gc.ca/AZMP_Maritimes/azmpdata/data/physical/fixedStations/'

result <- getURL(url_name,
                 verbose=TRUE,ftp.use.epsv=TRUE, dirlistonly = TRUE)

filenames <- unlist(strsplit(result, "\r\n"))

# get relevant files
fn <- grep(filenames, pattern = '\\w+IntegratedVariables\\w+\\.dat', value = TRUE)

# create dataframe list
d <- list()
for(i in 1:length(fn)){
  con <- url(paste0(url_name, fn[[i]]))
  d[[i]] <- read.physical(con)
}

# vardat1 <- unlist(lapply(d, function(k) k[['data']][['integrated_temperature_0_50']]))
# vardat2 <- unlist(lapply(d, function(k) k[['data']][['integrated_salinity_0_50']]))
# vardat3 <- unlist(lapply(d, function(k) k[['data']][['integrated_sigmaTheta_0_50']]))
vardat1 <- unlist(lapply(d, function(k) as.numeric(k[['data']][['integrated_temperature_0_50']])))
vardat2 <- unlist(lapply(d, function(k) as.numeric(k[['data']][['integrated_salinity_0_50']])))
vardat3 <- unlist(lapply(d, function(k) as.numeric(k[['data']][['integrated_sigmaTheta_0_50']])))

stationName <- unlist(lapply(d, function(k) rep(k[['stationName']], dim(k[['data']])[1])))
year <- unlist(lapply(d, function(k) k[['data']][['year']]))

df <- data.frame(year = year,
                 station = stationName,
                 integrated_sea_temperature_0_50 = as.numeric(vardat1),
                 integrated_salinity_0_50 = as.numeric(vardat2),
                 integrated_sigmaTheta_0_50 = as.numeric(vardat3))
integratedvars <- df %>%
  dplyr::filter(year>=1999)

# temperature_in_air
cat('    reading in air temperature data', sep = '\n')
url_name <- 'ftp://ftp.dfo-mpo.gc.ca/AZMP_Maritimes/azmpdata/data/physical/airTemperature/'

result <- getURL(url_name,
                 verbose=TRUE,ftp.use.epsv=TRUE, dirlistonly = TRUE)

filenames <- unlist(strsplit(result, "\r\n"))

# get relevant files
fn <- grep(filenames, pattern = 'airTemperatureAnnualAnomaly\\w+\\.dat', value = TRUE)

# create dataframe list
d <- list()
for(i in 1:length(fn)){
  con <- url(paste0(url_name, fn[[i]]))

  d[[i]] <- read.physical(con)
}

# vardat <- unlist(lapply(d, function(k) k[['data']][['anomaly']] + as.numeric(k[['climatologicalMean']])))
vardat <- unlist(lapply(d, function(k) as.numeric(k[['data']][['anomaly']]) + as.numeric(k[['climatologicalMean']])))
stationName <- unlist(lapply(d, function(k) rep(k[['stationName']], dim(k[['data']])[1])))
year <- unlist(lapply(d, function(k) k[['data']][['year']]))

df <- data.frame(year = year,
                 station = stationName,
                 temperature_in_air = vardat)
airTemperature <- df %>%
  dplyr::filter(year>=1999)

#sea_surface_temperature_from_moorings
cat('    reading in sst in-situ data', sep = '\n')

url_name <- 'ftp://ftp.dfo-mpo.gc.ca/AZMP_Maritimes/azmpdata/data/physical/SSTinSitu/'

result <- getURL(url_name,
                 verbose=TRUE,ftp.use.epsv=TRUE, dirlistonly = TRUE)

filenames <- unlist(strsplit(result, "\r\n"))

# get relevant files
fn <- grep(filenames, pattern = 'SSTinSitu\\w+\\.dat', value = TRUE)

# BC
fn <- c("SSTinSitu_Halifax_en.dat", "SSTinSitu_StAndrews_en.dat")
#BC

# create dataframe list
d <- list()
for(i in 1:length(fn)){
  con <- url(paste0(url_name, fn[[i]]))

  d[[i]] <- read.physical(con)
}

vardat <- unlist(lapply(d, function(k) k[['data']][['anomaly']] + as.numeric(k[['climatologicalMean']])))
stationName <- unlist(lapply(d, function(k) rep(k[['stationName']], dim(k[['data']])[1])))
year <- unlist(lapply(d, function(k) k[['data']][['year']]))

df <- data.frame(year = year,
                 station = stationName,
                 sea_surface_temperature_from_moorings = vardat)
SSTinSitu <- df %>%
  dplyr::filter(year>=1999)


# get temperature_0 and temperature_90 for p5 and HL2
cat('    reading in station2 and prince5 0m and 90m temperature data', sep = '\n')

# 1. load in lookup tables for mission IDs

url_name <- 'ftp://ftp.dfo-mpo.gc.ca/AZMP_Maritimes/AZMP_Reporting/lookup/' # have to move lookup
result <- getURL(url_name,
                 verbose=TRUE,ftp.use.epsv=TRUE, dirlistonly = TRUE)

filenames <- unlist(strsplit(result, "\r\n"))
lookup <- lapply(paste0(url_name, filenames), read.csv)
missions <- do.call('rbind', lookup)

# 2. read in the data and combine
url_name <- 'ftp://ftp.dfo-mpo.gc.ca/AZMP_Maritimes/azmpdata/data/physical/fixedStations/'
result <- getURL(url_name,
                 verbose=TRUE,ftp.use.epsv=TRUE, dirlistonly = TRUE)

filenames <- unlist(strsplit(result, "\r\n"))
# get not integrated data
filenames <- grep(filenames, pattern = '*IntegratedVariables*', value = TRUE, invert = TRUE)

d <- list()
for(i in 1:length(filenames)){
  con <- url(paste0(url_name, filenames[[i]]))
  d[[i]] <- read.csv(con)
}

############################
# this requires to be fixed
############################
# d <- do.call('rbind', d)
d <- rbind(d[[3]], d[[2]])

# 3. match up cruiseNumber and mission_number
# note : if anything goes sideways matching up idx, the structure of idx will change
#        so it could become a list instead of a vector
idx <- apply(d, 1, function(k) {ok <- which(missions[['mission_name']] == k[['cruiseNumber']]);
if(length(ok) > 1) {
  ok[1]
} else if(length(ok) == 0){
  NA
} else {
  ok
}})

d <- cbind(d, descriptor = missions[['mission_descriptor']][idx])

fixedStationsPO <- d %>%
  dplyr::filter(year>=1999)

temp_0 <- fixedStationsPO[fixedStationsPO$pressure == 0,] %>%
  dplyr::select(station, cruiseNumber, year, month, day,
                longitude, latitude, pressure, temperature)

temp_90 <- fixedStationsPO[fixedStationsPO$pressure == 90,] %>%
  dplyr::select(station, cruiseNumber, year, month, day,
                longitude, latitude, pressure, temperature)

newdf <- rbind(temp_0, temp_90)

newdf2 <- newdf %>%
  dplyr::group_by(station, year, pressure) %>%
  dplyr::mutate(temperature_new = mean(temperature))

temperature_0_df <- newdf2[newdf2$pressure == 0,] %>%
  dplyr::rename(temperature_0 = temperature) %>%
  dplyr::distinct(year, .keep_all = TRUE) %>%
  dplyr::select(-temperature_new, -month, -day)

temperature_90_df <- newdf2[newdf2$pressure == 90,] %>%
  dplyr::rename(temperature_90 = temperature) %>%
  dplyr::distinct(year, .keep_all = TRUE)%>%
  dplyr::select(-temperature_new, -month, -day)

# assemble data
Derived_Annual_Stations <- dplyr::bind_rows(HL2_env$df_means,
                                            P5_env$df_means)

# clean up
rm(list=c("HL2_env", "P5_env"))

# target variables to include
target_var <- c("Chlorophyll 0-100" = "integrated_chlorophyll_0_100",
                "Nitrate 0-50" = "integrated_nitrate_0_50",
                "Nitrate 50-150" = "integrated_nitrate_50_150",
                "Phosphate 0-50" = "integrated_phosphate_0_50",
                "Phosphate 50-150" = "integrated_phosphate_50_150",
                "Silicate 0-50" = "integrated_silicate_0_50",
                "Silicate 50-150" = "integrated_silicate_50_150")

# print order
station_order <- c("HL2" = 1,
                   "P5" = 2)

# reformat data
Derived_Annual_Stations <- Derived_Annual_Stations %>%
  dplyr::filter(variable %in% names(target_var)) %>%
  dplyr::mutate(variable = unname(target_var[variable])) %>%
  tidyr::pivot_wider(names_from=variable, values_from=value) %>%
  dplyr::mutate(order_station = unname(station_order[station])) %>%
  dplyr::arrange(order_station, year) %>%
  dplyr::select(station, year, unname(target_var))

# add physical data
Derived_Annual_Stations <- Derived_Annual_Stations %>%
  dplyr::bind_rows(., SSTinSitu, airTemperature, temperature_0_df, temperature_90_df, integratedvars)

# save data to csv
readr::write_csv(Derived_Annual_Stations, "inst/extdata/csv/Derived_Annual_Stations.csv")

# save data to rda
usethis::use_data(Derived_Annual_Stations, overwrite = TRUE)
