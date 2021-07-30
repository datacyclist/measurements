##############################
# Wasserzaehlerdaten aufbereiten
#
# liegen in CSV-Files, eins pro Tag, pro Zeile ein Timestamp und pro Zeile eine Wh
#
# 20210730, Georg Russ
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
dat <- list.files(path="/home/russ/mnt/nas/zaehlerlog/", pattern="*wasserzaehler-ping.csv", full.names=TRUE) %>%
			map_df(~read_csv(.,col_names=FALSE))

# Zählerstände werden per Offset (aus abgelesenen Werten an bestimmtem Datum)
# und cumsum errechnet

df_m3 <- dat %>%
				mutate(
				 timestamp_utc = X1,
				 timestamp = as.POSIXct(format(timestamp_utc, tz='Europe/Zurich')),
				 l = X2,
				 datum = as.Date(timestamp, "%Y%m%d", tz='Europe/Zurich')
				) %>%
	filter(timestamp>=format(as.Date("20210501", "%Y%m%d"))) %>%
	group_by(datum) %>%
	summarise(
						datum = unique(datum),
						l = sum(l)
						) %>%
	ungroup() %>%
	#pivot_wider(names_from=ht_nt, values_from = Wh) %>%
	#replace_na(list(HT=0)) %>%
	arrange(datum) %>%
	mutate(
				 # 882 Liter am 19.06. sind komisch --> Korrektur mit Quartalsabrechnung
				 korrektur_q2_2021 = ifelse((datum>=format(as.Date("20210619", "%Y%m%d"))), 1, 0),
				 m3_cum = round(cumsum(l)/1000+376.900 - korrektur_q2_2021*0.8, digits=2)
				 #HT_stand_cum = cumsum(HT)/1000 + 4666,
				# NT_stand_cum = cumsum(NT)/1000 + 9269
				 ) %>%
	arrange(desc(datum)) %>%
	select(datum, m3_cum) %>%
  write_tsv(file=paste(cachedirprefix, filedateprefix, "-zaehlerstande-wasser_errechnet.csv", sep=""))

