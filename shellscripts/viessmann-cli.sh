#!/bin/bash

##############################
# WW: Warmwassertemperatur der Heizung einstellen
##############################

# WW auf 33 Grad
# heizung-wwsoll.sh WW 32 

# WW auf 40 Grad Celsius
# heizung-wwsoll.sh WW 40


if [ "$1" == "WW" ]; then
	/usr/local/bin/vclient -c "setTempWWsoll $2"
fi

# Weitere Shortcuts bei Bedarf
