#!/bin/bash

# script läuft auf host smartmeter

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`
API_KEY_TS=`cat thingspeak_apikey`

########################################
# Daten holen
########################################

# Daten von Sensor holen
MESSWERTEAUSSEN=`./get_sensor_bmp085.py`
MESSWERTEKELLER=`./get_sensor_DS18B20.py`

# Daten von powermeter-A/C im Estrich holen
factor=`curl -s -X GET http://192.168.0.77/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Factor'`
voltage=`curl -s -X GET http://192.168.0.77/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Voltage'`
current=`curl -s -X GET http://192.168.0.77/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Current'`

# I love bc :-)
power=`echo "$factor*$voltage*$current" | bc`

#dt=$(date '+%Y-%m-%d %H:%M:%S')
#echo $dt $power $factor $voltage $current

#MESSWERTEAUSSEN=`./get_sensor_bmp085.py`
#MESSWERTEKELLER=`./get_sensor_DS18B20.py`

##############################
# Daten formatieren
##############################

# umformatieren, Beschreibung der Zahlenwerte dazu

ACPOWER=`echo AC_power value=$power`
ACVOLTAGE=`echo AC_voltage value=$voltage`
ACCURRENT=`echo AC_current value=$current`
ACFACTOR=`echo AC_factor value=$factor`

# alle Messwerte hintereinander
MESSWERTE=`echo $MESSWERTEAUSSEN $MESSWERTEKELLER $ACPOWER $ACVOLTAGE $ACCURRENT $ACFACTOR`
#

# echo $MESSWERTE


# Messwertzeilen durch \n getrennt

MESS=`echo $MESSWERTE | sed 's/ airpressure/\nairpressure/g;s/ basement/\nbasement/g;s/ AC/\nAC/g' `


#### Messwertzeilen durch \n getrennt

# echo $MESS

# such a mess...

# Daten in influxdb POSTen
curl -s -i -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=ms"\
	          --header "Authorization: Token $INFLUX_TOKEN"\
            --data-raw "$MESS "

# Daten auch nach Thingspeak loggen
# GET https://api.thingspeak.com/update?api_key=XY8HCUA6HPMCWIHG&field1=0

##############################
# Daten auch noch nach thingspeak loggen
##############################

# vorher 20s warten -- thingspeak erlaubt nur updates alle 15s und der host
# raspberryiot sendet auch minütlich

sleep 30s

#echo $MESSWERTEAUSSEN
TEMPERATUR_SUEDSEITE=`echo $MESSWERTEAUSSEN | sed 's/.*temperature_sth\svalue=\(-*[0-9]*[0-9].[0-9]\).*air.*/\1/'`
#echo $TEMPERATUR_SUEDSEITE

LUFTDRUCK=`echo $MESSWERTEAUSSEN | sed 's/.*airpressure\svalue=\([0-9]*[0-9][0-9][0-9].[0-9]\).*/\1/'`
#echo $LUFTDRUCK

#TEMPERATUR_WARMWASSER=`echo $MESSWERTE | sed 's/.*getTempWWist.value\s\(-*[0-9][0-9].[0-9]\).*getTempWWsoll.*/\1/'`
#echo $TEMPERATUR_NORDSEITE

#TEMPERATUR_HWR=`cat /var/tmp/bmp280_temperature`

curl -X GET -G https://api.thingspeak.com/update \
 	-d "api_key=$API_KEY_TS" \
 	-d "field4=$TEMPERATUR_SUEDSEITE" \
 	-d "field5=$LUFTDRUCK" \
     	--header "Content-type: application/x-www-form-urlencoded" \
  	--header "Accept: text/plain"
