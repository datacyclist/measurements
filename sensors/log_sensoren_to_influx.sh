#!/bin/bash

# script läuft auf host smartmeter

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`
API_KEY_TS=`cat thingspeak_apikey`

# Daten von Heizung abholen, alles auf einmal :-)
#MESSWERTE=`/usr/local/bin/vclient -m -c 'getTempWWist,getTempWWsoll,getTempKist,getTempAged,getTempA,\
#getVolStrom,getBrennerStatus,getBrennerStarts,getBrennerStunden1,getLeistungIst,\
#getPumpeStatusM1,getPumpeDrehzahlIntern,getBetriebArt,getTempVListM1,getTempVLsollM1,getTempRL17A,getTempAbgas '`
#
#echo $MESSWERTE
# Daten von Sensor holen
MESSWERTEAUSSEN=`./get_sensor_bmp085.py`
MESSWERTEKELLER=`./get_sensor_DS18B20.py`

# umformatieren

#echo $MESSWERTE

# vorher
# getTempAged.value 8.500000

# nachher
# getTempAged value=8.500000

# alle Messwerte hintereinander
MESSWERTE="$MESSWERTEAUSSEN $MESSWERTEKELLER"

#echo $MESSWERTE

# Messwertzeilen durch \n getrennt

MESS=`echo $MESSWERTE | sed 's/ airpressure/\nairpressure/g;s/ basement/\nbasement/g' `

#echo $MESS

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
echo $TEMPERATUR_SUEDSEITE

LUFTDRUCK=`echo $MESSWERTEAUSSEN | sed 's/.*airpressure\svalue=\([0-9]*[0-9][0-9][0-9].[0-9]\).*/\1/'`
echo $LUFTDRUCK

#TEMPERATUR_WARMWASSER=`echo $MESSWERTE | sed 's/.*getTempWWist.value\s\(-*[0-9][0-9].[0-9]\).*getTempWWsoll.*/\1/'`
#echo $TEMPERATUR_NORDSEITE

#TEMPERATUR_HWR=`cat /var/tmp/bmp280_temperature`

curl -X GET -G https://api.thingspeak.com/update \
 	-d "api_key=$API_KEY_TS" \
 	-d "field4=$TEMPERATUR_SUEDSEITE" \
 	-d "field5=$LUFTDRUCK" \
     	--header "Content-type: application/x-www-form-urlencoded" \
  	--header "Accept: text/plain"
