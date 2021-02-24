# Stromzaehlerdaten aufbereiten
#
# liegen in CSV-Files, eins pro Tag, pro Zeile ein Timestamp und pro Zeile eine Wh
#

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

filedateprefix <- format(Sys.time(), "%Y%m%d")
figdirprefix <- 'figs/'
cachedirprefix <- 'cache/'

# Daten vom NAS holen, alle CSVs in einem bestimmten Verzeichnis
dat <- list.files(path="/home/russ/mnt/nas/zaehlerlog/", pattern="*.csv", full.names=TRUE) %>%
			map_df(~read_csv(.,col_names=FALSE))

df <- dat %>%
	mutate(
				 timestamp = X1,
				 Wh = X2,
				 diff_h = interval(lag(timestamp),timestamp)/hours(1),
				 diff_s = interval(lag(timestamp),timestamp)/hours(1)*3600,
				 Leistung = Wh/diff_h
				 )

df_hours <- df %>%
				mutate(tagstunde = as.factor(format(timestamp, format="%Y%m%d-%H"))) %>%
				group_by(tagstunde) %>%
				summarise(E_el_Wh = sum(Wh))
			

########################################
# Abgenommene Leistung aktueller Tag (bisher)
########################################

dfplot <- df %>%
		mutate(datum = format(timestamp, format="%Y%m%d")) %>%
		#filter(datum == format(Sys.time()-days(1), "%Y%m%d"))
		filter(datum == format(Sys.time(), "%Y%m%d"))

leistungsplot <- ggplot(dfplot) +
	geom_line(aes(x=timestamp, y=Leistung), colour='black',  size=0.5) +
	#scale_colour_identity() +
	#facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	labs(title=paste("Elektrische Leistung OD10 im Zeitverlauf, ", format(Sys.time(), "%Y%m%d"), sep=""),
	     y = 'Leistung [W]',
			 x = 'Zeitachse'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_eel_leistung_verlauf.png", sep=''),
		width=1400, height=600)
 print(leistungsplot)
dev.off()
