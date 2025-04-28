#!/bin/bash

# script läuft auf host vpnhole minütlich in crontab                                                                                        
# * * * * * cd ~/bin/measurements/sensors && ../log_waschmaschine_to_influx.sh

# Leistungswerte der Waschmaschine nach influxDB loggen

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`

# timestamp in seconds (see XPOST for the specification of the precision)
TS=`date +%s`
#echo $TS

########################################
# Daten holen 
########################################

# Daten von sonoff powermeter an der Viessmann-Gaswaschmaschine holen
factor_waschmaschine=`curl -s -X GET http://192.168.0.81/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Factor'`
voltage_waschmaschine=`curl -s -X GET http://192.168.0.81/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Voltage'`
current_waschmaschine=`curl -s -X GET http://192.168.0.81/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Current'`

# I love bc :-) Leistung Waschmaschine berechnen
power_waschmaschine=`echo "$factor_waschmaschine*$voltage_waschmaschine*$current_waschmaschine" | bc`

# Daten von sonoff powermeter am Quooker holen
factor_quooker=`curl -s -X GET http://192.168.0.82/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Factor'`
voltage_quooker=`curl -s -X GET http://192.168.0.82/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Voltage'`
current_quooker=`curl -s -X GET http://192.168.0.82/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Current'`

# I love bc :-) Leistung Quooker berechnen
power_quooker=`echo "$factor_quooker*$voltage_quooker*$current_quooker" | bc`

##############################
# Daten formatieren
##############################

# umformatieren, Beschreibung der Zahlenwerte dazu

WASCHMASCHINEPOWER=`echo power_WASCHMASCHINE value=$power_waschmaschine`
WASCHMASCHINEVOLTAGE=`echo voltage_WASCHMASCHINE value=$voltage_waschmaschine`
WASCHMASCHINECURRENT=`echo current_WASCHMASCHINE value=$current_waschmaschine`
WASCHMASCHINEFACTOR=`echo factor_WASCHMASCHINE value=$factor_waschmaschine`

# Messwertzeilen durch \n getrennt und auf jeder Zeile mit timestamp
MESSWERTE=$(printf '%s' "$WASCHMASCHINEPOWER")$' '$(printf '%u' "$TS")$'\n'
MESSWERTE+=$(printf '%s' "$WASCHMASCHINEVOLTAGE")$' '$(printf '%u' "$TS")$'\n'
MESSWERTE+=$(printf '%s' "$WASCHMASCHINECURRENT")$' '$(printf '%u' "$TS")$'\n'
MESSWERTE+=$(printf '%s' "$WASCHMASCHINEFACTOR")$' '$(printf '%u' "$TS")$'\n'

QUOOKERPOWER=`echo power_QUOOKER value=$power_quooker`
QUOOKERVOLTAGE=`echo voltage_QUOOKER value=$voltage_quooker`
QUOOKERCURRENT=`echo current_QUOOKER value=$current_quooker`
QUOOKERFACTOR=`echo factor_QUOOKER value=$factor_quooker`

# Messwertzeilen durch \n getrennt und auf jeder Zeile mit timestamp
MESSWERTEQ=$(printf '%s' "$QUOOKERPOWER")$' '$(printf '%u' "$TS")$'\n'
MESSWERTEQ+=$(printf '%s' "$QUOOKERVOLTAGE")$' '$(printf '%u' "$TS")$'\n'
MESSWERTEQ+=$(printf '%s' "$QUOOKERCURRENT")$' '$(printf '%u' "$TS")$'\n'
MESSWERTEQ+=$(printf '%s' "$QUOOKERFACTOR")$' '$(printf '%u' "$TS")$'\n'

#echo $MESSWERTE

# Attention: precision of timestamp is specified in the POST request

# Daten in influxdb POSTen
curl -s -i -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=s"\
	          --header "Authorization: Token $INFLUX_TOKEN"\
            --data-raw "$MESSWERTE $MESSWERTEQ"
