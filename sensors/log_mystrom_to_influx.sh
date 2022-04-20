#!/bin/bash

# script läuft auf host smartmeter

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`
API_KEY_TS=`cat thingspeak_apikey`

########################################
# Daten holen
########################################

# Daten von mystrom-powermeter 192.168.0.45 (HWR: NAS+RASPIS) holen
power_mystrom_HWR=`curl -s -X GET http://192.168.0.45/report | jq -r '.power'`
# Daten von mystrom-powermeter 192.168.0.46 (PC) holen
power_mystrom_PC=`curl -s -X GET http://192.168.0.46/report | jq -r '.power'`
# Daten von mystrom-powermeter 192.168.0.47 (Wohnzimmer: Glasfaser/Router/VPN) holen
power_mystrom_WZ=`curl -s -X GET http://192.168.0.47/report | jq -r '.power'`
# Daten von mystrom-powermeter 192.168.0.55 (Wohnzimmer: Projektor) holen
power_mystrom_Proj=`curl -s -X GET http://192.168.0.55/report | jq -r '.power'`

## #dt=$(date '+%Y-%m-%d %H:%M:%S')
## #echo $dt $power $factor $voltage $current
## 
## ##############################
## # Daten formatieren
## ##############################
## 
## # umformatieren, Beschreibung der Zahlenwerte dazu
## 
POWER_HWR=`echo power_HWR value=$power_mystrom_HWR`
POWER_PC=`echo power_PC value=$power_mystrom_PC`
POWER_WZ=`echo power_WZ value=$power_mystrom_WZ`
POWER_PROJ=`echo power_PROJ value=$power_mystrom_Proj`
 
## # alle Messwerte hintereinander
MESSWERTE=`echo $POWER_HWR $POWER_PC $POWER_WZ $POWER_PROJ`
## #
## 
# echo $MESSWERTE
## 
## 
## # Messwertzeilen durch \n getrennt
## 
## # es wird immer der Anfang einer Messwertbezeichnung gesucht, z.B. " tempbuero"
## # und ersetzt durch "\ntempbuero", also Leerzeichen durch Zeilenumbruch ersetzt
## 
MESS=`echo $MESSWERTE | sed 's/ power/\npower/g' `
## 
## 
## #### Messwertzeilen durch \n getrennt
## 
# echo $MESS
## 
# Daten in influxdb POSTen
curl -s -i -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=ms"\
  	          --header "Authorization: Token $INFLUX_TOKEN"\
              --data-raw "$MESS "
