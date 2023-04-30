##############################
# Stromzaehlerdaten aufbereiten
#
# kommen von Data-Dump des Shelly 3EM
#
# liegen in CSV-Files, eins pro Monat und Phase (L0/L1/L2), pro Zeile ein
# Timestamp minutengenau und dahinter die Werte fuer Wh_Netzbezug und
# Wh_eingespeist
#
# ueberlappende Tageswerte werden per JOIN eliminiert
#
# 20230430, Georg Russ
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
dat_L0 <- list.files(path="/home/russ/mnt/nas/zaehlerlog/", pattern="*strom-L0-dump.csv", full.names=TRUE) %>%
			map_df(~read_csv(.,col_names=TRUE))
dat_L1 <- list.files(path="/home/russ/mnt/nas/zaehlerlog/", pattern="*strom-L1-dump.csv", full.names=TRUE) %>%
			map_df(~read_csv(.,col_names=TRUE))
dat_L2 <- list.files(path="/home/russ/mnt/nas/zaehlerlog/", pattern="*strom-L2-dump.csv", full.names=TRUE) %>%
			map_df(~read_csv(.,col_names=TRUE))


# Abgenommene Strommenge in HT und NT aufteilen
#
# Mo-Fr 7-19 Uhr: HT
#
# sonst: NT
# 
# Zählerstände werden per Offset (aus abgelesenen Werten an bestimmtem Datum)
# und cumsum errechnet

# TODO: die CSVs haben vermutlich doppelte Einträge, da mehrere
# Monats-Datenabzüge gleichzeitig eingelesen werden. Muss z.B. noch mit
# unique() abgefangen werden, wenn mehrere Datenlieferungen da sind.

#####
# L0
#####

df_kWh_ht_nt_L0 <- dat_L0 %>%
				mutate(
				 timestamp_utc = `Date/time UTC`,
				 timestamp = as.POSIXct(format(timestamp_utc, tz='Europe/Zurich')),
				 Wh = `Active energy Wh (A)`,
				 Wh_returned = `Returned energy Wh (A)`,
				 wochentag = wday(timestamp),
				 stunde = hour(timestamp),
				 ht_nt = ifelse(
												(wochentag %in% c(1:5) & stunde %in% c(7:18)), 
												"HT", 
												"NT"),
				 datum = as.Date(timestamp, "%Y%m%d", tz='Europe/Zurich')
				) %>%
	unique() %>% # da mehrere Datenlieferungen gleichzeitig im df landen
	filter(timestamp>=format(as.Date("20230301", "%Y%m%d"))) %>%
	group_by(datum,ht_nt) %>%
	summarise(datum = unique(datum),
						Wh_L0 = sum(Wh),
						Wh_returned_L0 = sum(Wh_returned)
						) %>%
	ungroup()

#####
# L1
#####

df_kWh_ht_nt_L1 <- dat_L1 %>%
				mutate(
				 timestamp_utc = `Date/time UTC`,
				 timestamp = as.POSIXct(format(timestamp_utc, tz='Europe/Zurich')),
				 Wh = `Active energy Wh (B)`,
				 Wh_returned = `Returned energy Wh (B)`,
				 wochentag = wday(timestamp),
				 stunde = hour(timestamp),
				 ht_nt = ifelse(
												(wochentag %in% c(1:5) & stunde %in% c(7:18)), 
												"HT", 
												"NT"),
				 datum = as.Date(timestamp, "%Y%m%d", tz='Europe/Zurich')
				) %>%
	unique() %>% # da mehrere Datenlieferungen gleichzeitig im df landen
	filter(timestamp>=format(as.Date("20230301", "%Y%m%d"))) %>%
	group_by(datum,ht_nt) %>%
	summarise(datum = unique(datum),
						Wh_L1 = sum(Wh),
						Wh_returned_L1 = sum(Wh_returned)
						) %>%
	ungroup()

#####
# L2
#####

df_kWh_ht_nt_L2 <- dat_L2 %>%
				mutate(
				 timestamp_utc = `Date/time UTC`,
				 timestamp = as.POSIXct(format(timestamp_utc, tz='Europe/Zurich')),
				 Wh = `Active energy Wh (C)`,
				 Wh_returned = `Returned energy Wh (C)`,
				 wochentag = wday(timestamp),
				 stunde = hour(timestamp),
				 ht_nt = ifelse(
												(wochentag %in% c(1:5) & stunde %in% c(7:18)), 
												"HT", 
												"NT"),
				 datum = as.Date(timestamp, "%Y%m%d", tz='Europe/Zurich')
				) %>%
	unique() %>% # da mehrere Datenlieferungen gleichzeitig im df landen
	filter(timestamp>=format(as.Date("20230301", "%Y%m%d"))) %>%
	group_by(datum,ht_nt) %>%
	summarise(datum = unique(datum),
						Wh_L2 = sum(Wh),
						Wh_returned_L2 = sum(Wh_returned)
						) %>%
	ungroup()

##########
# L1, L2, L3 joinen auf datum und HT/NT
##########

# HT berechnen
df_kWh_ht <- df_kWh_ht_nt_L0 %>%
				left_join(df_kWh_ht_nt_L1, by=c('datum', 'ht_nt')) %>%
				left_join(df_kWh_ht_nt_L2, by=c('datum', 'ht_nt')) %>%
				filter(ht_nt == "HT") %>%
				mutate(
							 Wh_HT = Wh_L0+Wh_L1+Wh_L2,
							 Wh_returned_HT = Wh_returned_L0+Wh_returned_L1+Wh_returned_L2,
							 ht_nt = "HT")

df_kWh_nt <- df_kWh_ht_nt_L0 %>%
				left_join(df_kWh_ht_nt_L1, by=c('datum', 'ht_nt')) %>%
				left_join(df_kWh_ht_nt_L2, by=c('datum', 'ht_nt')) %>%
				filter(ht_nt == "NT") %>%
				mutate(
							 Wh_NT = Wh_L0+Wh_L1+Wh_L2,
							 Wh_returned_NT = Wh_returned_L0+Wh_returned_L1+Wh_returned_L2,
							 ht_nt = "NT")

df_kWh_ht_nt <- df_kWh_ht %>%
				full_join(df_kWh_nt, by = c('datum'))  %>%
				arrange(datum) %>%
				mutate(
							 Wh_HT = replace_na(Wh_HT, 0),
							 Wh_returned_HT = replace_na(Wh_returned_HT,0)
							 )  %>% # es gibt Tage, wo kein HT-Strom tarifiert wird (Samstag/Sonntag)
				# offset Zaehlerstand 28.02.2023 11644 kWh NT, 6348 kWh HT
				mutate(
							 HT_stand = round(cumsum(Wh_HT)/1000 + 6348 , digits=3),
							 NT_stand = round(cumsum(Wh_NT)/1000 + 11644, digits=3),
							 HT_stand_returned = round(cumsum(Wh_returned_HT)/1000, digits=3),
							 NT_stand_returned = round(cumsum(Wh_returned_NT)/1000, digits=3)
							 ) %>%
				select(datum, HT_stand, NT_stand, HT_stand_returned, NT_stand_returned) %>%
				arrange(desc(datum)) %>%
  			write_tsv(file=paste(cachedirprefix, filedateprefix, "-zaehlerstande-strom_errechnet.csv", sep=""))

if(FALSE){

# siehe https://dc.georgruss.ch/2021/03/27/stromzahlerwerte-passen-ja-doch/
# Denkfehler gehabt :-) 

# der Offset zu den abgelesenen Zählerwerten steigt. Hm. Muss ich wohl mal
# beobachten. Vielleicht fehlen Blinkimpulse bei hohen Leistungen.

# Aus den _abgelesenen_ Werten die errechneten Tageswerte dazuholen:

# Eine Verbrauchszeile pro Tag:
dfdays <- read_csv2(file=paste(cachedirprefix, "dfdays.csv" , sep =""))

df_days_for_join <- dfdays %>%
		filter(timestamp_day >=format(as.Date("20210301", "%Y%m%d"))) %>%
		arrange(timestamp_day) %>%
		mutate(
					 gas_kum = cumsum(verbrauch_gas_pro_tag_kWh),
					 wasser_kum = cumsum(verbrauch_wasser_pro_tag_l),
					 strom_ht_kum = cumsum(verbrauch_strom_ht_pro_tag_kWh),
					 strom_nt_kum = cumsum(verbrauch_strom_nt_pro_tag_kWh),
					 strom_HT_kum_blink = strom_ht_kum + 4666,
					 strom_NT_kum_blink = strom_nt_kum + 9269,
					 ) %>%
		select(timestamp_day, matches('kum')) %>%
		mutate(datum = format(as.Date(timestamp_day), "%Y%m%d"))


dfplot <- df_kWh_ht_nt %>%
		inner_join(df_days_for_join, by='datum') %>%
		select(datum, HT_stand_cum, NT_stand_cum, strom_HT_kum_blink, strom_NT_kum_blink) %>%
		melt(id.vars='datum') %>%
		mutate(group = ifelse(grepl("NT", variable), "NT", "HT"))

strom_vergleich_plot <- ggplot(dfplot) +
	geom_line(aes(x=datum, y=value, group=variable, colour=variable), size=1.2) +
	#scale_colour_identity() +
	scale_colour_brewer(type='qual', direction=1) +
	facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	labs(title=paste("Strom, abgelesen vs. Blink-LED, generiert ", filedateprefix, sep=""),
	     y = 'Kumulierter Wert [kWh]',
			 x = 'Datum'
			 ) +
	theme(axis.text.x=element_text(angle=90)) +

png(filename=paste(figdirprefix, filedateprefix, "-strom-zaehlerstaende.png", sep=''),
		width=1400, height=600)
 print(strom_vergleich_plot)
dev.off()
}
