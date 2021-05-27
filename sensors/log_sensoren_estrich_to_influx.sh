#!/bin/bash

# script läuft auf host cucina und loggt A/C-Temperaturen im Estrich

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`
# API_KEY_TS=`cat thingspeak_apikey`

# Daten von Sensor holen
MESSWERTEESTRICH=`./get_sensor_AM2302.py`

# umformatieren

# Messwertzeilen durch \n getrennt
MESS=`echo $MESSWERTEESTRICH | sed 's/ temperature/\ntemperature/g' `

#echo $MESS

# Daten in influxdb POSTen
curl -s -i -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=ms"\
	          --header "Authorization: Token $INFLUX_TOKEN"\
            --data-raw "$MESS "
