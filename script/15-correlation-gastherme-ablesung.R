########################################
# Gastherme, Bestimmung Gasverbrauch aus Optolink-Log
# 
# 2021-05-26
#
# - Zählerstände aus CSV
# - Betriebsdauer aus Heizungslog
# 
########################################

library(tidyverse)
library(ggplot2)
library(gridExtra)
library(xtable)
library(dplyr)
library(googlesheets4)
library(lubridate)
library(reshape2)
library(readr)

source("theme-verbrauch.R")
#source("08-grundpreise.R")

# wird nicht mehr gebraucht, da ich nicht mehr in den Keller muss
# source("05-read-googlesheet.R") 

options("lubridate.week.start"=1)

filedateprefix <- format(Sys.time(), "%Y%m%d")
figdirprefix <- '../figs/'
cachedirprefix <- '../cache/'
# Ablesewerte wurden hier manuell abgelegt
csvdirprefix <- '../csv/'

##############################
# Ablesewerte holen
##############################

# archivierte Ablesewerte aus dem Google-Sheet...
dat1 <- read_csv(file=paste(csvdirprefix, "20210410-ablesewerte.csv", sep=""))
# ...und die aktuellen Ablesewerte
dat2 <- read_tsv(file=paste(csvdirprefix, "ablesewerte-zum-eintragen.csv", sep=""))

# ...zusammenhängen (Reihenfolge von dat1 vorher an dat2 anpassen)
dat <- dat1 %>%
	select(timestamp,strom_tag, strom_nacht, gas, wasser, kommentar) %>%
	rbind(dat2) %>%
	arrange((timestamp)) %>%
	mutate(tag = as.Date(timestamp),
				 gas_kWh = gas*10.17) %>%
	select(tag, gas_kWh) %>%
	mutate(diff_gas = gas_kWh-lag(gas_kWh))
	
##############################
# Daten aus Gastherme-Log holen
##############################

dft <- list.files(path="/home/russ/mnt/nas/zaehlerlog/gastherme/", pattern="*optolinklog.csv", full.names=TRUE) %>%
			map_df(~read_delim(.,delim=" ", 
								 col_types = cols(.default = col_character()),
												 col_names=FALSE))

dftherme <- dft %>%
				select(X1,X19,X21) %>%
				arrange(X1) %>%
				mutate(timestamp=as.POSIXct(as.numeric(X1), origin="1970-01-01", tz="Europe/Zurich"),
							 unix_ts = X1,
							 X1=NULL,
							 brennerstunden=as.numeric(X19),
						 diff_brennerstunden_s = (brennerstunden-lag(brennerstunden))*3600,
							 X19=NULL,
						 # brennerleistung ist in % der maximalen Leistung?
							 brennerleistung_prozent=as.numeric(X21),
							 brennerleistung_kW = brennerleistung_prozent/100 * 21,
							 X21=NULL,
				       diff_s = interval(lag(timestamp),timestamp)/hours(1)*3600,
							 Wh_grob = diff_s * brennerleistung_kW*1000 / 3600,
							 # moegliche Korrektur mittels Brennerdauer?
							 diff_s_korrigiert = -1*(diff_brennerstunden_s-diff_s),
							 Wh_korrigiert = diff_s_korrigiert * brennerleistung_kW*1000 / 3600
				 			 
							 ) 



dftag <- dftherme %>%
				mutate(tag = as.Date(timestamp)) %>%
				group_by(tag) %>%
				summarise(
									verbrauch_kWh_grob = sum(Wh_grob, na.rm=TRUE)/1000,
									verbrauch_kWh_korrigiert = sum(Wh_korrigiert, na.rm=TRUE)/1000
									)


dfcorr <- dftag %>%
				inner_join(dat) %>%
				filter(tag > as.Date("2021-05-14")) 
				#filter(tag < as.Date("2021-05-26"))

#df22 <- dftherme %>%
#				mutate(tag=as.Date(timestamp)) %>%
#				filter(tag == as.Date("2021-05-22")) %>%
#				mutate(stunde = hour(timestamp))

# negative Werte? Hae?
#dfneg <- dftherme %>%
#				filter(diff_s<0)

# ganz grosse  Werte? Hae?
#dfhoch <- dftherme %>%
#				filter(diff_brennerstunden_s>66)

##############################
# Korrelationsplot (ein Punkt pro Tag)
##############################

corrplot <- ggplot(dfcorr) +
	geom_point(aes(x=diff_gas, y=verbrauch_kWh_grob),  size=3.5, colour="dodgerblue", alpha=0.75) +
	#scale_colour_identity() +
	#scale_fill_brewer(type='qual', direction=1) +
	#facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	labs(title=paste("Gasverbrauch pro Tag, Ablesung vs. Optolink+Berechnung, generiert ", filedateprefix, sep=""),
	     y = 'kWh berechnet aus Optolink-Log',
			 x = 'kWh aus Zaehlerablesung'
			 ) +
  scale_x_continuous(limits=c(0,30)) +
  scale_y_continuous(limits=c(0,30)) +
	geom_abline(color="red", slope=1, intercept=0)


png(filename=paste(figdirprefix, filedateprefix, "_gasablesung-korrelation.png", sep=''),
		width=1100, height=1000)
 print(corrplot)
dev.off()


