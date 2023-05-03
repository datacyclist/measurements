########################################
# Gastherme, Versuch Bestimmung Gasverbrauch aus Optolink-Log
# 
# 2023-05-03
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

# genauere Werte ab 27.05. -- Ablesefrequenz verdoppelt
	
##############################
# Daten aus Gastherme-Log holen
##############################

dft <- list.files(path="/home/russ/mnt/nas/zaehlerlog/gastherme/", pattern="20230.*optolinklog.csv", full.names=TRUE) %>%
			map_df(~read_delim(.,delim=" ", 
								 col_types = cols(.default = col_character()),
												 col_names=FALSE))

dftherme <- dft %>%
				select(X1,X19,X25,X29,X27) %>%
				arrange(X1) %>%
				mutate(timestamp=as.POSIXct(as.numeric(X1), origin="1970-01-01", tz="Europe/Zurich"),
							 unix_ts = X1,
							 X1=NULL,
							 brennerstunden=as.numeric(X29),
						 diff_brennerstunden_s = (brennerstunden-lag(brennerstunden))*3600,
							 X19=NULL,
						 # brennerleistung ist in % der maximalen Leistung?
							 brennerleistung_prozent=as.numeric(X25),
							 brennerleistung_kW = brennerleistung_prozent/100 * 16,
							 #X21=NULL,
				       diff_s = interval(lag(timestamp),timestamp)/hours(1)*3600,
							 Wh_grob = diff_s * brennerleistung_kW*1000 / 3600,

							 brennerstarts = as.numeric(X27),
							 brennerstarts_pro_zeitraum = replace_na(brennerstarts-lag(brennerstarts),0),

							 # moegliche Korrektur mittels Brennerdauer?
							 #diff_s_korrigiert = -1*(diff_brennerstunden_s-diff_s),
							 #Wh_korrigiert = diff_s_korrigiert * brennerleistung_kW*1000 / 3600
				 			 
							 )  %>%
				filter(brennerstarts_pro_zeitraum<5)



dftag_therme <- dftherme %>%
				mutate(tag = as.Date(timestamp)) %>%
				group_by(tag) %>%
				summarise(
									verbrauch_kWh_grob = sum(Wh_grob, na.rm=TRUE)/1000,
									verbrauch_m3_therme = verbrauch_kWh_grob/10.17,
									anz_brennerstarts=sum(brennerstarts_pro_zeitraum),
									anz_zeilen = n(),
									verbrauch_m3_therme_korrigiert = verbrauch_m3_therme*0.90,
									verbrauch_kWh_therme_korrigiert = verbrauch_kWh_grob*0.90
									#verbrauch_kWh_korrigiert = sum(Wh_korrigiert, na.rm=TRUE)/1000
									)

# Tagesverbraueche aus Ablesung:
tagverbrauch <- dat2 %>%
				mutate(
							 tag=timestamp,
							 monat=month(timestamp),
							 verbrauch_kWh_zaehler = (gas-lead(gas))*10.17
							 )

# Datenquellen joinen

dfverbraeuche <- tagverbrauch %>%
				right_join(dftag_therme, by=c("tag")) %>%
									 filter(monat<6)%>%
									 mutate(monat=as.factor(monat))

##############################
# Korrelationsplot (ein Punkt pro Tag)
##############################

corrplot <- ggplot(dfverbraeuche) +
	geom_point(aes(x=verbrauch_kWh_therme_korrigiert, y=verbrauch_kWh_zaehler,colour=anz_brennerstarts),  size=3.5,  alpha=0.85) +
	#geom_text(aes(x=verbrauch_kWh_therme_korrigiert, y=verbrauch_kWh_zaehler,label=tag),  size=6, colour="black", alpha=0.75, hjust=0) +
	#scale_colour_identity() +
	scale_fill_brewer(type='div', direction=1) +
	#facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	labs(title=paste("Gasverbrauch pro Tag, Ablesung vs. Optolink+Berechnung, generiert ", filedateprefix, sep=""),
	     x = 'kWh berechnet aus Optolink-Log',
			 y = 'kWh aus Zaehlerablesung'
			 ) +
  scale_x_continuous(limits=c(0,150)) +
  scale_y_continuous(limits=c(0,150)) +
	geom_abline(color="red", slope=1, intercept=0)


png(filename=paste(figdirprefix, filedateprefix, "_gasablesung-korrelation.png", sep=''),
		width=1300, height=1100)
 print(corrplot)
dev.off()


