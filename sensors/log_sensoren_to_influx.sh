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

# I love bc :-) Leistung A/C berechnen
power=`echo "$factor*$voltage*$current" | bc`

# tasmota im Buero
tempbuero=`curl -s -X GET http://192.168.0.75/cm?cmnd=Status%208 | jq -r '.StatusSNS.DS18B20.Temperature'`
#echo $tempbuero
# tasmota im Schlafzimmer
tempbett=`curl -s -X GET http://192.168.0.76/cm?cmnd=Status%208 | jq -r '.StatusSNS.DS18B20.Temperature'`


# Daten von sonoff powermeter am Solarpanel holen
factor_solar=`curl -s -X GET http://192.168.0.78/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Factor'`
voltage_solar=`curl -s -X GET http://192.168.0.78/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Voltage'`
current_solar=`curl -s -X GET http://192.168.0.78/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Current'`

# I love bc :-) Leistung Solar berechnen
power_solar=`echo "$factor_solar*$voltage_solar*$current_solar" | bc`

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
TEMPBUERO=`echo temperature_buero value=$tempbuero`
TEMPBETT=`echo temperature_bett value=$tempbett`
SOLARPOWER=`echo SOLAR_power value=$power_solar`
SOLARVOLTAGE=`echo SOLAR_voltage value=$voltage_solar`
SOLARCURRENT=`echo SOLAR_current value=$current_solar`
SOLARFACTOR=`echo SOLAR_factor value=$factor_solar`

# alle Messwerte hintereinander
MESSWERTE=`echo $MESSWERTEAUSSEN $MESSWERTEKELLER $ACPOWER $ACVOLTAGE $ACCURRENT $ACFACTOR $SOLARPOWER $SOLARVOLTAGE $SOLARCURRENT $SOLARFACTOR $TEMPBUERO $TEMPBETT`
#

# echo $MESSWERTE


# Messwertzeilen durch \n getrennt

# es wird immer der Anfang einer Messwertbezeichnung gesucht, z.B. " tempbuero"
# und ersetzt durch "\ntempbuero", also Leerzeichen durch Zeilenumbruch ersetzt

MESS=`echo $MESSWERTE | sed 's/ airpressure/\nairpressure/g;s/ basement/\nbasement/g;s/ AC/\nAC/g;s/ SOLAR/\nSOLAR/g;s/ temperature_buero/\ntemperature_buero/g;s/ temperature_bett/\ntemperature_bett/g' `


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
