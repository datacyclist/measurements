#!/bin/bash

# influx token in File ablegen, wird nicht mit abgelegt im GIT
INFLUX_TOKEN=`cat influx_token_read`

CSVDATA=`curl -s --request POST \
 "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/query?org=influx@georgruss.ch"\
  --header "Authorization: Token $INFLUX_TOKEN"\
	--header "Accept: application/csv" \
	--header "Content-type: application/vnd.flux" \
	--data '
   from(bucket: "od10_messwerte")
	  |> range(start: -1m)
    |> filter(fn: (r) => r["_measurement"] == "getTempWWist" or r["_measurement"] == "getTempVListM1" or r["_measurement"] == "getTempKist" or r["_measurement"] == "getTempAbgas")
	  |> filter(fn: (r) => r["_field"] == "value")
		|> aggregateWindow(every: 30s, fn: last, createEmpty: false)
		|> yield(name: "last")
		'
		`

echo "$CSVDATA"
#echo $CSVDATA | awk -F "," '{ print $2 }'
#echo "$CSVDATA" | awk -F "," '{ print $7 }'
#echo "$CSVDATA" | awk -v i=2 -v j=3 'NR == i {print $j}'
#echo "$CSVDATA" | awk 'NR == 2' | awk -F "," '{ print $7 }'
ABGASTEMP=`echo "$CSVDATA" | awk /getTempAbgas/ | awk -F "," '{ print $7 }'`
KESSELTEMP=`echo "$CSVDATA" | awk /getTempKist/ | awk -F "," '{ print $7 }'`
VORLAUFTEMP=`echo "$CSVDATA" | awk /getTempVListM1/ | awk -F "," '{ print $7 }'`
WWTEMP=`echo "$CSVDATA" | awk /getTempWWist/ | awk -F "," '{ print $7 }'`

echo $ABGASTEMP >> /var/tmp/abgastemp
echo $KESSELTEMP >> /var/tmp/kesseltemp
echo $VORLAUFTEMP >> /var/tmp/vorlauftemp
echo $WWTEMP >> /var/tmp/wwtemp
