# Stromzaehlerdaten aufbereiten
#
# liegen in CSV-Files, eins pro Tag, pro Zeile ein Timestamp und pro Zeile eine Wh
#
# 20200227, Georg Russ

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
#source("05-read-googlesheet.R")
#source("08-grundpreise.R")

# für millisekundengenaue Berechnungen Anzahl Nachkommastellen anpassen
options("digits.secs"=6)

filedateprefix <- format(Sys.time(), "%Y%m%d")
figdirprefix <- '../figs/'
cachedirprefix <- '../cache/'

vortag <- format(Sys.time()-days(1), "%Y%m%d")
dat_gestern <- read_csv(file=paste("/home/russ/mnt/nas/zaehlerlog/", vortag, '-stromzaehler-ping.csv', sep=""),
								col_names=FALSE)

## Daten vom NAS holen, alle CSVs in einem bestimmten Verzeichnis
#dat <- list.files(path="/home/russ/mnt/nas/zaehlerlog/", pattern="*.csv", full.names=TRUE) %>%
#			map_df(~read_csv(.,col_names=FALSE))

df <- dat_gestern %>%
	mutate(
				 timestamp_utc = X1,
				 timestamp = as.POSIXct(format(timestamp_utc, tz='Europe/Zurich')),
				 Wh = X2,
				 diff_h = interval(lag(timestamp),timestamp)/hours(1),
				 diff_s = interval(lag(timestamp),timestamp)/hours(1)*3600,
				 Leistung = Wh/diff_h
				 )

df_hours <- df %>%
				mutate(
							 tagstunde = as.factor(format(timestamp, format="%Y%m%d-%H")),
							 datum = format(timestamp, format="%Y%m%d")
							 ) %>%
				group_by(tagstunde) %>%
				summarise(
									E_el_Wh = sum(Wh),
									datum = unique(datum))

df_minutes <- df %>%
				mutate(
							 dhm = as.factor(format(timestamp, format="%Y%m%d-%H%M")),
							 datum = format(timestamp, format="%Y%m%d")
							 ) %>%
				group_by(dhm) %>%
				summarise(
									E_el_Wh = sum(Wh),
									datum = unique(datum))
			
########################################
# Abgenommene Leistung Vortag 
########################################

datevortag <- format(Sys.time()-days(1), "%Y%m%d")

dfplot <- df %>%
		mutate(datum = format(timestamp, format="%Y%m%d")) %>%
		filter(datum == format(Sys.time()-days(1), "%Y%m%d"))
		#filter(datum == format(Sys.time(), "%Y%m%d"))

leistungsplot <- ggplot(dfplot) +
	geom_line(aes(x=timestamp, y=Leistung), colour='black',  size=0.5) +
	#scale_colour_identity() +
	#facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	labs(title=paste("Elektrische Leistung OD10 im Zeitverlauf, ", datevortag, sep=""),
	     y = 'Leistung [W]',
			 x = 'Zeitachse'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_eel_leistung_verlauf.png", sep=''),
		width=1400, height=600)
 print(leistungsplot)
dev.off()


########################################
# Abgenommene Energie Vortag (Stundenplot)
########################################

datevortag <- format(Sys.time()-days(1), "%Y%m%d")

dfplot <- df_hours %>%
#		mutate(datum = format(timestamp, format="%Y%m%d")) %>%
		filter(datum == datevortag)
#		#filter(datum == format(Sys.time(), "%Y%m%d"))

energie_h_plot <- ggplot(dfplot) +
	geom_col(aes(x=tagstunde, y=E_el_Wh), colour='black',  size=0.5) +
	#scale_colour_identity() +
	#facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	theme(axis.text.x=element_text(angle=90)) +
	#theme(axis.text.x
	labs(title=paste("Elektrische Energie OD10 im Zeitverlauf, ", datevortag, sep=""),
	     y = 'Energie [Wh]',
			 x = 'Zeitachse'
			 )

png(filename=paste(figdirprefix, filedateprefix, "-", datevortag, "_eel_stunden_verlauf.png", sep=''),
		width=1400, height=600)
 print(energie_h_plot)
dev.off()


########################################
# Abgenommene Energie Vortag (Minutenplot)
########################################

datevortag <- format(Sys.time()-days(1), "%Y%m%d")

dfplot <- df_minutes %>%
#		mutate(datum = format(timestamp, format="%Y%m%d")) %>%
		filter(datum == datevortag) %>%
		mutate(dhm = as.factor(dhm))
#		#filter(datum == format(Sys.time(), "%Y%m%d"))

energie_minutes_plot <- ggplot(dfplot) +
	geom_line(aes(x=dhm, y=E_el_Wh), group=1, colour='black',  size=0.5) +
	theme_verbrauch() +
	theme(axis.text.x=element_text(angle=90)) +
	scale_x_discrete(breaks = levels(dfplot$dhm)[1:8000*60]) +
	labs(title=paste("Elektrische Energie OD10, minutenbasiert, ", datevortag, sep=""),
	     y = 'Energie [Wh]',
			 x = 'Zeitachse'
			 )

png(filename=paste(figdirprefix, filedateprefix, "-", datevortag, "_eel_minuten_verlauf.png", sep=''),
		width=1400, height=600)
 print(energie_minutes_plot)
dev.off()
