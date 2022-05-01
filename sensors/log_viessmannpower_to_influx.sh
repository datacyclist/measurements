#!/bin/bash

# script läuft auf host smartmeter

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`

########################################
# Daten holen
########################################

# Daten von sonoff powermeter an der Viessmann-Gastherme holen
factor_therme=`curl -s -X GET http://192.168.0.79/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Factor'`
voltage_therme=`curl -s -X GET http://192.168.0.79/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Voltage'`
current_therme=`curl -s -X GET http://192.168.0.79/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Current'`

# I love bc :-) Leistung Therme berechnen
power_therme=`echo "$factor_therme*$voltage_therme*$current_therme" | bc`

##############################
# Daten formatieren
##############################

# umformatieren, Beschreibung der Zahlenwerte dazu

THERMEPOWER=`echo power_THERME value=$power_therme`
THERMEVOLTAGE=`echo voltage_THERME value=$voltage_therme`
THERMECURRENT=`echo current_THERME value=$current_therme`
THERMEFACTOR=`echo factor_THERME value=$factor_therme`

# alle Messwerte hintereinander
MESSWERTE=`echo $THERMEPOWER $THERMEVOLTAGE $THERMECURRENT $THERMEFACTOR`

# Messwertzeilen durch \n getrennt

# es wird immer der Anfang einer Messwertbezeichnung gesucht, z.B. " tempbuero"
# und ersetzt durch "\ntempbuero", also Leerzeichen durch Zeilenumbruch ersetzt

MESS=`echo $MESSWERTE | sed 's/ THERME/\nTHERME/g' `
#echo $MESS

#### Messwertzeilen durch \n getrennt

# echo $MESS

# such a mess...

# Daten in influxdb POSTen
curl -s -i -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=ms"\
	          --header "Authorization: Token $INFLUX_TOKEN"\
            --data-raw "$MESS "
