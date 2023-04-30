auswertung:
	cd script; Rscript -e "source('10-verbrauchswerte.R')"

wassertagesstaende:
	cd script; Rscript -e "source('23-calculate-wasser-zaehlerstaende.R')"

stromtagesstaende_deprecated:
	cd script; Rscript -e "source('22-calculate-strom-zaehlerstaende-deprecated.R')"

stromtagesstaende:
	cd script; Rscript -e "source('22-calculate-strom-zaehlerstaende.R')"

stromvortag:
	cd script; Rscript -e "source('20-stromzaehler-vortageswerte.R')"

stromaktuell:
	cd script; Rscript -e "source('21-stromzaehler-aktuellertag.R')"
