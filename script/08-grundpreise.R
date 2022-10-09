##############################
# Grundpreise und Bezugspreise festlegen
##############################

# Eine "Preiszeile" pro Jahr und Monat, wird dann später drangejoint an Verbrauchswerte
# fuer die Kostenberechnung

preise2023 <- tibble(
										 	jahr=2023,
										 	monat=c(1:12),
											mwst1 = 0.025, #2.5% Wasser
											mwst2 = 0.077, #7.7% Gas/Strom

											# Strom gesamt HT 31.07 Rp./kWh, Strom NT 24.06 Rp./kWh brutto
											preis_menge_strom_ht = (16.16+10.66)/(1+mwst2), #Rp. netto 
											preis_menge_strom_nt = (12.92+6.89)/(1+mwst2), #Rp.
											preis_menge_strom_sdl_kev_abgaben = (0.50+3.75)/(1+mwst2), #Rp.

											# Gas wird nochmal angepasst seitens TB Wil (Preise Q4/2022)
											preis_menge_gas = (5.17+1.21+0.43+2.34)/(1+mwst2), #Rp., Bruttopreise hier eintragen

											preis_menge_wasser = 1.28/(1+mwst1), #Fr. pro Kubikmeter,
											preis_menge_abwasser = 1.44/(1+mwst2), #Fr. pro Kubikmeter,
											preis_grund_wasser = 10.25/(1+mwst1), #Fr. pro Monat
											preis_grund_gas = 6.46/(1+mwst2), #Fr. pro Monat
											preis_grund_strom = 7.00/(1+mwst2), #Fr. pro Monat
											preis_grund_abwasser = 4.00/(1+mwst2), #Fr. pro Monat
										) %>%
	expand(jahr, monat, mwst1, mwst2, 
				 preis_menge_strom_ht, preis_menge_strom_nt, preis_menge_strom_sdl_kev_abgaben,
				 preis_menge_gas,preis_menge_wasser, preis_menge_abwasser, preis_grund_wasser, 
				 preis_grund_gas, preis_grund_strom, preis_grund_abwasser
				 )


preise2022_q4 <- tibble(
											# Preisanpassung Gas ab Oktober 2022 (etwa +25%)
											jahr=2022,
											monat=c(10:12),
											mwst1 = 0.025, #2.5% Wasser
											mwst2 = 0.077, #7.7% Gas/Strom
											preis_menge_strom_ht = (8.72+10.12)/(1+mwst2), #Rp. brutto get. durch Mwst.
											preis_menge_strom_nt = (7.65+6.25)/(1+mwst2), #Rp.
											preis_menge_strom_sdl_kev_abgaben = (0.17+3.75)/(1+mwst2), #Rp.

											preis_menge_gas = (5.17+1.21+0.43+2.34)/(1+mwst2), #Rp., Bruttopreise hier eintragen
											preis_menge_wasser = 1.28/(1+mwst1), #Fr. pro Kubikmeter,
											preis_menge_abwasser = 1.44/(1+mwst2), #Fr. pro Kubikmeter,
											preis_grund_wasser = 10.25/(1+mwst1), #Fr. pro Monat
											preis_grund_gas = 6.46/(1+mwst2), #Fr. pro Monat
											preis_grund_strom = 7.00/(1+mwst2), #Fr. pro Monat
											preis_grund_abwasser = 4.00/(1+mwst2), #Fr. pro Monat
											) %>%
	expand(jahr, monat, mwst1, mwst2, 
				 preis_menge_strom_ht, preis_menge_strom_nt, preis_menge_strom_sdl_kev_abgaben,
				 preis_menge_gas,preis_menge_wasser, preis_menge_abwasser, preis_grund_wasser, 
				 preis_grund_gas, preis_grund_strom, preis_grund_abwasser
				 )

preise2022_q1_q2_q3 <- tibble(
											jahr=2022,
											monat=c(1:9),
											mwst1 = 0.025, #2.5% Wasser
											mwst2 = 0.077, #7.7% Gas/Strom
											preis_menge_strom_ht = (8.72+10.12)/(1+mwst2), #Rp. netto (aus Bruttopreis errechnet)
											preis_menge_strom_nt = (7.65+6.25)/(1+mwst2), #Rp.
											preis_menge_strom_sdl_kev_abgaben = (0.17+3.75)/(1+mwst2), #Rp.
											# Strom HT 22.76 Rp./kWh, Strom NT 18.82 Rp./kWh
											preis_menge_gas = (3.70+0.90+0.40+2.169)/(1+mwst2), #Rp., Bruttopreis get. durch Mwst.
											preis_menge_wasser = 1.28/(1+mwst1), #Fr. pro Kubikmeter,
											preis_menge_abwasser = 1.44/(1+mwst2), #Fr. pro Kubikmeter,
											preis_grund_wasser = 10.25/(1+mwst1), #Fr. pro Monat
											preis_grund_gas = 6.46/(1+mwst2), #Fr. pro Monat
											preis_grund_strom = 7.00/(1+mwst2), #Fr. pro Monat
											preis_grund_abwasser = 4.00/(1+mwst2), #Fr. pro Monat
											) %>%
	expand(jahr, monat, mwst1, mwst2, 
				 preis_menge_strom_ht, preis_menge_strom_nt, preis_menge_strom_sdl_kev_abgaben,
				 preis_menge_gas,preis_menge_wasser, preis_menge_abwasser, preis_grund_wasser, 
				 preis_grund_gas, preis_grund_strom, preis_grund_abwasser
				 )

preise2021 <- tibble(
											jahr=2021,
											monat=c(1:12),
											mwst1 = 0.025, #2.5% Wasser
											mwst2 = 0.077, #7.7% Gas/Strom
											preis_menge_strom_ht = (8.08+9.91)/(1+mwst2), #Rp.
											preis_menge_strom_nt = (7.00+6.14)/(1+mwst2), #Rp.
											preis_menge_strom_sdl_kev_abgaben = (0.17+3.73)/(1+mwst2), #Rp.
											preis_menge_gas = (5.17+1.88)/(1+mwst2), #Rp.
											preis_menge_wasser = 1.28/(1+mwst1), #Fr. pro Kubikmeter,
											preis_menge_abwasser = 1.44/(1+mwst2), #Fr. pro Kubikmeter,
											preis_grund_wasser = 10.25/(1+mwst1), #Fr. pro Monat
											preis_grund_gas = 6.46/(1+mwst2), #Fr. pro Monat
											preis_grund_strom = 7.00/(1+mwst2), #Fr. pro Monat
											preis_grund_abwasser = 4.00/(1+mwst2), #Fr. pro Monat
										 ) %>%
	expand(jahr, monat, mwst1, mwst2, 
				 preis_menge_strom_ht, preis_menge_strom_nt, preis_menge_strom_sdl_kev_abgaben,
				 preis_menge_gas,preis_menge_wasser, preis_menge_abwasser, preis_grund_wasser, 
				 preis_grund_gas, preis_grund_strom, preis_grund_abwasser
				 )


preise2020 <- tibble(
										jahr=2020,
										monat=c(1:12),
										mwst1 = 0.025, #2.5% Wasser
										mwst2 = 0.077, #7.7% Gas/Strom
										preis_menge_strom_ht = (8.19+9.91)/(1+mwst2), #Rp.
										preis_menge_strom_nt = (7.11+6.14)/(1+mwst2), #Rp.
										preis_menge_strom_sdl_kev_abgaben = (0.17+3.73)/(1+mwst2), #Rp.
										preis_menge_gas = (5.17+1.88)/(1+mwst2), #Rp.
										preis_menge_wasser = 1.28/(1+mwst1), #Fr. pro Kubikmeter,
										preis_menge_abwasser = 1.44/(1+mwst2), #Fr. pro Kubikmeter,
										preis_grund_wasser = 10.25/(1+mwst1), #Fr. pro Monat
										preis_grund_gas = 6.46/(1+mwst2), #Fr. pro Monat
										preis_grund_strom = 7.00/(1+mwst2), #Fr. pro Monat
										preis_grund_abwasser = 4.00/(1+mwst2), #Fr. pro Monat
										) %>%
	expand(jahr, monat, mwst1, mwst2, 
				 preis_menge_strom_ht, preis_menge_strom_nt, preis_menge_strom_sdl_kev_abgaben,
				 preis_menge_gas,preis_menge_wasser, preis_menge_abwasser, preis_grund_wasser, 
				 preis_grund_gas, preis_grund_strom, preis_grund_abwasser
				 )


dfpreise <- rbind(preise2020,
									preise2021,
									preise2022_q1_q2_q3,
									preise2022_q4,
									preise2023)
