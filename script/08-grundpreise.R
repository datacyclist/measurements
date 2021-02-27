##############################
# Grundpreise und Bezugspreise festlegen
##############################

# Eine "Preiszeile" pro Jahr, wird dann später drangejoint an Verbrauchswerte
# fuer die Kostenberechnung

preise2021 <- data.frame(jahr=2021) %>%
	mutate(
												 mwst1 = 0.025, #2.5% Wasser
												 mwst2 = 0.077, #7.7% Gas/Strom
												 preis_menge_strom_ht = (8.19+9.91)/(1+mwst2), #Rp.
												 preis_menge_strom_nt = (7.11+6.14)/(1+mwst2), #Rp.
												 preis_menge_strom_sdl_kev_abgaben = (0.17+3.73)/(1+mwst2), #Rp.
												 preis_menge_gas = (5.17+1.88)/(1+mwst2), #Rp.
												 preis_menge_wasser = 1.28/(1+mwst1), #Fr. pro Kubikmeter,
												 preis_grund_wasser = 10.25/(1+mwst1), #Fr. pro Monat
												 preis_grund_gas = 6.46/(1+mwst2), #Fr. pro Monat
												 preis_grund_strom = 7.00/(1+mwst2), #Fr. pro Monat
												 )

preise2020 <- data.frame(jahr=2020) %>%
              mutate(
												 mwst1 = 0.025, #2.5% Wasser
												 mwst2 = 0.077, #7.7% Gas/Strom
												 preis_menge_strom_ht = (8.19+9.91)/(1+mwst2), #Rp.
												 preis_menge_strom_nt = (7.11+6.14)/(1+mwst2), #Rp.
												 preis_menge_strom_sdl_kev_abgaben = (0.17+3.73)/(1+mwst2), #Rp.
												 preis_menge_gas = (5.17+1.88)/(1+mwst2), #Rp.
												 preis_menge_wasser = 1.28/(1+mwst1), #Fr. pro Kubikmeter,
												 preis_grund_wasser = 10.25/(1+mwst1), #Fr. pro Monat
												 preis_grund_gas = 6.46/(1+mwst2), #Fr. pro Monat
												 preis_grund_strom = 7.00/(1+mwst2), #Fr. pro Monat
												 )

dfpreise <- rbind(preise2020,preise2021)
