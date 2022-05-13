#!/bin/bash

# script läuft per cron auf host smartmeter (oder auf einem der anderen raspis)

# Daten von powermeter-solar im Keller holen
solarenergy_panel0_today=`curl -s -X GET http://192.168.0.78/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Today'`
#echo $solarenergy_panel0_today
dt=$(date '+%Y-%m-%d_%H:%M:%S')

# direkt aufs NAS in ein File loggen
#echo $dt $solarenergy_panel0_today >> ~/mnt/nas/zaehlerlog/solar/solar_panel0.log
# lokal in ein File loggen, das periodisch (nachts) aufs NAS rsyncen per cron
echo $dt $solarenergy_panel0_today >> /var/tmp/solar_panel0.log
