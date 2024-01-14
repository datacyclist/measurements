#!/bin/bash

# script läuft auf host cucina

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`
#echo $API_KEY_TS

TIMESTAMP=`date +"%s%3N"`
FILEDATE=`date +"%Y%m%d"`

#echo $TIMESTAMP

# Daten von Heizung abholen, alles auf einmal :-)
MESSWERTE=`/usr/bin/vclient -h 127.0.0.1:3002 -m -c 'getTempWWist,getTempWWsoll,\
getTempKist,getTempAged,\
getTempVListM1,\
getTempVLsollM1,\
getTempA,\
getBetriebArt,\
getVolStrom,getBrennerStatus,getBrennerStarts,getBrennerStunden1,getLeistungIst,\
getTempAbgas,\
getPumpeStatusM1,\
getPumpeDrehzahlIntern,getPumpeStatusIntern,\
getTempRaumNorSollM1,getUmschaltventil,getTempRL17A'`

#echo $MESSWERTE

#echo "\n"

# umformatieren

# vorher
# getTempAged.value 8.500000

# nachher
# getTempAged value=8.500000

# Messwertzeilen durch \n getrennt

# echo "reformatting\n"
MESS=`echo $MESSWERTE | sed 's/.value\ / value=/g'`
#echo $MESS
#echo "----"
MESS1=`echo $MESS | sed 's/getTemp\([a-zA-Z0-9]*\) value=/temperature \1=/g;s/=\([-]*[0-9.]*\) /=\1\n/g' `
#echo $MESS1 > /home/russ/tmp/log.txt

#echo $MESS1

#echo $TIMESTAMP
#MESS2=`echo $MESS1 | sed 's/ get/\nget/g' `
#echo $MESS2

#echo $MESS1 > /home/russ/tmp/log.txt
# such a mess...

printf "$MESS1 $TIMESTAMP" > /tmp/influxpost.txt

#echo $LOGCONTENT | tr -d '\n'
# echo "posting to influx\n"
##############################
# Daten in influxdb POSTen
##############################
#echo "---"
#curl -k -s -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=ms"\

curl -k -s -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte"\
 	          --header "Authorization: Token $INFLUX_TOKEN"\
						--data-binary @/tmp/influxpost.txt

						#--data-raw "temperature A=5\ntemperature B=7\ntemperature C=-2.5\n1705248127821"
#            --data-raw "$MESS1"
# (curl ohne Zertifikatprüfung: -k)

##############################
# echo "Daten in File ablegen zwecks späterer Auswertung in R\n"
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


# TEMPERATUR_NORDSEITE=`echo $MESSWERTE | sed 's/.*getTempA.value\s\(-*[0-9]*[0-9].[0-9]\).*getVol.*/\1/'`
#echo $TEMPERATUR_NORDSEITE

# TEMPERATUR_WARMWASSER=`echo $MESSWERTE | sed 's/.*getTempWWist.value\s\([0-9]*[0-9].[0-9]\).*getTempWWsoll.*/\1/'`
#echo $TEMPERATUR_NORDSEITE

#TEMPERATUR_HWR=`cat /var/tmp/bmp280_temperature`

#API_KEY_TS=`cat thingspeak_apikey`
#curl -k -X GET -G https://api.thingspeak.com/update \
#	-d "api_key=$API_KEY_TS" \
#	-d "field1=$TEMPERATUR_NORDSEITE" \
#	-d "field2=$TEMPERATUR_WARMWASSER" \
#    	--header "Content-type: application/x-www-form-urlencoded" \
# 	--header "Accept: text/plain"

#	-d "field3=$TEMPERATUR_HWR" \
