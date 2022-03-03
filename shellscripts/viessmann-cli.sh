#!/bin/bash

# config file vcontrold: /etc/vcontrold/vcontrold.xml

##############################
# WW: Warmwassertemperatur der Heizung einstellen
##############################

# WW auf 33 Grad
# viessmann-cli.sh WW 32 

# WW auf 40 Grad Celsius
# viessmann-cli.sh WW 40


if [ "$1" == "WW" ]; then
	/usr/local/bin/vclient -c "setTempWWsoll $2"
fi

# Schaltmodi Gasheizung:

# Heizung auf "Heizung + Warmwasser"
# viessmann-cli.sh BA NORM

# Heizung auf "nur Warmwasser"
# viessmann-cli.sh BA RED

# Heizung auf "Abschaltbetrieb"
# viessmann-cli.sh BA WW

if [ "$1" == "BA" ]; then
 	/usr/local/bin/vclient -c "setBetriebArtM1 $2"
fi

# Weitere Shortcuts bei Bedarf
