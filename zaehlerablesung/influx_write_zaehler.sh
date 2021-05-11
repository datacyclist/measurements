#!/bin/bash

INFLUX_TOKEN=`cat /home/russ/bin/measurements/zaehlerablesung/influx_token`

# Wenn das Script aufgerufen wird, wird ein Datenpunkt nach InfluxDB geschrieben.
# Der Datenpunkt entspricht 1Wh verbrauchter Energie.

curl -i -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=ms"\
	  --header "Authorization: Token $INFLUX_TOKEN"\
          --data-raw "
	  stromzaehler_1wh,host=smartmeter value=1
	  " 
