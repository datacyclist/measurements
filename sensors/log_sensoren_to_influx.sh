#!/bin/bash

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`

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
            --data-raw "
	 $MESS
	            "

