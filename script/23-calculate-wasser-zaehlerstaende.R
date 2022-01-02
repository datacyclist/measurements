##############################
# Wasserzaehlerdaten aufbereiten
#
# liegen in CSV-Files, eins pro Tag, pro Zeile ein Timestamp und pro Zeile eine Wh
#
# 20211022, Georg Russ
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

# für millisekundengenaue Berechnungen Anzahl Nachkommastellen anpassen
options("digits.secs"=6)
options("lubridate.week.start"=1)

filedateprefix <- format(Sys.time(), "%Y%m%d")
figdirprefix <- '../figs/'
cachedirprefix <- '../cache/'

# Daten zur Quartalsabrechnung holen, dort manuelle Eintragung 4x im Jahr zum
# Korrigieren von Ablesefehlern -- dieser Data Frame wird später per Join an
# den Ablesewert-DF gehängt, um maschinelle Ablesefehler mit den offiziellen
# Ablesewerten zu korrigieren

dfquartal <- read_tsv("../csv/quartalsabrechnung.csv",
											comment="#") %>%
	mutate(
				 quartal = quarter(date),
				 jahr = year(date),
				 jq = paste(jahr,"Q",quartal, sep=""),
				 endstand_quartal = wasser,
				 verbrauch_quartal = wasser-lead(wasser),
				 endstand_vorquartal = lead(wasser)
				 ) %>%
	select(jq, endstand_quartal, verbrauch_quartal,endstand_vorquartal)

## Daten vom NAS holen, alle CSVs in einem bestimmten Verzeichnis
# (man könnte später auch diese CSVs löschen, wenn die Tagesstände einmal
# berechnet und abgelegt sind)

dat <- list.files(path="/home/russ/mnt/nas/zaehlerlog/", pattern="*wasserzaehler-ping.csv", full.names=TRUE) %>%
			map_df(~read_csv(.,col_names=FALSE))

# da der Wasserverbrauch auch mal null sein kann, sollen später für diese Nullverbrauchstage 
# trotzdem Zeilen angelegt werden
dummytage <- data.frame( datum = ymd(seq.Date(as.Date(min(dat$X1)),as.Date(max(dat$X1)), by='days'))) %>%
				arrange(desc(datum))

# Zählerstände werden per Offset (aus offiziellen Quartalsabrechnungen) und
# cumsum errechnet

df_m3 <- dat %>%
				mutate(
				 timestamp_utc = X1,
				 timestamp = as.POSIXct(format(timestamp_utc, tz='Europe/Zurich')),
				 l = X2,
				 datum = as.Date(timestamp, "%Y%m%d", tz='Europe/Zurich')
				) %>%
	filter(timestamp>=format(as.Date("20210501", "%Y%m%d"))) %>%
	group_by(datum) %>%
	# bestimme Verbrauch pro Tag und stelle Join-Key her für Quartalswerte
	summarise(
						datum = unique(datum),
						l = sum(l),
				 		quartal = quarter(datum),
				 		jahr = year(datum),
				 		jq = paste(jahr,"Q",quartal, sep="")
						) %>%
	ungroup() %>%
	left_join(dfquartal, by="jq") %>%
	arrange(datum) %>%
	# zuerst einfach nur alle Zählerstand-Pings kumulieren, korrigiert wird später
	mutate(
				 m3_cum = round(cumsum(l)/1000, digits=2),
				 ) %>%
	# Korrektur erfolgt pro Quartal mit Hilfe der Werte aus der offiziellen Quartalsabrechnung
	group_by(jq) %>%
	mutate(
				 # bestimme die selber per Zählerstand-Ping ermittelte Menge
				 min_m3_quartal = min(m3_cum),
				 max_m3_quartal = max(m3_cum),
				 ping_m3 = max_m3_quartal-min_m3_quartal,

				 # bestimme den Korrekturfaktor (pro Quartal)
				 korrekturfaktor_quartal = verbrauch_quartal/ping_m3,

				 # Korrekturfaktor fürs aktuelle noch nicht beendete Quartal ist 1
				 korrekturfaktor_quartal = ifelse(is.na(korrekturfaktor_quartal),1,korrekturfaktor_quartal),

				 # korrigiere jeden einzelnen Tageswert
				 l_korrigiert = round(l*korrekturfaktor_quartal,digits=0),

				 # berechne daraus den korrigierten Zählerstand
				 m3_cum_korrigiert = round(cumsum(l_korrigiert)/1000+endstand_vorquartal, digits=2)
				 ) %>%
	ungroup() %>%
	arrange(desc(datum)) %>%
	select(datum, m3_cum_korrigiert, l_korrigiert)

	# Fehlende Tage via join ergänzen und Zählerstand bzw. Tagesverbrauch nachführen

	df_m3 <- dummytage %>%
					left_join(df_m3) %>%
					fill(m3_cum_korrigiert,.direction='up') %>%
					mutate(l_korrigiert = replace_na(l_korrigiert, 0)) %>%
  write_tsv(file=paste(cachedirprefix, filedateprefix, "-zaehlerstande-wasser_errechnet.csv", sep=""))

