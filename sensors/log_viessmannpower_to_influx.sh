#!/bin/bash

# script läuft auf host smartmeter

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`

# timestamp in seconds (see XPOST for the specification of the precision)
TS=`date +%s`
#echo $TS

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

# Messwertzeilen durch \n getrennt und auf jeder Zeile mit timestamp
MESSWERTE=$(printf '%s' "$THERMEPOWER")$' '$(printf '%u' "$TS")$'\n'
MESSWERTE+=$(printf '%s' "$THERMEVOLTAGE")$' '$(printf '%u' "$TS")$'\n'
MESSWERTE+=$(printf '%s' "$THERMECURRENT")$' '$(printf '%u' "$TS")$'\n'
MESSWERTE+=$(printf '%s' "$THERMEFACTOR")$' '$(printf '%u' "$TS")$'\n'

#echo $MESSWERTE

# Attention: precision of timestamp is specified in the POST request

# Daten in influxdb POSTen
curl -s -i -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=s"\
	          --header "Authorization: Token $INFLUX_TOKEN"\
            --data-raw "$MESSWERTE "
