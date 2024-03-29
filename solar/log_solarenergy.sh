#!/bin/bash

# script läuft per cron auf host smartmeter (oder auf einem der anderen raspis)

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`
#API_KEY_TS=`cat thingspeak_apikey`

# Daten von powermeter-solar im Keller holen
solarenergy_panel0_today=`curl -s -X GET http://192.168.0.78/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Today'`
solarenergy_panel12_today=`curl -s -X GET http://192.168.0.80/cm?cmnd=Status%208 | jq -r '.StatusSNS.ENERGY.Today'`
#echo $solarenergy_panel0_today
dt=$(date '+%Y-%m-%d_%H:%M:%S')

# direkt aufs NAS in ein File loggen
#echo $dt $solarenergy_panel0_today >> ~/mnt/nas/zaehlerlog/solar/solar_panel0.log
# lokal in ein File loggen, das periodisch (nachts) aufs NAS rsyncen per cron
echo $dt $solarenergy_panel0_today >> /var/tmp/solar_panel0.log
echo $dt $solarenergy_panel12_today >> /var/tmp/solar_panel12.log
#!/bin/bash

SOLARENERGYTODAY_PANEL0=`echo SOLAR_ENERGY_TODAY_kWh_panel0 value=$solarenergy_panel0_today`
SOLARENERGYTODAY_PANEL12=`echo SOLAR_ENERGY_TODAY_kWh_panel12 value=$solarenergy_panel12_today`

## alle Messwerte hintereinander
MESSWERTE=`echo $SOLARENERGYTODAY_PANEL0 $SOLARENERGYTODAY_PANEL12`
#
#echo $MESSWERTE

#### Messwertzeilen durch \n getrennt
MESS=`echo $MESSWERTE | sed 's/ SOLAR/\nSOLAR/g' `

# echo $MESS

# Daten in influxdb POSTen
curl -s -i -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=ms"\
	          --header "Authorization: Token $INFLUX_TOKEN"\
            --data-raw "$MESS "
