
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
source("05-read-googlesheet.R")
source("08-grundpreise.R")

filedateprefix <- format(Sys.time(), "%Y%m%d")
figdirprefix <- '../figs/'
cachedirprefix <- '../cache/'


dat <- read_csv(file=paste(cachedirprefix, filedateprefix, "-ablesewerte.csv", sep=""))

df <- dat %>%
	mutate(
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
	
	datedf <- data.frame(datum=seq.Date(min(df$datum),max(df$datum),by="day")) %>%
					mutate(JahrMonat = as.factor(format(datum, format = "%Y-%m"))) %>%
					group_by(JahrMonat) %>%
					mutate(tage_pro_monat = n()) %>%
					ungroup()
				

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
	geom_col(aes(x=datum, y=value, group=variable, fill=variable, color=abgelesen_colour), position='dodge', size=0.3) +
	scale_colour_identity() +
	facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	labs(title="Verbrauchswerte OD10 im Zeitverlauf",
	     y = 'Wert in jew. Einheit [l bzw. kWh]',
			 x = 'Datum'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_verbrauchsverlauf.png", sep=''),
		width=1400, height=600)
 print(verbrauchsplot)
dev.off()

# alles auf Monate aggregieren
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
		mutate(group = case_when(
														 grepl('strom',variable) ~ 'Strom [kWh]',
														 grepl('wasser', variable) ~ 'Wasser [Liter]',
														 #grepl('gas', variable) ~ 'Gas [m3 und kWh]'
														 grepl('gas', variable) ~ 'Gas [kWh]'
														 )
		)

verbrauchsplot1 <- ggplot(dfplot1) +
	geom_col(aes(x=JahrMonat, y=value, group=variable, fill=variable), colour='black', position='dodge', size=0.3) +
	#scale_colour_identity() +
	facet_wrap(~group, ncol=1, scales='free_y') +
	theme_verbrauch() +
	theme(axis.text.x=element_text(angle=90)) +
	labs(title="Verbrauchswerte OD10, Monate",
	     y = 'Wert in jew. Einheit [l bzw. kWh]',
			 x = 'Jahr-Monat'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_verbrauchsverlauf_jahrmonat.png", sep=''),
		width=600, height=700)
 print(verbrauchsplot1)
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
	mutate(jahr = as.numeric(format(datum, format = "%Y"))) %>%
	left_join(dfpreise, by="jahr") %>%
	mutate(abgelesen_flag = ifelse(is.na(timestamp_orig), FALSE, TRUE)) %>%
	mutate(
				 bezug_wasser = verbrauch_wasser_pro_tag_l/1000*preis_menge_wasser*(1+mwst1)*100, # bei 100l etwa 13 Rp. pro Tag
				 bezug_gas = verbrauch_gas_pro_tag_kWh *preis_menge_gas*(1+mwst2), # etwa 7.6 Rp. pro kWh
				 bezug_strom_ht = verbrauch_strom_ht_pro_tag_kWh*preis_menge_strom_ht*(1+mwst2), # etwa 20 Rp. pro kWh Normallast
				 bezug_strom_nt = verbrauch_strom_nt_pro_tag_kWh*preis_menge_strom_nt*(1+mwst2), # etwa 14 Rp. pro kWh Schwachlast
				 bezug_strom_sdl_kev_abgaben = (verbrauch_strom_ht_pro_tag_kWh+verbrauch_strom_nt_pro_tag_kWh)*
								 preis_menge_strom_sdl_kev_abgaben*(1+mwst2), # 4 Rp. pro kWh
				 grundpreis_wasser = preis_grund_wasser*(1+mwst1)/tage_pro_monat*100, # etwa 35 Rp. pro Tag
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
	geom_col(aes(x=datum, y=value, group=variable, fill=variable, color=abgelesen_colour), position='stack', size=0.3) +
	scale_colour_identity() +
	annotate("text", x=min(dfplot2$datum), y=900, hjust=0, cex=5, label='- Balken ohne Umrandung = interpoliert, nicht abgelesen') +
	annotate("text", x=min(dfplot2$datum), y=850, hjust=0, cex=5, label='- Grundpreise nur bei vollständigen Monaten korrekt') +
	scale_y_continuous(limits=c(0,1000)) +
	#scale_fill_brewer(type='qual') +
	scale_fill_brewer(type='div') +
	theme_verbrauch() +
	labs(title="Kosten Energie/Wasser OD10 im Zeitverlauf",
	     y = 'Rp. pro Tag',
			 x = 'Datum'
	)

png(filename=paste(figdirprefix, filedateprefix, "_kostenverlauf.png", sep=''),
		width=1400, height=600)
 print(kostenplot)
dev.off()

##############################
# Kosten auf Monate aggregieren
##############################

df2_monate <- df2 %>%
	mutate(JahrMonat = as.factor(format(datum, format = "%Y-%m"))) %>%
	group_by(JahrMonat) %>%
	summarise(
						bezug_strom_ht = sum(bezug_strom_ht),
						bezug_strom_nt = sum(bezug_strom_nt),
						bezug_strom_sdl_kev_abgaben = sum(bezug_strom_sdl_kev_abgaben),
						bezug_gas = sum(bezug_gas),
						bezug_wasser = sum(bezug_wasser),
						#tage = n(),
						grund_wasser = sum(grundpreis_wasser),
						grund_strom = sum(grundpreis_strom),
						grund_gas = sum(grundpreis_gas),
						summe_kosten = bezug_strom_ht +
										bezug_strom_nt + 
										bezug_strom_sdl_kev_abgaben +
										bezug_gas +
										bezug_wasser +
										grund_wasser +
										grund_strom +
										grund_gas
						)

dfplot2 <- df2_monate %>%
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

dfplot2_ann <- df2_monate %>%
		select(JahrMonat, summe_kosten)


kostenplot2 <- ggplot(dfplot2) +
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
		width=750, height=700)
 print(kostenplot2)
dev.off()

kostenplot3 <- ggplot(dfplot2) +
	geom_col(aes(x=JahrMonat, y=value_Fr, group=variable, fill=variable), colour='black', position='stack', size=0.3) +
	#scale_colour_identity() +
	#facet_wrap(~group, ncol=1, scales='free_y') +
	geom_text(data=dfplot2_ann, aes(x=JahrMonat, y=(summe_kosten/100)+5,label=round(summe_kosten/100, digits=2)), cex=5) +
	theme_verbrauch() +
	theme(axis.text.x=element_text(angle=90)) +
	labs(title="Verbrauchskosten OD10 gesamt, Monate",
	     y = 'Wert in Fr.',
			 x = 'Jahr-Monat'
			 )

png(filename=paste(figdirprefix, filedateprefix, "_kostenverlauf_jahrmonat_stack.png", sep=''),
		width=850, height=700)
 print(kostenplot3)
dev.off()


