#library(ggplot2)
#library(gridExtra)
#library(xtable)
#library(dplyr)
#library(lubridate)
#library(reshape2)

#source("theme-verbrauch.R")

filedateprefix <- format(Sys.time(), "%Y%m%d")
figdirprefix <- '../figs/'
cachedirprefix <- '../cache/'

library(tidyverse)
library(googlesheets4)
library(readr)

if(!(file.exists(file=paste(cachedirprefix, filedateprefix, "-ablesewerte.csv", sep="")))){
# google sheet laden
gs4_deauth()
url <- 'https://docs.google.com/spreadsheets/d/1EMdrNK8iAGyXFGwIzJs5_I4GsUNWjeQbs99dcXeuMzs/edit?usp=sharing'
#dat <- read_sheet(url)

dat <- read_sheet(url) %>%
	rename(timestamp = Zeitstempel,
				 strom_tag = 'Strom Wert 1.8.1 [kWh]',
				 strom_nacht = 'Strom Wert 1.8.2 [kWh]',
				 gas = Gas,
				 wasser = Wasser) %>%
	mutate(gas = as.numeric(gas),
				 wasser = as.numeric(wasser)
				 )

write_csv(x=dat, path=paste(cachedirprefix, filedateprefix, "-ablesewerte.csv", sep=""))
}

