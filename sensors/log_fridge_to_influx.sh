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

# Daten von sonoff powermeter holen
factor_fridge=`curl -s -X GET http://192.168.0.80/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Factor'`
voltage_fridge=`curl -s -X GET http://192.168.0.80/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Voltage'`
current_fridge=`curl -s -X GET http://192.168.0.80/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Current'`

# I love bc :-) Leistung berechnen
power_fridge=`echo "$factor_fridge*$voltage_fridge*$current_fridge" | bc`

##############################
# Daten formatieren
##############################

# umformatieren, Beschreibung der Zahlenwerte dazu

FRIDGEPOWER=`echo power_FRIDGE value=$power_fridge`
FRIDGEVOLTAGE=`echo voltage_FRIDGE value=$voltage_fridge`
FRIDGECURRENT=`echo current_FRIDGE value=$current_fridge`
FRIDGEFACTOR=`echo factor_FRIDGE value=$factor_fridge`

# Messwertzeilen durch \n getrennt und auf jeder Zeile mit timestamp
MESSWERTE=$(printf '%s' "$FRIDGEPOWER")$' '$(printf '%u' "$TS")$'\n'
MESSWERTE+=$(printf '%s' "$FRIDGEVOLTAGE")$' '$(printf '%u' "$TS")$'\n'
MESSWERTE+=$(printf '%s' "$FRIDGECURRENT")$' '$(printf '%u' "$TS")$'\n'
MESSWERTE+=$(printf '%s' "$FRIDGEFACTOR")$' '$(printf '%u' "$TS")$'\n'

#echo $MESSWERTE

# Attention: precision of timestamp is specified in the POST request

# Daten in influxdb POSTen
curl -s -i -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=s"\
	          --header "Authorization: Token $INFLUX_TOKEN"\
            --data-raw "$MESSWERTE "
