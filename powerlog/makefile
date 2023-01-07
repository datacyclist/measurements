reportfile := $(shell date +%F_%T)_report_power.pdf
report:
	Rscript -e "library(knitr); logfile='$(logfile)'; knit('power-analyse.Rnw')"
	pdflatex power-analyse.tex
	pdflatex power-analyse.tex
	cp power-analyse.pdf $(reportfile)

reportlocal:
	Rscript -e "library(knitr); logfile='2020-11-12_powerlog.csv'; knit('power-analyse.Rnw')"
	pdflatex power-analyse.tex
	pdflatex power-analyse.tex
	cp power-analyse.pdf $(reportfile)

