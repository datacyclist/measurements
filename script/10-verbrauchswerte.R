########################################
# Skript zum Generieren von Verbrauchs-/Kostengrafiken
# 
# 2023-04-30
#
# - Zählerstände aus CSV
# - Berechnen von Zeitdifferenzen und Zählerdifferenzen für diese Zeiträume
# - Aggregation auf Tagesbasis, Monatsbasis
# - Kosten müssen pro Jahr separat angepasst werden (siehe 08-grundpreise.R)
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
source("08-grundpreise.R")

# wird nicht mehr gebraucht, da ich nicht mehr in den Keller muss
# source("05-read-googlesheet.R") 

options("lubridate.week.start"=1)

filedateprefix <- format(Sys.time(), "%Y%m%d")
figdirprefix <- '../figs/'
cachedirprefix <- '../cache/'
# Ablesewerte werden hier manuell abgelegt
csvdirprefix <- '../csv/'


# archivierte Ablesewerte aus dem Google-Sheet...
# dat1 <- read_csv(file=paste(csvdirprefix, "20210410-ablesewerte.csv", sep=""))
# ...und die aktuellen Ablesewerte
dat <- read_tsv(file=paste(csvdirprefix, "ablesewerte-zum-eintragen.csv", sep=""))

#dat <- dat2 
#%>%
#	select(timestamp,strom_tag, strom_nacht, gas, wasser, kommentar) %>%
#	rbind(dat2) %>%
#	arrange(timestamp)
	

##############################
# Ablesetage bestimmen
##############################

df_abgelesen_logical <- dat %>%
	mutate(
				 timestamp_day = format(timestamp, format = "%Y-%m-%d")
				 ) %>%
	select(timestamp_day) %>%
	unique() %>% # bei mehrfachen Tagesablesungen
	mutate(abgelesen_flag = TRUE)

#########################################
#cat(" Daten vorbearbeiten und bereinigen -- auf Stundenbasis runterbrechen \n")
#########################################
#
#df_hours <- dat %>%
#	mutate(
#				 diff_h = interval(lag(timestamp),timestamp)/hours(1),
#				 diff_gas = gas - lag(gas),
#				 diff_wasser = wasser - lag(wasser),
#				 diff_strom_ht = strom_tag-lag(strom_tag),
#				 diff_strom_nt = strom_nacht-lag(strom_nacht),
#				 verbrauch_gas_pro_stunde_kWh = diff_gas/diff_h*10.17,
#				 verbrauch_wasser_pro_stunde_l = diff_wasser/diff_h*1000,
#				 verbrauch_strom_ht_pro_stunde_kWh = diff_strom_ht/diff_h,
#				 verbrauch_strom_nt_pro_stunde_kWh = diff_strom_nt/diff_h,
#				 verbrauch_strom_gesamt_pro_stunde = verbrauch_strom_ht_pro_stunde_kWh + verbrauch_strom_nt_pro_stunde_kWh,
#				 timestamp_hours= format(timestamp, format = "%Y-%m-%d %H:00:00")
#				 )
#
## join with this datedf in hours to fill missing values
#df_hours_for_join <- data.frame(
#															 timestamp_hours = seq.POSIXt(as.POSIXct(min(df_hours$timestamp,na.rm=TRUE)), 
#																														as.POSIXct(max(df_hours$timestamp, na.rm=TRUE)), 
#																														by="hour")
#															 ) %>%
#	mutate(timestamp_hours = format(timestamp_hours, format="%Y-%m-%d %H:00:00"))
#
## Alles auf Stundenbasis berechnen...
#df_hours_join <- df_hours_for_join %>%
#				left_join(df_hours, by='timestamp_hours') %>%
#	fill(verbrauch_gas_pro_stunde_kWh, .direction='up') %>%
#	fill(verbrauch_wasser_pro_stunde_l, .direction='up') %>%
#	fill(verbrauch_strom_nt_pro_stunde_kWh, .direction='up') %>%
#	fill(verbrauch_strom_ht_pro_stunde_kWh, .direction='up') %>%
#	fill(verbrauch_strom_gesamt_pro_stunde, .direction='up')

# ...und wieder auf Tagesbasis aggregieren

df_days <- dat %>%
		arrange(timestamp) %>%
		mutate(
						verbrauch_strom_ht_pro_tag_kWh = round(strom_tag-lag(strom_tag),digits=3),
						verbrauch_strom_nt_pro_tag_kWh = round(strom_nacht-lag(strom_nacht),digits=3),
						verbrauch_gas_pro_tag_kWh = round((gas-lag(gas))*10.17,digits=3),
						verbrauch_wasser_pro_tag_l = round((wasser-lag(wasser))*1000,digits=3),
						verbrauch_strom_gesamt_pro_tag = verbrauch_strom_ht_pro_tag_kWh + verbrauch_strom_nt_pro_tag_kWh
		) %>%
	mutate(
				 timestamp_day = as.character(as.Date(timestamp)),
				 datum = as.Date(timestamp)
				 ) %>%
	left_join(df_abgelesen_logical, by='timestamp_day') %>%
	mutate(abgelesen_flag = replace_na(abgelesen_flag, FALSE))
	
#	#mutate(datum = as.Date(format(timestamp_day, format="%Y-%m-%d", tz='Europe/Zurich'))) %>%
#				 #, format="%Y-%m-%d")) %>%
#
#w1 <- write_csv2(x=df_days, file=paste(cachedirprefix, "dfdays.csv" , sep =""))
	
########################################
# Tage pro Monat -- nicht immer 30...
# join with this datedf to fill missing values
########################################

df_datum_tage_pro_monat_join <- data.frame(datum=seq.Date(as.Date(min(df_days$datum)),as.Date(max(df_days$datum)),by="day")) %>%
					mutate(
								 JahrMonat = as.factor(format(datum, format = "%Y-%m")),
								 tage_pro_monat = days_in_month(datum)
	               #datum = format(datum, format="%Y-%m-%d", tz='Europe/Zurich')
								 )

# Tage pro Monat und Jahr-Monat dranhaengen
df1 <- df_datum_tage_pro_monat_join %>%
				left_join(df_days, by='datum')
	
###############################
cat("Verbrauchsmengen und Plot dazu \n")
###############################

#df1 <- datedf %>%
#	left_join(df, by='datum') %>%
#	fill(verbrauch_gas_pro_tag_kWh, .direction='up') %>%
#	fill(verbrauch_wasser_pro_tag_l, .direction='up') %>%
#	fill(verbrauch_strom_nt_pro_tag_kWh, .direction='up') %>%
#	fill(verbrauch_strom_ht_pro_tag_kWh, .direction='up') %>%
#	fill(verbrauch_strom_gesamt_pro_tag, .direction='up') %>%
#	mutate(abgelesen_flag = ifelse(is.na(timestamp_orig), FALSE, TRUE))

##############################
# Abnahmemengen pro Tag, gesamter Zeitraum
##############################

dfplot <- df1 %>%
		select(datum, abgelesen_flag, starts_with('verbrauch')) %>%
		melt(id.vars=c('datum', 'abgelesen_flag')) %>%
		filter(variable != 'verbrauch_strom_gesamt_pro_tag') %>%	
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
	geom_col(aes(x=datum, y=value, group=variable, fill=variable), position='stack', size=1) +
	scale_colour_identity() +
	scale_fill_brewer(type='qual', palette='Set2', direction=1) +
	facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	labs(title=paste("Abnahmemengen OD10 im Zeitverlauf, generiert ", filedateprefix, sep=""),
	     y = 'Wert in jew. Einheit [l bzw. kWh]',
			 x = 'Datum'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_verbrauchsverlauf.png", sep=''),
		width=1400, height=600)
 print(verbrauchsplot)
dev.off()

##############################
cat("Abnahmemengen pro Tag, nur letzte 365 Tage\n")
##############################

filterdate <- format(Sys.time()-days(365), "%Y-%m-%d")

dfplotverbrauch_365days <- df1 %>%
		filter(datum >= filterdate) %>%
		select(datum, abgelesen_flag, starts_with('verbrauch')) %>%
		melt(id.vars=c('datum', 'abgelesen_flag')) %>%
		filter(variable != 'verbrauch_strom_gesamt_pro_tag') %>%	
		#filter(!(is.na(value))) %>%
		mutate(group = case_when(
														 grepl('strom',variable) ~ 'Strom [kWh]',
														 grepl('wasser', variable) ~ 'Wasser [Liter]',
														 #grepl('gas', variable) ~ 'Gas [m3 und kWh]'
														 grepl('gas', variable) ~ 'Gas [kWh]'
														 ) ,
					abgelesen_colour = as.factor(ifelse(abgelesen_flag, 'black', 'gray'))
		)

verbrauchsplot <- ggplot(dfplotverbrauch_365days) +
	geom_col(aes(x=datum, y=value, group=variable, fill=variable, color=abgelesen_colour), position='stack', size=0.3) +
	scale_colour_identity() +
	scale_fill_brewer(type='qual', palette='Set2', direction=1) +
	facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	labs(title=paste("Abnahmemengen OD10 im Zeitverlauf letzte 365 Tage, generiert ", filedateprefix, sep=""),
	     y = 'Wert in jew. Einheit [l bzw. kWh]',
			 x = 'Datum'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_verbrauchsverlauf_365days.png", sep=''),
		width=1400, height=600)
 print(verbrauchsplot)
dev.off()

##############################
cat("Abnahmemengen pro Tag, nur letzte 30 Tage\n")
##############################
filterdate <- format(Sys.time()-days(30), "%Y-%m-%d")

dfplotverbrauch_30days <- df1 %>%
		filter(datum >= filterdate) %>%
		select(datum, abgelesen_flag, starts_with('verbrauch')) %>%
		melt(id.vars=c('datum', 'abgelesen_flag')) %>%
		filter(variable != 'verbrauch_strom_gesamt_pro_tag') %>%	
		#filter(!(is.na(value))) %>%
		mutate(group = case_when(
														 grepl('strom',variable) ~ 'Strom [kWh]',
														 grepl('wasser', variable) ~ 'Wasser [Liter]',
														 #grepl('gas', variable) ~ 'Gas [m3 und kWh]'
														 grepl('gas', variable) ~ 'Gas [kWh]'
														 ) ,
					abgelesen_colour = as.factor(ifelse(abgelesen_flag, 'black', 'gray'))
		)

verbrauchsplot <- ggplot(dfplotverbrauch_30days) +
	geom_col(aes(x=datum, y=value, group=variable, fill=variable, color=abgelesen_colour), position='stack', size=0.3) +
	scale_colour_identity() +
	scale_fill_brewer(type='qual', palette='Set2', direction=1) +
	facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	labs(title=paste("Abnahmemengen OD10 im Zeitverlauf letzte 30 Tage, generiert ", filedateprefix, sep=""),
	     y = 'Wert in jew. Einheit [l bzw. kWh]',
			 x = 'Datum'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_verbrauchsverlauf_30days.png", sep=''),
		width=1400, height=600)
 print(verbrauchsplot)
dev.off()


##############################
cat("Abnahmemengen auf Monate aggregiert\n")
##############################

df1_monate <- df1 %>%
	mutate(JahrMonat = as.factor(format(datum, format = "%Y-%m"))) %>%
	group_by(JahrMonat) %>%
	summarise(
						strom_ht_kWh = sum(verbrauch_strom_ht_pro_tag_kWh),
						strom_nt_kWh = sum(verbrauch_strom_nt_pro_tag_kWh),
						strom_ges_kWh = strom_ht_kWh+strom_nt_kWh,
						wasser_l = sum(verbrauch_wasser_pro_tag_l),
						gas_kWh = sum(verbrauch_gas_pro_tag_kWh)
						)

dfplot1 <- df1_monate %>%
		#select(JahrMonat, starts_with('verbrauch')) %>%
		melt(id.vars=c('JahrMonat')) %>%
		filter(variable != 'strom_ges_kWh') %>%
		mutate(group = case_when(
														 grepl('strom',variable) ~ 'Strom [kWh]',
														 grepl('wasser', variable) ~ 'Wasser [Liter]',
														 #grepl('gas', variable) ~ 'Gas [m3 und kWh]'
														 grepl('gas', variable) ~ 'Gas [kWh]'
														 )
		)

dfplot1_ann_pos <- df1_monate %>%
	mutate(pos_strom = round(strom_ges_kWh),
				 pos_wasser = round(wasser_l, digits=0),
				 pos_gas = round(gas_kWh, digits=0)
				 ) %>%
	select(JahrMonat, starts_with("pos")) %>%
	melt(id.vars="JahrMonat") %>%
	mutate(
				 ypos = value,
				 group = case_when(
														 grepl('strom',variable) ~ 'Strom [kWh]',
														 grepl('wasser', variable) ~ 'Wasser [Liter]',
														 #grepl('gas', variable) ~ 'Gas [m3 und kWh]'
														 grepl('gas', variable) ~ 'Gas [kWh]'
														 ),
				 variable = NULL,
				 value = NULL
	)

dfplot1_ann_labels <- df1_monate %>%
	mutate(label_strom = paste(round(strom_ht_kWh, digits=0), 
														 round(strom_nt_kWh, digits=0), sep = " | "),
				 label_wasser = round(wasser_l, digits=0),
				 label_gas = round(gas_kWh, digits=0)
				 ) %>%
	select(JahrMonat, starts_with("label")) %>%
	melt(id.vars="JahrMonat") %>%
	mutate(
				 label = value,
				 group = case_when(
														 grepl('strom',variable) ~ 'Strom [kWh]',
														 grepl('wasser', variable) ~ 'Wasser [Liter]',
														 #grepl('gas', variable) ~ 'Gas [m3 und kWh]'
														 grepl('gas', variable) ~ 'Gas [kWh]'
														 ),
				 variable = NULL,
				 value = NULL
				 )

dfplot1_ann <- dfplot1_ann_pos %>%
	inner_join(dfplot1_ann_labels, by=c("JahrMonat", "group"))

  
verbrauchsplot1 <- ggplot(dfplot1) +
	geom_col(aes(x=JahrMonat, y=value, group=variable, fill=variable), colour='black', position='stack', size=0.3) +
	#scale_colour_identity() +
	geom_text(data=dfplot1_ann, aes(x=JahrMonat, y=0, vjust=-0.5,
																	label=label)) +
	facet_wrap(~group, ncol=1, scales='free_y') +
	scale_fill_brewer(type='qual', palette='Set2', direction=-1) +
	theme_verbrauch() +
	theme(axis.text.x=element_text(angle=90)) +
	labs(title=paste("Abnahmemengen OD10, Monate, generiert ", filedateprefix, sep=""),
	     y = 'Wert in jew. Einheit [l bzw. kWh]',
			 x = 'Jahr-Monat'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_verbrauchsverlauf_jahrmonat.png", sep=''),
		width=1200, height=700)
 print(verbrauchsplot1)
dev.off()


###############################
cat("Verbrauchs*kosten* und Plot dazu \n")
###############################

# alles Bruttokosten, d.h. inkl. MWSt. (7.7% Gas/Strom, 2.5% Wasser)

df2 <- df_days %>%
	#left_join(df, by='datum') %>%
	#fill(verbrauch_gas_pro_tag_kWh, .direction='up') %>%
	#fill(verbrauch_wasser_pro_tag_l, .direction='up') %>%
	#fill(verbrauch_strom_nt_pro_tag_kWh, .direction='up') %>%
	#fill(verbrauch_strom_ht_pro_tag_kWh, .direction='up') %>%
	#fill(verbrauch_strom_gesamt_pro_tag, .direction='up') %>%
	mutate(
				 jahr = as.numeric(format(datum, format = "%Y")),
				 monat = as.numeric(format(datum, format = "%m"))) %>%
	left_join(dfpreise, by=c("jahr", "monat")) %>%
	left_join(df_datum_tage_pro_monat_join, by='datum') %>% 
	#mutate(abgelesen_flag = ifelse(is.na(timestamp_orig), FALSE, TRUE)) %>%
	mutate(
				 bezug_wasser = verbrauch_wasser_pro_tag_l/1000*preis_menge_wasser*(1+mwst1)*100, # bei 100l etwa 13 Rp. pro Tag
				 bezug_abwasser = verbrauch_wasser_pro_tag_l/1000*preis_menge_abwasser*(1+mwst2)*100, # Abwasser teurer als Frischwasser
				 bezug_gas = verbrauch_gas_pro_tag_kWh *preis_menge_gas*(1+mwst2), # etwa 7.6 Rp. pro kWh
				 bezug_strom_ht = verbrauch_strom_ht_pro_tag_kWh*preis_menge_strom_ht*(1+mwst2), # etwa 20 Rp. pro kWh Normallast
				 bezug_strom_nt = verbrauch_strom_nt_pro_tag_kWh*preis_menge_strom_nt*(1+mwst2), # etwa 14 Rp. pro kWh Schwachlast
				 bezug_strom_sdl_kev_abgaben = (verbrauch_strom_ht_pro_tag_kWh+verbrauch_strom_nt_pro_tag_kWh)*
								 preis_menge_strom_sdl_kev_abgaben*(1+mwst2), # 4 Rp. pro kWh
				 grundpreis_wasser = preis_grund_wasser*(1+mwst1)/tage_pro_monat*100, # etwa 35 Rp. pro Tag
				 grundpreis_abwasser = preis_grund_abwasser*(1+mwst2)/tage_pro_monat*100, # etwa 15 Rp. pro Tag Abwassergrundpreis
				 grundpreis_gas = preis_grund_gas*(1+mwst2)/tage_pro_monat*100, # etwa 23 Rp. pro Tag
				 grundpreis_strom = preis_grund_strom*(1+mwst2)/tage_pro_monat*100 # etwa 25 Rp. pro Tag
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
	#geom_col(aes(x=datum, y=value, group=variable, fill=variable, color=abgelesen_colour), position='stack', size=0.3) +
	geom_col(aes(x=datum, y=value, group=variable, fill=variable), position='stack', size=0.3) +
	scale_colour_identity() +
	#annotate("text", x=min(dfplot2$datum), y=1000, hjust=0, cex=5, label='- Balken ohne Umrandung = interpoliert, nicht abgelesen') +
	#annotate("text", x=min(dfplot2$datum), y=950, hjust=0, cex=5, label='- Balken = Werte von vorheriger Ablesung bis "Balkendatum"') +
	#scale_y_continuous(limits=c(0,1000)) +
	scale_fill_brewer(type='div') +
	#scale_fill_brewer(type='div', palette='Set2') +
	theme_verbrauch() +
	labs(title=paste("Kosten Energie/Wasser OD10 im Zeitverlauf, generiert ", filedateprefix, sep=""),
	     y = 'Rp. pro Tag',
			 x = 'Datum'
	)

png(filename=paste(figdirprefix, filedateprefix, "_kostenverlauf.png", sep=''),
		width=1400, height=600)
 print(kostenplot)
dev.off()

#####################################
cat("Nur letzte 30 Tage anschauen\n")
#####################################

filterdate <- format(Sys.time()-days(30), "%Y-%m-%d")

dfplot2_30days <- df2 %>%
		filter(datum >= filterdate) %>%
		select(datum, abgelesen_flag, starts_with(c('grundpreis', 'bezug'))) %>%
		melt(id.vars=c('datum', 'abgelesen_flag')) %>%
		mutate(group = case_when(
														 grepl('bezug',variable) ~ 'Verbrauch',
														 grepl('grundpreis', variable) ~ 'Fixkosten'
														 ),
					abgelesen_colour = as.factor(ifelse(abgelesen_flag, 'black', 'gray')),
					variable = fct_reorder(variable, desc(variable))
					)

kostenplot_30days <- ggplot(dfplot2_30days) +
	geom_col(aes(x=datum, y=value, group=variable, fill=variable, color=abgelesen_colour), position='stack', size=0.3) +
	scale_colour_identity() +
	#annotate("text", x=min(dfplot2$datum), y=1000, hjust=0, cex=5, label='- Balken ohne Umrandung = interpoliert, nicht abgelesen') +
	#annotate("text", x=min(dfplot2$datum), y=950, hjust=0, cex=5, label='- Balken = Werte von vorheriger Ablesung bis "Balkendatum"') +
	#scale_y_continuous(limits=c(0,1000)) +
	scale_fill_brewer(type='div') +
	#scale_fill_brewer(type='div', palette='Set2') +
	theme_verbrauch() +
	labs(title=paste("Kosten Energie/Wasser OD10 letzte 30 Tage, generiert ", filedateprefix, sep=""),
	     y = 'Rp. pro Tag',
			 x = 'Datum'
	)

png(filename=paste(figdirprefix, filedateprefix, "_kostenverlauf-30tage.png", sep=''),
		width=1400, height=600)
 print(kostenplot_30days)
dev.off()

##############################
cat("Kosten auf Monate aggregieren \n")
##############################

df2_monate <- df2 %>%
	mutate(JahrMonat = as.factor(format(datum, format = "%Y-%m"))) %>%
	#mutate(jahr = as.numeric(format(datum, format = "%Y"))) %>%
	#left_join(dfpreise, by="jahr") 
	group_by(JahrMonat) %>%
	summarise(
						bezug_strom_ht = sum(bezug_strom_ht),
						bezug_strom_nt = sum(bezug_strom_nt),
						bezug_strom_sdl_kev_abgaben = sum(bezug_strom_sdl_kev_abgaben),
						bezug_gas = sum(bezug_gas),
						bezug_wasser = sum(bezug_wasser),
						bezug_abwasser = sum(bezug_abwasser),
						#tage = n(),
						grund_wasser = sum(grundpreis_wasser),
						grund_abwasser = sum(grundpreis_abwasser),
						grund_strom = sum(grundpreis_strom),
						grund_gas = sum(grundpreis_gas),
						#grund_wasser = unique(preis_grund_wasser)*100,
						#grund_strom = unique(preis_grund_strom)*100,
						#grund_gas = unique(preis_grund_gas)*100,
						summe_kosten = bezug_strom_ht +
										bezug_strom_nt + 
										bezug_strom_sdl_kev_abgaben +
										bezug_gas +
										bezug_wasser +
										bezug_abwasser +
										grund_wasser +
										grund_abwasser +
										grund_strom +
										grund_gas
						)

dfplot3 <- df2_monate %>%
		#select(JahrMonat, starts_with('verbrauch')) %>%
		melt(id.vars=c('JahrMonat')) %>%
		mutate(group = case_when(
														 grepl('strom',variable) ~ 'Strom',
														 grepl('wasser', variable) ~ 'Wasser',
														 #grepl('gas', variable) ~ 'Gas [m3 und kWh]'
														 grepl('gas', variable) ~ 'Gas'
														 ),
		       value_Fr = value/100
		) %>%
		filter(!(is.na(group)))

dfplot3_ann <- df2_monate %>%
		select(JahrMonat, summe_kosten)


kostenplot2 <- ggplot(dfplot3) +
	geom_col(aes(x=JahrMonat, y=value_Fr, group=variable, fill=variable), colour='black', position='stack', size=0.3) +
	#scale_colour_identity() +
	facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	theme(axis.text.x=element_text(angle=90)) +
	labs(title="Verbrauchskosten OD10, Monate",
	     y = 'Wert in Fr.',
			 x = 'Jahr-Monat'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_kostenverlauf_jahrmonat.png", sep=''),
		width=1250, height=700)
 print(kostenplot2)
dev.off()

kostenplot3 <- ggplot(dfplot3) +
	geom_col(aes(x=JahrMonat, y=value_Fr, group=variable, fill=variable), colour='black', position='stack', size=0.3) +
	#scale_colour_identity() +
	#facet_wrap(~group, ncol=1, scales='free_y') +
	geom_text(data=dfplot3_ann, aes(x=JahrMonat, y=(summe_kosten/100)+5,label=round(summe_kosten/100, digits=2)), cex=5) +
	theme_verbrauch() +
	theme(axis.text.x=element_text(angle=90)) +
	labs(title="Verbrauchskosten OD10 gesamt, Monate",
	     y = 'Wert in Fr.',
			 x = 'Jahr-Monat'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_kostenverlauf_jahrmonat_stack.png", sep=''),
		width=1250, height=700)
 print(kostenplot3)
dev.off()


##############################
cat("Kosten auf Quartale aggregieren \n")
##############################

df2_quartal <- df2 %>%
	mutate(quartal = as.factor(paste(format(datum, format="%Y"),quarter(datum), sep="_Q"))
				 ) %>%
	group_by(quartal) %>%
	summarise(
						bezug_strom_ht = sum(bezug_strom_ht),
						bezug_strom_nt = sum(bezug_strom_nt),
						bezug_strom_sdl_kev_abgaben = sum(bezug_strom_sdl_kev_abgaben),
						bezug_gas = sum(bezug_gas),
						bezug_wasser = sum(bezug_wasser),
						bezug_abwasser = sum(bezug_abwasser),
						#tage = n(),
						grund_wasser = sum(grundpreis_wasser),
						grund_abwasser = sum(grundpreis_abwasser),
						grund_strom = sum(grundpreis_strom),
						grund_gas = sum(grundpreis_gas),
						#grund_wasser = unique(preis_grund_wasser)*100,
						#grund_strom = unique(preis_grund_strom)*100,
						#grund_gas = unique(preis_grund_gas)*100,
						summe_kosten = bezug_strom_ht +
										bezug_strom_nt + 
										bezug_strom_sdl_kev_abgaben +
										bezug_gas +
										bezug_wasser +
										bezug_abwasser +
										grund_wasser +
										grund_abwasser +
										grund_strom +
										grund_gas
						)

dfplot4 <- df2_quartal %>%
		melt(id.vars=c('quartal')) %>%
		mutate(group = case_when(
														 grepl('strom',variable) ~ 'Strom',
														 grepl('wasser', variable) ~ 'Wasser',
														 #grepl('gas', variable) ~ 'Gas [m3 und kWh]'
														 grepl('gas', variable) ~ 'Gas'
														 ),
		       value_Fr = value/100
		) %>%
		filter(!(is.na(group)))

dfplot4_ann <- df2_quartal %>%
		select(quartal, summe_kosten)


kostenplot2 <- ggplot(dfplot4) +
	geom_col(aes(x=quartal, y=value_Fr, group=variable, fill=variable), colour='black', position='stack', size=0.3) +
	#scale_colour_identity() +
	facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	theme(axis.text.x=element_text(angle=90)) +
	labs(title="Verbrauchskosten OD10, Quartale",
	     y = 'Wert in Fr.',
			 x = 'Jahr-Quartal'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_kostenverlauf_quartal.png", sep=''),
		width=750, height=700)
 print(kostenplot2)
dev.off()

kostenplot3 <- ggplot(dfplot4) +
	geom_col(aes(x=quartal, y=value_Fr, group=variable, fill=variable), colour='black', position='stack', size=0.3) +
	#scale_colour_identity() +
	#facet_wrap(~group, ncol=1, scales='free_y') +
	geom_text(data=dfplot4_ann, aes(x=quartal, y=(summe_kosten/100)+10,label=round(summe_kosten/100, digits=2)), cex=5) +
	theme_verbrauch() +
	theme(axis.text.x=element_text(angle=90)) +
	labs(title="Verbrauchskosten OD10 gesamt, Quartale (inkl. Abwasser)",
	     y = 'Wert in Fr.',
			 x = 'Jahr-Quartal'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_kostenverlauf_quartal_stack.png", sep=''),
		width=1050, height=700)
 print(kostenplot3)
dev.off()

