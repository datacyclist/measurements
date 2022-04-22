#!/bin/bash

########################################
# requires dconv (from package dateutils)
# script läuft auf raspberryiot (bzw. dem Host, der das FHEM hat)

# dieses Script benutzt die Logfiles, die FHEM pro Heizungsthermostat in
# /opt/fhem/log ablegt

# es werden einzelne Parameter der Thermostate aus dem unteren (=aktuellen)
# Ende des Logfiles mit Timestamp ausgelesen

# die Daten werden in das Format gebracht, das influxDB im lineProtocol erwartet

# Beispiel für eine einzelne Zeile im Line-Protocol:
# valveposition,thermostat=MAX_009404 value=0 1620937787

########################################

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token`
#API_KEY_TS=`cat thingspeak_apikey`


# Daten von Thermostaten aus deren FHEM-Logfiles abholen

# Welche Thermostate?
thermostate=( MAX_00a661 MAX_008bb8 MAX_008cd0 MAX_008d29 MAX_00904d MAX_009363 MAX_0090bf MAX_00a256 MAX_009404 MAX_008ca7 )

# Variable leer initialisieren
CURL_INFLUX_LOG=''

# Jahr variabel setzen (fiel von 2021 auf 2022 auf :-) )
JAHR=$(date '+%Y')

for MAX_PREFIX in "${thermostate[@]}"
do
	#MAX_PREFIX='MAX_0090bf'
	#echo $MAX_PREFIX
	
	LOGSNIPPET=`tail -n 8 /opt/fhem/log/$MAX_PREFIX-$JAHR.log`
	#echo "$LOGSNIPPET"
	
	# wichtig: für den Timestamp muss eine Herkunfts-Zeitzone angegeben
	# werden -- ansonsten macht dconv daraus einen UNIX-Epoch-Timestamp in
	# der Zukunft, und wenn man den im Lineprotocol für InfluxDB verwenden
	# möchte, werden die entsprechenden Daten im Request zwar quittiert,
	# aber verworfen
	
	TIMESTAMP=`echo "$LOGSNIPPET" | tail -n 1  | 
	  awk '{ print $1}' | 
	  dateutils.dconv -i "%Y-%m-%d_%H:%M:%S" --from-zone Europe/Berlin -f '%s'`
	
	
	# der berechnete Unix-Timestamp in Sekunden wird an awk als Variable explizit mit übergeben

	DESIREDTEMP=`echo "$LOGSNIPPET" |
	grep 'desiredTemperature:' | 
	awk -v ts=$TIMESTAMP '{printf substr($3,1,length($3)-1)",thermostat="$2" value="$4" "ts}'`
	#echo $DESIREDTEMP
	
	TEMPERATURE=`echo "$LOGSNIPPET" |
	grep 'temperature:' | 
	awk -v ts=$TIMESTAMP '{printf substr($3,1,length($3)-1)",thermostat="$2" value="$4" "ts}'`
	#echo $TEMPERATURE
	
	VALVEPOSITION=`echo "$LOGSNIPPET" | 
	grep 'valveposition:' | 
	awk -v ts=$TIMESTAMP '{printf substr($3,1,length($3)-1)",thermostat="$2" value="$4" "ts}'`
	#echo $VALVEPOSITION
	
	# Datenblock pro Thermostat generieren
	DATABLOCK=${DESIREDTEMP}
	DATABLOCK+=`echo -e "\n "`
	DATABLOCK+=${TEMPERATURE}
	DATABLOCK+=`echo -e "\n "`
	DATABLOCK+=${VALVEPOSITION}
	
	#echo "$DATABLOCK"
	
	# Datenblock an Influx-Log-Variable anhängen
	CURL_INFLUX_LOG+=${DATABLOCK}
	CURL_INFLUX_LOG+=`echo -e "\n "`

done

# echo $CURL_INFLUX_LOG

# So, jetzt alles nach InfluxDB abkippen, friss und stirb :-)
# (curl ohne Zertifikat-Pruefung: -k)
echo "$CURL_INFLUX_LOG" | 
curl -k -i -s -XPOST "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/write?org=influx@georgruss.ch&bucket=od10_messwerte&precision=s"\
   	   --header "Authorization: Token $INFLUX_TOKEN"\
            --data-binary @-

