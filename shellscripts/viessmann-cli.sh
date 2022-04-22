#!/bin/bash

##############################
# WW: Warmwassertemperatur der Heizung einstellen
##############################

# WW auf 33 Grad
# viessmann-cli.sh WW 32 

# WW auf 40 Grad Celsius
# viessmann-cli.sh WW 40


if [ "$1" == "WW" ]; then
	/usr/bin/vclient -c "setTempWWsoll $2"
fi

# Heizung auf "Heizung + Warmwasser"
# viessmann-cli.sh BA NORM
# Heizung auf "nur WW"
# viessmann-cli.sh BA RED

if [ "$1" == "BA" ]; then
 	/usr/bin/vclient -c "setBetriebArtM1 $2"
fi

# Weitere Shortcuts bei Bedarf
