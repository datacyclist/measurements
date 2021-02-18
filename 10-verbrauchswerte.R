# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# \documentclass[10pt,a4paper]{article}
# \usepackage[german]{babel}
# \usepackage{mathpazo}
# \renewcommand{\sfdefault}{lmss}
# \renewcommand{\ttdefault}{lmtt}
# \usepackage[T1]{fontenc}
# \usepackage[utf8]{inputenc}
# \usepackage{geometry}
# \geometry{verbose,tmargin=2.0cm,bmargin=2.0cm,lmargin=2.0cm,rmargin=2.0cm}
# \usepackage{url}
# 
# \author{Georg Russ}
# \date{\today}
# \title{Verbrauchs{\"u}bersicht Oberdorfstr. 10}
# 
# \begin{document}
# \maketitle
# 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# 
# <<auswertung, echo=FALSE>>=
#library(zoo)

library(tidyverse)
library(ggplot2)
library(gridExtra)
library(xtable)
library(dplyr)
library(googlesheets4)
library(lubridate)
library(reshape2)

source("theme-verbrauch.R")

filedateprefix <- format(Sys.time(), "%Y%m%d")
figdirprefix <- 'figs/'

# google sheet laden

gs4_deauth()

url <- 'https://docs.google.com/spreadsheets/d/1EMdrNK8iAGyXFGwIzJs5_I4GsUNWjeQbs99dcXeuMzs/edit?usp=sharing'
dat <- read_sheet(url)

df <- dat %>%
	rename(timestamp = Zeitstempel,
				 strom_tag = 'Strom Wert 1.8.1 [kWh]',
				 strom_nacht = 'Strom Wert 1.8.2 [kWh]',
				 gas = Gas,
				 wasser = Wasser) %>%
	mutate(gas = as.numeric(gas),
				 wasser = as.numeric(wasser),
				 diff_h = interval(lag(timestamp),timestamp)/hours(1),
				 diff_gas = gas - lag(gas),
				 diff_wasser = wasser - lag(wasser),
				 diff_strom_ht = strom_tag-lag(strom_tag),
				 diff_strom_nt = strom_nacht-lag(strom_nacht),
				 #verbrauch_gas_pro_tag_m3 = diff_gas/diff_h*24,
				 verbrauch_gas_pro_tag_kWh = diff_gas/diff_h*24*10.17,
				 verbrauch_wasser_pro_tag_l = diff_wasser/diff_h*24*1000,
				 verbrauch_strom_ht_pro_tag_kWh = diff_strom_ht/diff_h*24,
				 verbrauch_strom_nt_pro_tag_kWh = diff_strom_nt/diff_h*24,
				 verbrauch_strom_gesamt_pro_tag = verbrauch_strom_ht_pro_tag_kWh + verbrauch_strom_nt_pro_tag_kWh,
				 timestamp_orig = timestamp,
				 timestamp = lag(timestamp),
				 datum = as.Date(timestamp_orig)
				 )
	# join with df to fill missing values
	
	datedf <- data.frame(datum=seq.Date(min(df$datum),max(df$datum),by="day"))

###############################
# Verbrauchswerte und Plot dazu
###############################

df1 <- datedf %>%
	left_join(df, by='datum') %>%
	fill(verbrauch_gas_pro_tag_kWh, .direction='up') %>%
	fill(verbrauch_wasser_pro_tag_l, .direction='up') %>%
	fill(verbrauch_strom_nt_pro_tag_kWh, .direction='up') %>%
	fill(verbrauch_strom_ht_pro_tag_kWh, .direction='up') %>%
	fill(verbrauch_strom_gesamt_pro_tag, .direction='up') %>%
	mutate(abgelesen_flag = ifelse(is.na(timestamp_orig), FALSE, TRUE))

dfplot <- df1 %>%
		select(datum, abgelesen_flag, starts_with('verbrauch')) %>%
		melt(id.vars=c('datum', 'abgelesen_flag')) %>%
		#filter(!(is.na(value))) %>%
		mutate(group = case_when(
														 grepl('strom',variable) ~ 'Strom [kWh]',
														 grepl('wasser', variable) ~ 'Wasser [Liter]',
														 #grepl('gas', variable) ~ 'Gas [m3 und kWh]'
														 grepl('gas', variable) ~ 'Gas [kWh]'
														 ) ,
					abgelesen_colour = as.factor(ifelse(abgelesen_flag, 'black', 'gray'))
		)

verbrauchsplot <- ggplot(dfplot) +
 #aes(x=timestamp,y=value)) +
	#geom_line(aes(x=timestamp, y=value, group=variable, colour=variable), size=1) +
	#geom_point(aes(x=timestamp, y=value, group=variable, colour=variable), size=1) +
	geom_col(aes(x=datum, y=value, group=variable, fill=variable, color=abgelesen_colour), position='dodge', size=0.3) +
	scale_colour_identity() +
	#geom_smooth(aes(x=datum, y=value, group=variable, colour=variable), size=1) +
	facet_wrap(~group, ncol=1, scales='free_y') +
#	geom_smooth(aes(y=Schnitt), colour="orange", size=2) +
	#scale_y_continuous(limits=c(0,300)) +
	theme_verbrauch() +
	labs(title="Verbrauchswerte OD10 im Zeitverlauf",
	     y = 'Wert in jew. Einheit [l bzw. kWh]',
			 x = 'Datum'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_verbrauchsverlauf.png", sep=''),
		width=1400, height=600)
 print(verbrauchsplot)
dev.off()

###############################
# Verbrauchs*kosten* und Plot dazu
###############################

# alles Bruttokosten, d.h. inkl. MWSt. (7.7% Gas/Strom, 2.5% Wasser)

df2 <- datedf %>%
	left_join(df, by='datum') %>%
	fill(verbrauch_gas_pro_tag_kWh, .direction='up') %>%
	fill(verbrauch_wasser_pro_tag_l, .direction='up') %>%
	fill(verbrauch_strom_nt_pro_tag_kWh, .direction='up') %>%
	fill(verbrauch_strom_ht_pro_tag_kWh, .direction='up') %>%
	fill(verbrauch_strom_gesamt_pro_tag, .direction='up') %>%
	mutate(abgelesen_flag = ifelse(is.na(timestamp_orig), FALSE, TRUE)) %>%
	mutate(
				 bezug_wasser = verbrauch_wasser_pro_tag_l/1000*1.28*1.025, # bei 100l etwa 13 Rp. pro Tag
				 bezug_gas = verbrauch_gas_pro_tag_kWh *(5.17+1.88)*1.077, # etwa 7.6 Rp. pro kWh
				 bezug_strom_ht = verbrauch_strom_ht_pro_tag_kWh*(8.19+9.91)*1.077, # etwa 20 Rp. pro kWh Normallast
				 bezug_strom_nt = verbrauch_strom_nt_pro_tag_kWh*(7.11+6.14)*1.077, # etwa 14 Rp. pro kWh Schwachlast
				 bezug_strom_sdl_kev_abgaben = (verbrauch_strom_ht_pro_tag_kWh+verbrauch_strom_nt_pro_tag_kWh)*(0.17+3.73)*1.077, # 4 Rp. pro kWh
				 grundpreis_wasser = (10.25*1.025/30*100), # etwa 35 Rp. pro Tag
				 grundpreis_gas = (6.46*1.077/30*100), # etwa 23 Rp. pro Tag
				 grundpreis_strom = (7.00*1.077/30*100) # etwa 25 Rp. pro Tag
				 )

dfplot2 <- df2 %>%
		select(datum, abgelesen_flag, starts_with(c('grundpreis', 'bezug'))) %>%
		melt(id.vars=c('datum', 'abgelesen_flag')) %>%
		#filter(!(is.na(value))) %>%
		mutate(group = case_when(
														 grepl('bezug',variable) ~ 'Verbrauch',
														 grepl('grundpreis', variable) ~ 'Fixkosten'
														 #grepl('gas', variable) ~ 'Gas [m3 und kWh]'
														 #grepl('gas', variable) ~ 'Gas [kWh]'
														 ),
					abgelesen_colour = as.factor(ifelse(abgelesen_flag, 'black', 'gray')),
					variable = fct_reorder(variable, desc(variable))
		)

kostenplot <- ggplot(dfplot2) +
 #aes(x=timestamp,y=value)) +
	#geom_line(aes(x=timestamp, y=value, group=variable, colour=variable), size=1) +
	#geom_point(aes(x=timestamp, y=value, group=variable, colour=variable), size=1) +
	geom_col(aes(x=datum, y=value, group=variable, fill=variable, color=abgelesen_colour), position='stack', size=0.3) +
	scale_colour_identity() +
	#geom_smooth(aes(x=datum, y=value, group=variable, colour=variable), size=1) +
	#facet_wrap(~group, ncol=1, scales='free_y') +
#	geom_smooth(aes(y=Schnitt), colour="orange", size=2) +
	#annotate("text", x=9, y=1600, colour="red", hjust=0, label="(Vollständige Erfassung ab 01/2013)") +
	annotate("text", x=min(dfplot2$datum), y=900, hjust=0, cex=5, label='(Balken ohne Umrandung = interpoliert, nicht abgelesen)') +
	scale_y_continuous(limits=c(0,1000)) +
	theme_verbrauch() +
	labs(title="Kosten Energie/Wasser OD10 im Zeitverlauf",
	     y = 'Rp. pro Tag',
			 x = 'Datum'
	)

png(filename=paste(figdirprefix, filedateprefix, "_kostenverlauf.png", sep=''),
		width=1400, height=600)
 print(kostenplot)
dev.off()




#dft <- df %>%
#	filter(as.numeric(year) > 2020)


# df2020 <- read.csv("2020.csv", sep="\t")
# dfkosten <- rbind(df2012,df2013,df2014,df2015,df2016,df2017,df2018,df2019,df2020)
# dfkosten$date <- as.Date(dfkosten$Datum, format="%d.%m.%Y")
# dfkosten$Datum <- dfkosten$date
# dfkosten$date <- NULL
# dfkosten$Kosten <- as.numeric(dfkosten$Kosten)

#windowsize <- 60
#dfkosten$Schnitt <- c(rep(NA,windowsize-1),
#					rollapply(dfkosten$Kosten, width=windowsize, mean)
#					)
# dfkosten$Monat <- as.factor(as.numeric(format(dfkosten$Datum, format = "%Y%m")))

######

# costsum <- sum(dfkosten$Kosten)
# daydiff <- as.numeric(max(dfkosten$Datum) - min(dfkosten$Datum))
# 
# 
# print(paste("Gesamtkosten:", costsum, sep=" "))
# print(paste("        Tage:", daydiff, sep=" "))
# print(paste("     pro Tag:", round(costsum/daydiff, digits=2), sep=" "))
# print(paste("   pro Monat:", round(costsum/daydiff*30, digits=2), sep=" "))

# zeitplot <- ggplot(dfkosten, aes(x=Datum,y=Kosten)) +
# 	geom_point(aes(colour=Betreff), size=3) +
# #	geom_smooth(aes(y=Schnitt), colour="orange", size=2) +
# 	scale_y_continuous(limits=c(0,300)) +
# 	theme_kosten() +
# 	labs(title="Kostenverlauf")
# 
# png(filename="kostenverlauf.png",
# 		width=1200, height=600)
#  print(zeitplot)
# dev.off()
# 
# dfks <- aggregate(Kosten ~ Monat + Betreff, data = dfkosten, sum)
# dfks$Betreff <- factor(dfks$Betreff, levels=rev(levels(dfks$Betreff)))
# 
# ########################################
# 
# monatsplot <- ggplot(dfks) +
# 	geom_bar(aes(x=Monat, y=Kosten, fill=Betreff), stat="identity", position="stack") +
# 	theme_kosten() +
# 	theme(axis.text.x=element_text(angle=90)) +
# 	geom_vline(xintercept=c(8.5, 20.5, 32.5, 44.5), colour = "dodgerblue") +
# 	#annotate("text", x=9, y=1600, colour="red", hjust=0, label="(Vollständige Erfassung ab 01/2013)") +
# 	scale_x_discrete(breaks = levels(dfks$Monat)[1:60*3]) +
# 	labs(y="Ausgaben täglicher Bedarf, Mobilität, cash (CHF)") +
# 	labs(title="Lebenshaltungskosten")
# 
# png(filename="kostenverlauf-monate.png",
# 		width=1200, height=600)
#   print(monatsplot)
# dev.off()
# 
# 
# ########################################
# # Monatsplot Detaillisten
# ########################################
# dfkscoopmigros <- subset(dfks, Betreff %in% c("coop", "migros", "denner", "lidl", "aldi"))
# monatsplotlines <- ggplot(dfkscoopmigros, aes(x=Monat, y=Kosten)) +
# 	#geom_histogram(aes(fill=Betreff), stat="identity", position="stack") +
# 	geom_point(aes(colour=Betreff, group=Betreff), size=1.5, alpha=1) +
# 	#geom_line(aes(colour=Betreff, group=Betreff), size=1.5, alpha=0.5) +
# 	geom_smooth(aes(colour=Betreff, group=Betreff), size=1.5, se=FALSE) +
# 	geom_vline(xintercept=c(8.5, 20.5, 32.5), colour = "dodgerblue") +
# 	theme_kosten() +
# 	theme(axis.text.x=element_text(angle=90)) +
# 	#geom_vline(x=c(8.5, 20.5), colour = "dodgerblue") +
# 	#annotate("text", x=9, y=1600, colour="red", hjust=0, label="(Vollständige Erfassung ab 01/2013)") +
# 	scale_x_discrete(breaks = levels(dfks$Monat)[1:60*3]) +
# 	labs(y="Ausgaben Detailhandel [CHF/Monat]") +
# 	labs(title="Ausgaben Detaillisten")
# 
# png(filename="kostenverlauf-monate-coop-migros-lineplot.png",
# 		width=1200, height=600)
#   print(monatsplotlines)
# dev.off()
# 
# ########################################
# 
# ########################################
# # Monatsplot Detaillisten
# ########################################
# dfkscoopmigros <- subset(dfks, Betreff %in% c("coop", "migros", "denner", "lidl", "aldi"))
# monatsplotlines <- ggplot(dfkscoopmigros, aes(x=Monat, y=Kosten)) +
# 	#geom_histogram(aes(fill=Betreff), stat="identity", position="stack") +
# 	geom_point(aes(colour=Betreff, group=Betreff), size=1.5, alpha=1) +
# 	#geom_line(aes(colour=Betreff, group=Betreff), size=1.5, alpha=0.5) +
# 	geom_smooth(aes(colour=Betreff, group=Betreff), size=1.5, se=FALSE) +
# 	geom_vline(xintercept=c(8.5, 20.5, 32.5), colour = "dodgerblue") +
# 	theme_kosten() +
# 	theme(axis.text.x=element_text(angle=90)) +
# 	#geom_vline(x=c(8.5, 20.5), colour = "dodgerblue") +
# 	#annotate("text", x=9, y=1600, colour="red", hjust=0, label="(Vollständige Erfassung ab 01/2013)") +
# 	scale_x_discrete(breaks = levels(dfks$Monat)[1:60*3]) +
# 	labs(y="Ausgaben Detailhandel [CHF/Monat]") +
# 	labs(title="Ausgaben Detaillisten")
# 
# png(filename="kostenverlauf-monate-coop-migros-lineplot.png",
# 		width=1200, height=600)
#   print(monatsplotlines)
# dev.off()
# 
# dfkosten_sbbvelo <- subset(dfkosten,Betreff %in% c("SBBvelo"))
# sum(dfkosten_sbbvelo$Kosten)
# dfkosten_sbb <- subset(dfkosten,Betreff %in% c("SBB"))
# sum(dfkosten_sbb$Kosten)
# 
# ## Auswertung nur für 2012 
# dfkosten_2012 <- subset(dfkosten, Datum <= "2012-12-31")
# 
# costsum <- sum(dfkosten_2012$Kosten)
# daydiff <- as.numeric(max(dfkosten_2012$Datum) - min(dfkosten_2012$Datum))
# 
# print(paste("Gesamtkosten 2012:", costsum, sep=" "))
# print(paste("        Tage 2012:", daydiff, sep=" "))
# print(paste("     pro Tag 2012:", round(costsum/daydiff, digits=2), sep=" "))
# print(paste("   pro Monat 2012:", round(costsum/daydiff*30, digits=2), sep=" "))
# 
# ## Auswertung nur für 2013 (aktueller, keine "Einstandskosten")
# dfkosten_2013 <- subset(dfkosten, Datum >= "2013-01-01" & Datum <= "2013-12-31")
# 
# costsum <- sum(dfkosten_2013$Kosten)
# daydiff <- as.numeric(max(dfkosten_2013$Datum) - min(dfkosten_2013$Datum))
# 
# print(paste("Gesamtkosten 2013:", costsum, sep=" "))
# print(paste("        Tage 2013:", daydiff, sep=" "))
# print(paste("     pro Tag 2013:", round(costsum/daydiff, digits=2), sep=" "))
# print(paste("   pro Monat 2013:", round(costsum/daydiff*30, digits=2), sep=" "))
# 
# ## Auswertung nur für 2014
# dfkosten_2014 <- subset(dfkosten, Datum >= "2014-01-01" & Datum <= "2014-12-31")
# 
# costsum <- sum(dfkosten_2014$Kosten)
# daydiff <- as.numeric(max(dfkosten_2014$Datum) - min(dfkosten_2014$Datum))
# 
# print(paste("Gesamtkosten 2014:", costsum, sep=" "))
# print(paste("        Tage 2014:", daydiff, sep=" "))
# print(paste("     pro Tag 2014:", round(costsum/daydiff,digits=2), sep=" "))
# print(paste("   pro Monat 2014:", round(costsum/daydiff*30, digits=2), sep=" "))
# 
# ## Auswertung nur für 2015
# dfkosten_2015 <- subset(dfkosten, Datum >= "2015-01-01" & Datum <= "2015-12-31")
# 
# costsum <- sum(dfkosten_2015$Kosten)
# daydiff <- as.numeric(max(dfkosten_2015$Datum) - min(dfkosten_2015$Datum))
# 
# print(paste("Gesamtkosten 2015:", costsum, sep=" "))
# print(paste("        Tage 2015:", daydiff, sep=" "))
# print(paste("     pro Tag 2015:", round(costsum/daydiff, digits=2), sep=" "))
# print(paste("   pro Monat 2015:", round(costsum/daydiff*30, digits=2), sep=" "))
# 
# ## Auswertung nur für 2016
# dfkosten_2016 <- subset(dfkosten, Datum >= "2016-01-01" & Datum <= "2016-12-31")
# 
# costsum <- sum(dfkosten_2016$Kosten)
# daydiff <- as.numeric(max(dfkosten_2016$Datum) - min(dfkosten_2016$Datum))
# 
# print(paste("Gesamtkosten 2016:", costsum, sep=" "))
# print(paste("        Tage 2016:", daydiff, sep=" "))
# print(paste("     pro Tag 2016:", round(costsum/daydiff, digits=2), sep=" "))
# print(paste("   pro Monat 2016:", round(costsum/daydiff*30, digits=2), sep=" "))
# 
# ## Auswertung nur für 2017
# dfkosten_2017 <- subset(dfkosten, Datum >= "2017-01-01" & Datum <= "2017-12-31")
# 
# costsum <- sum(dfkosten_2017$Kosten)
# daydiff <- as.numeric(max(dfkosten_2017$Datum) - min(dfkosten_2017$Datum))
# 
# print(paste("Gesamtkosten 2017:", costsum, sep=" "))
# print(paste("        Tage 2017:", daydiff, sep=" "))
# print(paste("     pro Tag 2017:", round(costsum/daydiff, digits=2), sep=" "))
# print(paste("   pro Monat 2017:", round(costsum/daydiff*30, digits=2), sep=" "))
# 
# ## Auswertung nur für 2018
# dfkosten_2018 <- subset(dfkosten, Datum >= "2018-01-01" & Datum <= "2018-12-31")
# 
# costsum <- sum(dfkosten_2018$Kosten)
# daydiff <- as.numeric(max(dfkosten_2018$Datum) - min(dfkosten_2018$Datum))
# 
# print(paste("Gesamtkosten 2018:", costsum, sep=" "))
# print(paste("        Tage 2018:", daydiff, sep=" "))
# print(paste("     pro Tag 2018:", round(costsum/daydiff, digits=2), sep=" "))
# print(paste("   pro Monat 2018:", round(costsum/daydiff*30, digits=2), sep=" "))
# 
# ## Auswertung nur für 2019
# dfkosten_2019 <- subset(dfkosten, Datum >= "2019-01-01" & Datum <= "2019-12-31")
# 
# costsum <- sum(dfkosten_2019$Kosten)
# daydiff <- as.numeric(max(dfkosten_2019$Datum) - min(dfkosten_2019$Datum))
# 
# print(paste("Gesamtkosten 2019:", costsum, sep=" "))
# print(paste("        Tage 2019:", daydiff, sep=" "))
# print(paste("     pro Tag 2019:", round(costsum/daydiff, digits=2), sep=" "))
# print(paste("   pro Monat 2019:", round(costsum/daydiff*30, digits=2), sep=" "))
# 
# ## Auswertung nur für 2020
# dfkosten_2020 <- subset(dfkosten, Datum >= "2020-01-01" & Datum <= "2020-12-31")
# 
# costsum <- sum(dfkosten_2020$Kosten)
# daydiff <- as.numeric(max(dfkosten_2020$Datum) - min(dfkosten_2020$Datum))
# 
# print(paste("Gesamtkosten 2020:", costsum, sep=" "))
# print(paste("        Tage 2020:", daydiff, sep=" "))
# print(paste("     pro Tag 2020:", round(costsum/daydiff, digits=2), sep=" "))
# print(paste("   pro Monat 2020:", round(costsum/daydiff*30, digits=2), sep=" "))
# 
# @
# 
# 
# %%%% Ausgabe in Grafiken im Report %%%%
# \begin{figure}
# <<zeitplot, echo=FALSE, results='asis', fig.width=12, fig.height=8, out.width='0.85\\linewidth'>>=
# 	print(zeitplot)
# @
# 	\label{fig:zeitplot}
# 	\caption{Kostenverlauf über die Zeit verteilt, Einzelausgaben}
# \end{figure}
# 
# %\clearpage
# 
# \begin{figure}
# <<monatsplot, include=TRUE, echo=FALSE, error=FALSE, results='asis', fig.width=11, fig.height=7, out.width='0.90\\linewidth'>>=
# 	print(monatsplot)
# @
# 	\label{fig:monatsplot}
# 	\caption{Kostenverlauf {\"u}ber die Zeit verteilt, aggregiert nach Monaten. Alle variablen Kosten; exkl: Versicherungen,
# 	Miete, Nebenkosten, Billag, Kinderfahrtkosten, grössere Anschaffungen, Abonnemente. }
# \end{figure}
# 
# \clearpage
# 
# \begin{figure}
# <<monatsplotlines, include=TRUE, echo=FALSE, error=FALSE, results='asis', fig.width=11, fig.height=7, out.width='0.90\\linewidth'>>=
# 	print(monatsplotlines)
# @
# 	\label{fig:monatsplotlines}
# 	\caption{Kostenverlauf coop/migros/Detailhandel {\"u}ber die Zeit, aggregiert nach Monaten.}
# \end{figure}
# 
# \clearpage
# 
# 
# \section{Analyse: Lebensmittelausgaben Detaillisten}
# 
# <<berechnunglebensmittel, include=TRUE, echo=FALSE, error=FALSE>>=
# 
# dfkostenlm <- droplevels(subset(dfkosten, Betreff %in% c('migros', 'coop', 'aldi', 'lidl', 'denner')))
# dfkostenlm$Einkaufsort <- dfkostenlm$Betreff
# 
# lebensmittelplot <- ggplot(dfkostenlm) +
# 	geom_bar(aes(x=Monat,y=Kosten,fill=Einkaufsort), stat="identity", position="stack") +
# 	scale_fill_manual(values=c("migros"="orange", "coop"="red", "denner" = "darkred", "aldi"="blue", "lidl"="gold")) +
# 	theme_kosten() +
# 	theme(axis.text.x=element_text(angle=90)) +
# 	scale_x_discrete(breaks = levels(dfkostenlm$Monat)[1:60*3]) +
# 	labs(y="Ausgaben (CHF)")
# 
# 	png(filename="kostenverlauf-lebensmittel.png",
# 			width=1200, height=600)
# 	  print(lebensmittelplot)
# 	dev.off()
# 
# @
# 
# Welche der vier grossen Detaillisten werden wie häufig aufgesucht? Wie gross
# ist der durchschnittliche Umsatz? Wie hoch ist der Gesamtumsatz?
# 
# \subsection{Aufbereitung Monatsumsätze}
# 
# \begin{figure}[h]
# <<lebensmittelplot, echo=FALSE, error=FALSE, results='asis', fig.width=12, fig.height=8, out.width='0.95\\linewidth'>>=
# 	print(lebensmittelplot)
# @
# 				\label{fig:lebensmittelplot}
# 				\caption{Kostenverlauf nur Lebensmittel}
# \end{figure}
# 
# %Die jeweiligen Kinderbesuche sind als Spitzen deutlich zu erkennen (2013-02, 2013-04, 2013-07, 2013-11, 2014-05, 2014-08).
# 
# \subsection{Kennzahlen für einzelne Detaillisten}
# 
# <<tablebensmittel, echo=FALSE, results='asis'>>=
# 	dfvert <- data.frame(Anzahl = summary(dfkostenlm$Einkaufsort),
# 											 Durchschnitt = aggregate(dfkostenlm$Kosten, by=list(dfkostenlm$Einkaufsort), mean)$x,
# 											 Umsatz = aggregate(dfkostenlm$Kosten, by=list(dfkostenlm$Einkaufsort), sum)$x
# 											 )
#   xtable(dfvert,
# 				 caption='Verteilung Einkäufe auf Detaillisten')
# @
# 
# \clearpage
# 
# 
# \begin{figure}
# <<lebensmittelsmooth, echo=FALSE, results='asis', fig.width=10, fig.height=8, out.width='0.88\\linewidth'>>=
# 
# vertlm <- ggplot(dfkostenlm) +
# 	geom_histogram(aes(x=Kosten, y = ..count..), 
# 								 fill='lightblue', colour='darkblue', binwidth=10) +
# 	facet_wrap(~Einkaufsort, ncol=1, scales='free_y') +
# 	scale_x_continuous(limits=c(0,150)) +
# 	labs(x='Warenkorbgrösse')
# 
# 	png(filename="warenkorbverteilung-lebensmittel.png",
# 			width=600, height=1200)
# 	  print(vertlm)
# 	dev.off()
# 
# 	print(vertlm)
# 
# @
# 				\label{fig:lebensmittelsmooth}
# 				\caption{Kostenverteilung nur Lebensmittel}
# \end{figure}
# 
# 
# \clearpage
# 
# \section{Analyse: Ausgaben 2020 täglicher Bedarf}
# 
# <<taeglicherbedarf_2020, include=FALSE, echo=FALSE, error=FALSE>>=
# 
# dfkosten2020 <- dfkosten %>%
# 	filter(Betreff %in% c('spar', 
# 												'milch',
# 												'kaffee',
# 												'hofladen',
# 												'beck',
# 												'volg',
# 												'landi',
# 												'denner',
# 												'auswaerts',
# 												'starbucks',
# 												'migros',
# 												'coop',
# 												'lidl',
# 												'kehricht',
# 												'rewe',
# 												'aldi')) %>%
# 	filter(Datum >= '2020-01-01') %>%
# 	mutate(kategorie = ifelse(Betreff %in% c('spar', 'denner', 'coop', 'migros', 'lidl', 'aldi', 'volg', 'rewe'), 'supermarkt', 'sonstige')) %>%
# 	droplevels()
# 
# monatsplot2020 <- ggplot(dfkosten2020) +
# 	geom_bar(aes(x=Monat, y=Kosten, fill=Betreff), stat="identity", position="stack") +
# 	theme_kosten() +
# 	theme(axis.text.x=element_text(angle=90)) +
# 	facet_wrap(~kategorie, ncol=1) +
# #	geom_vline(xintercept=c(8.5, 20.5, 32.5, 44.5), colour = "dodgerblue") +
# 	labs(y="2020: Ausgaben täglicher Bedarf") +
# 	labs(title="Lebenshaltungskosten ab 2020")
# 
# png(filename="kostenverlauf-monate-2020.png",
# 		width=1200, height=600)
#   print(monatsplot2020)
# dev.off()
# 
# dfkosten2020_supermarkt <- dfkosten2020 %>%
# 	filter(kategorie=='supermarkt')
# 
# monatsplot2020_supermarkt <- ggplot(dfkosten2020_supermarkt) +
# 	geom_bar(aes(x=Monat, y=Kosten, fill=Betreff), stat="identity", position="stack") +
# 	theme_kosten() +
# 	theme(axis.text.x=element_text(angle=90)) +
# 	#facet_wrap(~kategorie, ncol=1) +
# #	geom_vline(xintercept=c(8.5, 20.5, 32.5, 44.5), colour = "dodgerblue") +
# 	labs(y="2020: Ausgaben Supermarkt") +
# 	labs(title="Lebenshaltungskosten Supermarkt ab 2020")
# 
# png(filename="kostenverlauf-monate-2020-supermarkt.png",
# 		width=1200, height=600)
#   print(monatsplot2020_supermarkt)
# dev.off()
# 
# dfkosten2020_sonstige <- dfkosten2020 %>%
# 	filter(kategorie=='sonstige')
# 
# monatsplot2020_sonstige <- ggplot(dfkosten2020_sonstige) +
# 	geom_bar(aes(x=Monat, y=Kosten, fill=Betreff), stat="identity", position="stack") +
# 	theme_kosten() +
# 	theme(axis.text.x=element_text(angle=90)) +
# 	#facet_wrap(~kategorie, ncol=1) +
# #	geom_vline(xintercept=c(8.5, 20.5, 32.5, 44.5), colour = "dodgerblue") +
# 	labs(y="2020: Ausgaben sonstige Lhk.") +
# 	labs(title="Lebenshaltungskosten sonstige ab 2020")
# 
# png(filename="kostenverlauf-monate-2020-sonstige.png",
# 		width=1200, height=600)
#   print(monatsplot2020_sonstige)
# dev.off()
# 
# @
# 
# \begin{figure}
# 
# <<monatsplot2020, echo=FALSE, results='asis', fig.width=10, fig.height=8, out.width='0.88\\linewidth'>>=
# 	print(monatsplot2020)
# @
# 				\label{fig:monatsplot2020}
# 				\caption{Kostenverlauf 2020, t{\"a}glicher Bedarf}
# \end{figure}
# 
# \begin{figure}
# <<monatsplot2020_supermarkt, echo=FALSE, results='asis', fig.width=10, fig.height=8, out.width='0.88\\linewidth'>>=
# 	print(monatsplot2020_supermarkt)
# @
# 
# 				\label{fig:monatsplot2020_supermarkt}
# 				\caption{Kostenverlauf 2020, nur Supermarkt}
# \end{figure}
# 
# \begin{figure}
# <<monatsplot2020_sonstige, echo=FALSE, results='asis', fig.width=10, fig.height=8, out.width='0.88\\linewidth'>>=
# 	print(monatsplot2020_sonstige)
# @
# 
# 				\label{fig:monatsplot2020_sonstige}
# 				\caption{Kostenverlauf 2020, nur Sonstige}
# \end{figure}
# 
# %\section{Analyse: Ausgaben Mobilität}
# 
# %<<oevkosten, include=FALSE, echo=FALSE, error=FALSE>>=
# %dfkostenov <- subset(dfkosten, Betreff %in% c('SBB', 'SBBvelo','SBBhalbtax', 'SBB-GA', 'mobility'))
# %
# %sbbplot <- ggplot(dfkostenov) +
# %	geom_bar(aes(x=Monat, y=Kosten, fill=Betreff), stat="identity", position="stack") +
# %	scale_fill_manual(values=c("mobility"="red", "SBB-GA"="darkblue", "SBB"="blue", "SBBhalbtax"="lightblue", "SBBvelo"="gold")) +
# %	theme_kosten() +
# %	theme(axis.text.x=element_text(angle=90)) +
# %	labs(y='Mobilitätsausgaben')
# %
# %	png(filename="kostenverlauf-sbb.png",
# %			width=1200, height=600)
# %	  print(sbbplot)
# %	dev.off()
# %@
# %
# %\begin{figure}
# %
# %<<sbbplot, echo=FALSE, results='asis', fig.width=10, fig.height=8, out.width='0.88\\linewidth'>>=
# %	print(sbbplot)
# %@
# %				\label{fig:sbbplot}
# %				\caption{Kostenverlauf Mobilität (SBB/ÖV/mobility), ohne Kosten GA}
# %\end{figure}
# %
# %Summe Mobilität seit Zuwanderung: \Sexpr{sum(dfkostenov$Kosten)} CHF
# %
# %Durchschnitt Mobilität pro Jahr: \Sexpr{sum(dfkostenov$Kosten)/as.numeric(diff(range(dfkostenov$Datum)))*360} CHF
# 
# \end{document}
# 

