#!/bin/bash

# Dieses Skript loggt den Stromverbrauch eines am Mystrom-Switch (oder tasmota
# etc.) angeschlossenen Geräts und erstellt hinterher mit R/LaTeX ein PDF
# daraus.

# run this via nohup from another machine/app:
# ssh cucina "nohup mystrom-get-power.sh 1>/dev/null 2>/dev/null &"

# stop by creating the sentinel file:
# touch /var/tmp/stop-powerlog


HOME="/home/russ"
#echo $HOME
DATE=$(date '+%Y-%m-%d')
echo $DATE
SENTINELFILE="/var/tmp/stop-powerlog"

#echo "switch power logger started on" >> ~/tmp/uptimelog.txt
#echo 'datetime power' >> ~/nextcloud/powerlog/powerlog.txt

~/bin/switch-mystrom.sh 4 on

LOGFILE="${HOME}/tmp/${DATE}_powerlog.csv"                                                                           
echo 'date time power' > ${LOGFILE}

echo "Logging mystrom power to ${LOGFILE}"
g=0
while [ $g -eq 0 ]
  do
   JS=`curl -s -X GET http://192.168.0.48/report | jq -r '.power'`
   dt=$(date '+%Y-%m-%d %H:%M:%S')
   echo $dt $JS >> $LOGFILE
	 echo $dt $JS 
   sleep 1
	 read -n 1 -t 1 inputkey
	 if [[ -f $SENTINELFILE ]] ; then
					 break;
	 fi
	 # if it is run in an interactive session, just hit q
	 if [[ $inputkey = q ]] ; then 
					 break;
	 fi
done

cp $LOGFILE ${HOME}/mnt/nas/powerlog/

~/bin/switch-mystrom.sh 4 off

cd ~/mnt/nas/powerlog/
rm $SENTINELFILE

make report logfile=${DATE}_powerlog.csv
