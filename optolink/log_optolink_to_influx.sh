#!/bin/bash

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`
API_KEY_TS=`cat thingspeak_apikey`
#echo $API_KEY_TS

# Daten von Heizung abholen, alles auf einmal :-)
MESSWERTE=`/usr/local/bin/vclient -m -c 'getTempWWist,getTempWWsoll,getTempKist,getTempAged,getTempA,\
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

# Daten in influxdb POSTen
curl -s -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=ms"\
	          --header "Authorization: Token $INFLUX_TOKEN"\
            --data-raw "$MESS"

##############################
# Daten nach thingspeak loggen
##############################

TEMPERATUR_NORDSEITE=`echo $MESSWERTE | sed 's/.*getTempA.value\s\(-*[0-9][0-9].[0-9]\).*getVol.*/\1/'`
#echo $TEMPERATUR_NORDSEITE

TEMPERATUR_WARMWASSER=`echo $MESSWERTE | sed 's/.*getTempWWist.value\s\(-*[0-9][0-9].[0-9]\).*getTempWWsoll.*/\1/'`
#echo $TEMPERATUR_NORDSEITE

TEMPERATUR_HWR=`cat /var/tmp/bmp280_temperature`

curl -X GET -G https://api.thingspeak.com/update \
	-d "api_key=$API_KEY_TS" \
	-d "field1=$TEMPERATUR_NORDSEITE" \
	-d "field2=$TEMPERATUR_WARMWASSER" \
	-d "field3=$TEMPERATUR_HWR" \
    	--header "Content-type: application/x-www-form-urlencoded" \
 	--header "Accept: text/plain"
