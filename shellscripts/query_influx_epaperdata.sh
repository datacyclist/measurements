#!/bin/bash

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token_read`

# Tagesnetzbezug elektrische Energie holen
# curl ohne Zertifikatprüfung: -k
CSVDATA=`curl -s -k --request POST \
 "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/query?org=influx@georgruss.ch"\
  --header "Authorization: Token $INFLUX_TOKEN"\
	--header "Accept: application/csv" \
	--header "Content-type: application/vnd.flux" \
	--data '
	from(bucket: "od10_messwerte")
		|> range(start: today(), stop: now())
		|> filter(fn: (r) => r["_measurement"] == "stromzaehler_1wh")
	  |> filter(fn: (r) => r["_field"] == "value")
 		|> elapsed(unit: 1ms)
		|> sum()
		'
		`
WH=`echo "$CSVDATA" | awk /_result/ | awk -F "," '{ print $9;exit; }'` 
echo $WH > /var/log/netzbezug_Wh

# Tageserzeugung Solar holen
# curl ohne Zertifikatprüfung: -k
CSVDATA=`curl -s -k --request POST \
 "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/query?org=influx@georgruss.ch"\
  --header "Authorization: Token $INFLUX_TOKEN"\
	--header "Accept: application/csv" \
	--header "Content-type: application/vnd.flux" \
	--data '
	from(bucket: "od10_messwerte")
	   	|> range(start:-1h)
		|> filter(fn: (r) => r["_measurement"] == "SOLAR_ENERGY_TODAY_kWh")
		|> filter(fn: (r) => r["_field"] == "value")
		|> tail(n:1)
		'
		`
#echo $CSVDATA
SolarkWh=`echo "$CSVDATA" | awk /_result/ | awk -F "," '{ print $7;exit; }'` 
echo $SolarkWh > /var/log/solar_kWh
#echo $SolarkWh

# Tagesverbrauch A/C holen
CSVDATA=`curl -s -k --request POST \
 "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/query?org=influx@georgruss.ch"\
  --header "Authorization: Token $INFLUX_TOKEN"\
	--header "Accept: application/csv" \
	--header "Content-type: application/vnd.flux" \
	--data '
	from(bucket: "od10_messwerte")
	   	|> range(start:-1h)
		|> filter(fn: (r) => r["_measurement"] == "AC_energytoday")
		|> filter(fn: (r) => r["_field"] == "value")
		|> tail(n:1)
		'
		`
#echo $CSVDATA
AC_kWh=`echo "$CSVDATA" | awk /_result/ | awk -F "," '{ print $7;exit; }'` 
echo $AC_kWh > /var/log/AC_kWh
#echo $SolarkWh

# Tageswasserverbrauch holen
CSVDATA=`curl -s -k --request POST \
 "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/query?org=influx@georgruss.ch"\
  --header "Authorization: Token $INFLUX_TOKEN"\
	--header "Accept: application/csv" \
	--header "Content-type: application/vnd.flux" \
	--data '
	from(bucket: "od10_messwerte")
		|> range(start: today(), stop: now())
		|> filter(fn: (r) => r["_measurement"] == "wasserzaehler_1l")
	  |> filter(fn: (r) => r["_field"] == "value")
 		|> elapsed(unit: 1ms)
		|> sum()
		'
		`
WasserL=`echo "$CSVDATA" | awk /_result/ | awk -F "," '{ print $9;exit; }'` 
echo $WasserL > /var/log/wasser_l
#echo $WasserL

# aktuelle Solarleistung holen
CSVDATA=`curl -s -k --request POST \
 "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/query?org=influx@georgruss.ch"\
  --header "Authorization: Token $INFLUX_TOKEN"\
	--header "Accept: application/csv" \
	--header "Content-type: application/vnd.flux" \
	--data '
	from(bucket: "od10_messwerte")
	   |> range(start:-2m)
		 |> truncateTimeColumn(unit: 1m)
		 |> filter(fn: (r) => r["_measurement"] == "SOLAR_power")
		 |> filter(fn: (r) => r["_field"] == "value")
		'
		`

SolarW=`echo "$CSVDATA" | awk /_result/ | awk -F "," '{ print $9;exit; }'` 
# mit awk runden
echo $SolarW | awk '{print int($1)}' > /var/log/solar_W
