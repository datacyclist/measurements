#!/bin/bash

# script läuft auf host smartmeter

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`
#API_KEY_TS=`cat thingspeak_apikey`

#g=0
#while [ $g -eq 0 ]
#	  do

# Daten von powermeter-A/C im Estrich holen
energytoday=`curl -s -X GET http://192.168.0.77/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Today'`
factor=`curl -s -X GET http://192.168.0.77/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Factor'`
voltage=`curl -s -X GET http://192.168.0.77/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Voltage'`
current=`curl -s -X GET http://192.168.0.77/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Current'`
power=`echo "$factor*$voltage*$current" | bc`
dt=$(date '+%Y-%m-%d %H:%M:%S')
#echo $dt $power $factor $voltage $current

#MESSWERTEAUSSEN=`./get_sensor_bmp085.py`
#MESSWERTEKELLER=`./get_sensor_DS18B20.py`

# umformatieren

#
ACPOWER=`echo AC_power value=$power`
ACVOLTAGE=`echo AC_voltage value=$voltage`
ACCURRENT=`echo AC_current value=$current`
ACFACTOR=`echo AC_factor value=$factor`
ACENERGYTODAY=`echo AC_energytoday value=$energytoday`

## alle Messwerte hintereinander
MESSWERTE=`echo $ACPOWER $ACVOLTAGE $ACCURRENT $ACFACTOR $ACENERGYTODAY`
#
#echo $MESSWERTE

#### Messwertzeilen durch \n getrennt
MESS=`echo $MESSWERTE | sed 's/ AC/\nAC/g' `

# echo $MESS

# Daten in influxdb POSTen
curl -s -i -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=ms"\
	          --header "Authorization: Token $INFLUX_TOKEN"\
            --data-raw "$MESS "
