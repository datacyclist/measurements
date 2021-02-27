auswertung:
	cd script; Rscript -e "source('10-verbrauchswerte.R')"

stromvortag:
	cd script; Rscript -e "source('20-stromzaehler-vortageswerte.R')"

stromaktuell:
	cd script; Rscript -e "source('21-stromzaehler-aktuellertag.R')"
