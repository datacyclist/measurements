#!/bin/bash

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token_read`

# curl ohne Zertifikatprüfung: -k
CSVDATA=`curl -s -k --request POST \
 "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/query?org=influx@georgruss.ch"\
  --header "Authorization: Token $INFLUX_TOKEN"\
	--header "Accept: application/csv" \
	--header "Content-type: application/vnd.flux" \
	--data '
   from(bucket: "od10_messwerte")
	  |> range(start: -2m)
		|> truncateTimeColumn(unit: 1m)
    |> filter(fn: (r) => r["_measurement"] == "getTempA" or r["_measurement"] == "temperature_sth" )
		|> lowestMin(
		    n:1,
			 column: "_value",
			 groupColumns: [])
		'
		`

#echo "$CSVDATA"
#echo $CSVDATA | awk -F "," '{ print $2 }'
#echo "$CSVDATA" | awk -F "," '{ print $7 }'
#echo "$CSVDATA" | awk -v i=2 -v j=3 'NR == i {print $j}'
#echo "$CSVDATA" | awk 'NR == 2' | awk -F "," '{ print $7 }'
#ABGASTEMP=`echo "$CSVDATA" | awk /getTempAbgas/ | awk -F "," '{ print $7;exit; }'`
#KESSELTEMP=`echo "$CSVDATA" | awk /getTempKist/ | awk -F "," '{ print $7;exit; }'`
#VORLAUFTEMP=`echo "$CSVDATA" | awk /getTempVListM1/ | awk -F "," '{ print $7;exit; }'`

# such aus dem String aus der Influx-DB-Query (nur eine Zeile) den ganz hinten
# stehenden Wert raus (= derjenige, der an neunter Stelle steht)
TEMP1=`echo "$CSVDATA" | awk /_result/ | awk -F "," '{ print $9;exit; }'` 
#echo "$TEMP1" | xargs printf "%.2f \n"
TEMPROUNDED=`awk -v temp="$TEMP1" 'BEGIN { rounded = sprintf("%.1f", temp); print rounded }'`
echo $TEMPROUNDED

#echo $ABGASTEMP > /var/tmp/abgastemp
#echo $KESSELTEMP > /var/tmp/kesseltemp
#echo $VORLAUFTEMP > /var/tmp/vorlauftemp
#echo $WWTEMP > /var/tmp/wwtemp
