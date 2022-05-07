#!/bin/bash

# script läuft auf host raspberryiot

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`
API_KEY_TS=`cat thingspeak_apikey`
#echo $API_KEY_TS

TIMESTAMP=`date +"%s"`
FILEDATE=`date +"%Y%m%d"`

# Daten von Heizung abholen, alles auf einmal :-)
MESSWERTE=`/usr/bin/vclient -h 127.0.0.1:3002 -m -c 'getTempWWist,getTempWWsoll,getTempKist,getTempAged,getTempA,\
getVolStrom,getBrennerStatus,getBrennerStarts,getBrennerStunden1,getLeistungIst,\
getPumpeStatusM1,getPumpeDrehzahlIntern,getBetriebArt,getTempVListM1,getTempVLsollM1,getTempRL17A,getTempAbgas '`

#echo $MESSWERTE

# umformatieren

# vorher
# getTempAged.value 8.500000

# nachher
# getTempAged value=8.500000

# Messwertzeilen durch \n getrennt

MESS=`echo $MESSWERTE | sed 's/ get/\nget/g;s/.value\ / value=/g' `

# such a mess...

##############################
# Daten in influxdb POSTen
##############################

curl -k -s -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=ms"\
	          --header "Authorization: Token $INFLUX_TOKEN"\
            --data-raw "$MESS"

# (curl ohne Zertifikatprüfung: -k)

##############################
# Daten in File ablegen zwecks späterer Auswertung in R
##############################
LOGLINE=$TIMESTAMP" "$MESSWERTE

#echo $MESSWERTE >> ~/mnt/nas/zaehlerlog/gastherme/$DATE-optolinklog.csv

# nicht mehr aufs NAS loggen, damit dessen Platte runterfahren kann
# stattdessen in lokales File, das nach Mitternacht per cron/rsync aufs NAS kopiert wird
#echo $LOGLINE >> ~/mnt/nas/zaehlerlog/gastherme/$FILEDATE-optolinklog.csv
echo $LOGLINE >> /var/tmp/$FILEDATE-optolinklog.csv

##############################
# einzelne Messwerte nach thingspeak loggen
##############################

TEMPERATUR_NORDSEITE=`echo $MESSWERTE | sed 's/.*getTempA.value\s\(-*[0-9]*[0-9].[0-9]\).*getVol.*/\1/'`
#echo $TEMPERATUR_NORDSEITE

TEMPERATUR_WARMWASSER=`echo $MESSWERTE | sed 's/.*getTempWWist.value\s\([0-9]*[0-9].[0-9]\).*getTempWWsoll.*/\1/'`
#echo $TEMPERATUR_NORDSEITE

#TEMPERATUR_HWR=`cat /var/tmp/bmp280_temperature`

curl -k -X GET -G https://api.thingspeak.com/update \
	-d "api_key=$API_KEY_TS" \
	-d "field1=$TEMPERATUR_NORDSEITE" \
	-d "field2=$TEMPERATUR_WARMWASSER" \
    	--header "Content-type: application/x-www-form-urlencoded" \
 	--header "Accept: text/plain"

#	-d "field3=$TEMPERATUR_HWR" \
