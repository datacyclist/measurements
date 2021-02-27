#########################################
# Stromzaehlerdaten aufbereiten
#
# liegen in CSV-Files, eins pro Tag, pro Zeile ein Timestamp und pro Zeile eine Wh
#
# Hier nur Werte der letzten 24h berechnen (Energie auf Stundenbasis und Leistungskurve)
#########################################

library(tidyverse)
library(ggplot2)
library(gridExtra)
library(xtable)
library(dplyr)
library(googlesheets4)
library(lubridate)
library(reshape2)
library(readr)

# für millisekundengenaue Berechnungen Anzahl Nachkommastellen anpassen
options("digits.secs"=6)

source("theme-verbrauch.R")
#source("05-read-googlesheet.R")
#source("08-grundpreise.R")

filedateprefix <- format(Sys.time(), "%Y%m%d")
figdirprefix <- 'figs/'
cachedirprefix <- 'cache/'

currenttime <- Sys.time()

# Daten vom NAS holen, alle CSVs in einem bestimmten Verzeichnis

# nur aktueller Tag...

dat_heute <- read_csv(file=paste("/home/russ/mnt/nas/zaehlerlog/", filedateprefix, '-stromzaehler-ping.csv', sep=""),
								col_names=FALSE)

# ... und Vortag
vortag <- format(Sys.time()-days(1), "%Y%m%d")
dat_gestern <- read_csv(file=paste("/home/russ/mnt/nas/zaehlerlog/", vortag, '-stromzaehler-ping.csv', sep=""),
								col_names=FALSE)

# Daten aneinanderhängen
dat <- data.frame()
dat <- rbind(dat_gestern, dat_heute)

df <- dat %>%
	mutate(
				 timestamp_utc = X1,
				 timestamp = as.POSIXct(format(timestamp_utc, tz='Europe/Zurich')),
				 Wh = X2,
				 diff_h = interval(lag(timestamp),timestamp)/hours(1),
				 diff_s = interval(lag(timestamp),timestamp)/hours(1)*3600,
				 #diff_s1 = difftime(lag(timestamp), timestamp, units='secs'),
				 Leistung = Wh/diff_h
				 )


########################################
# Abgenommene Leistung letzte 24h
########################################

dfplot <- df %>%
		#mutate(datum = format(timestamp, format="%Y%m%d")) %>%
		#filter(datum == format(Sys.time()-days(1), "%Y%m%d"))
		filter(timestamp > (currenttime-days(1)))

leistungsplot24h <- ggplot(dfplot) +
	geom_line(aes(x=timestamp, y=Leistung), colour='black',  size=0.5) +
	#scale_colour_identity() +
	#facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	labs(title=paste("Elektrische Leistung OD10, letzte 24h, generiert ", currenttime, sep=""),
	     y = 'Leistung [W]',
			 x = 'Zeitachse'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_eel_24h_verlauf.png", sep=''),
		width=1400, height=600)
 print(leistungsplot24h)
dev.off()


########################################
# Abgenommene Energie letzte 24h (Stundenplot)
########################################

df_hours <- df %>%
				mutate(
							 tagstunde = as.factor(format(timestamp, format="%Y%m%d-%H")),
							 datum = format(timestamp, format="%Y%m%d")
							 ) %>%
				filter(timestamp > (currenttime-days(1))) %>%
				group_by(tagstunde) %>%
				summarise(
									E_el_Wh = sum(Wh),
									datum = unique(datum))

#	df_minutes <- df %>%
#					mutate(
#								 dhm = as.factor(format(timestamp, format="%Y%m%d-%H%M")),
#								 datum = format(timestamp, format="%Y%m%d")
#								 ) %>%
#					group_by(dhm) %>%
#					summarise(
#										E_el_Wh = sum(Wh),
#										datum = unique(datum))
#				
#	

energie_h_plot <- ggplot(df_hours) +
	geom_col(aes(x=tagstunde, y=E_el_Wh), fill='dodgerblue', colour='black',  size=0.5) +
	geom_text(aes(x=tagstunde, y=E_el_Wh+50, label=E_el_Wh), size=7) +
	#scale_colour_identity() +
	#facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	theme(axis.text.x=element_text(angle=90)) +
	#theme(axis.text.x
	labs(title=paste("Elektrische Energie OD10 letzte 24h, generiert ", currenttime, sep=""),
	     y = 'Energie pro Zeitstunde, [Wh]',
			 x = 'Zeitachse'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_eel_24h_stunden_verlauf.png", sep=''),
		width=1400, height=600)
 print(energie_h_plot)
dev.off()
