##############################
# Stromzaehlerdaten aufbereiten
#
# liegen in CSV-Files, eins pro Tag, pro Zeile ein Timestamp und pro Zeile eine Wh
#
# 20210313, Georg Russ
##############################

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
options("lubridate.week.start"=1)

filedateprefix <- format(Sys.time(), "%Y%m%d")
figdirprefix <- '../figs/'
cachedirprefix <- '../cache/'

#vortag <- format(Sys.time()-days(1), "%Y%m%d")
#dat_gestern <- read_csv(file=paste("/home/russ/mnt/nas/zaehlerlog/", vortag, '-stromzaehler-ping.csv', sep=""),
#								col_names=FALSE)

## Daten vom NAS holen, alle CSVs in einem bestimmten Verzeichnis
dat <- list.files(path="/home/russ/mnt/nas/zaehlerlog/", pattern="*.csv", full.names=TRUE) %>%
			map_df(~read_csv(.,col_names=FALSE))

# Abgenommene Strommenge in HT und NT aufteilen
#
# Mo-Fr 7-19 Uhr: HT
#
# sonst: NT
# 
# Zählerstände werden per Offset (aus abgelesenen Werten an bestimmtem Datum)
# und cumsum errechnet

df_kWh_ht_nt <- dat %>%
				mutate(
				 timestamp_utc = X1,
				 timestamp = as.POSIXct(format(timestamp_utc, tz='Europe/Zurich')),
				 Wh = X2,
				 wochentag = wday(timestamp),
				 stunde = hour(timestamp),
				 ht_nt = ifelse(
												(wochentag %in% c(1:5) & stunde %in% c(7:19)), 
												"HT", 
												"NT"),
				 datum = format(timestamp, "%Y%m%d")
				) %>%
	filter(timestamp>=format(as.Date("20210301", "%Y%m%d"))) %>%
	group_by(datum,ht_nt) %>%
	summarise(datum = unique(datum),
						Wh = sum(Wh)
						) %>%
	ungroup() %>%
	pivot_wider(names_from=ht_nt, values_from = Wh) %>%
	replace_na(list(HT=0)) %>%
	arrange(datum) %>%
	mutate(
				 HT_stand_cum = cumsum(HT)/1000 + 4666,
				 NT_stand_cum = cumsum(NT)/1000 + 9269
				 ) %>%
  write_csv(path=paste(cachedirprefix, filedateprefix, "-zaehlerstande-strom_errechnet.csv", sep=""))

# der Offset zu den abgelesenen Zählerwerten steigt. Hm. Muss ich wohl mal
# beobachten. Vielleicht fehlen Blinkimpulse bei hohen Leistungen.
