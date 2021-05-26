##############################
# Wasserzaehlerdaten aufbereiten
#
# liegen in CSV-Files, eins pro Tag, pro Zeile ein Timestamp und pro Zeile eine Wh
#
# 20210521, Georg Russ
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
				 datum = format(timestamp, "%Y%m%d")
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
				 m3_cum = round(cumsum(l)/1000+376.900, digits=2)
				 #HT_stand_cum = cumsum(HT)/1000 + 4666,
				# NT_stand_cum = cumsum(NT)/1000 + 9269
				 ) %>%
  write_csv(file=paste(cachedirprefix, filedateprefix, "-zaehlerstande-wasser_errechnet.csv", sep=""))

# der Offset zu den abgelesenen Zählerwerten steigt. Hm. Muss ich wohl mal
# beobachten. Vielleicht fehlen Blinkimpulse bei hohen Leistungen.

# Aus den _abgelesenen_ Werten die errechneten Tageswerte dazuholen:

# Eine Verbrauchszeile pro Tag:
# dfdays <- read_csv2(file=paste(cachedirprefix, "dfdays.csv" , sep =""))
# 
# df_days_for_join <- dfdays %>%
# 		filter(timestamp_day >=format(as.Date("20210301", "%Y%m%d"))) %>%
# 		arrange(timestamp_day) %>%
# 		mutate(
# 					 gas_kum = cumsum(verbrauch_gas_pro_tag_kWh),
# 					 wasser_kum = cumsum(verbrauch_wasser_pro_tag_l),
# 					 strom_ht_kum = cumsum(verbrauch_strom_ht_pro_tag_kWh),
# 					 strom_nt_kum = cumsum(verbrauch_strom_nt_pro_tag_kWh),
# 					 strom_HT_kum_blink = strom_ht_kum + 4666,
# 					 strom_NT_kum_blink = strom_nt_kum + 9269,
# 					 ) %>%
# 		select(timestamp_day, matches('kum')) %>%
# 		mutate(datum = format(as.Date(timestamp_day), "%Y%m%d"))
# 
# 
# dfplot <- df_kWh_ht_nt %>%
# 		inner_join(df_days_for_join, by='datum') %>%
# 		select(datum, HT_stand_cum, NT_stand_cum, strom_HT_kum_blink, strom_NT_kum_blink) %>%
# 		melt(id.vars='datum') %>%
# 		mutate(group = ifelse(grepl("NT", variable), "NT", "HT"))
# 
# strom_vergleich_plot <- ggplot(dfplot) +
# 	geom_line(aes(x=datum, y=value, group=variable, colour=variable), size=1.2) +
# 	#scale_colour_identity() +
# 	scale_colour_brewer(type='qual', direction=1) +
# 	facet_wrap(~group, ncol=1, scales='free_y') +
# 	theme_verbrauch() +
# 	labs(title=paste("Strom, abgelesen vs. Blink-LED, generiert ", filedateprefix, sep=""),
# 	     y = 'Kumulierter Wert [kWh]',
# 			 x = 'Datum'
# 			 ) +
# 	theme(axis.text.x=element_text(angle=90)) +
# 
# png(filename=paste(figdirprefix, filedateprefix, "-strom-zaehlerstaende.png", sep=''),
# 		width=1400, height=600)
#  print(strom_vergleich_plot)
# dev.off()