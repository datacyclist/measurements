#!/bin/bash
#TXB=0
#for txbytes in /sys/class/net/eth0/statistics/tx_bytes ; do
TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
#echo $TEMP
#echo $(echo $( TEMP)/1000) 
TEMPROUNDED=`awk -v temp="$TEMP" 'BEGIN { rounded = sprintf("%.1f", temp/1000); print rounded }'`
echo $TEMPROUNDED°C
#				  let TXB+=$(<$txbytes)
#done
#
#sleep 2
#
#TXBN=0
#for txbytes in /sys/class/net/eth0/statistics/tx_bytes ; do
#					  let TXBN+=$(<$txbytes)
#done
#
##divide by two for the period, multiply by 10 to allow a correct decimal place
#TXDIF=$(echo $(((TXBN - TXB) * 5  )))
#
#SPEEDU="B/s up"
#
#if [ $TXDIF -ge 10240 ]; then
#				SPEEDU="Ki/s up"
#					TXDIF=$(echo $((TXDIF / 1024 )) )
#fi
#
#if [ $TXDIF -ge 10240 ]; then
#							SPEEDU="Mi/s up"
#								TXDIF=$(echo $((TXDIF / 1024 )) )
#fi
#
#if [ $TXDIF -ge 10240 ]; then
#									SPEEDU="Gi/s up"
#										TXDIF=$(echo $((TXDIF / 1024 )) )
#fi
#
#TXDIFF=$(($TXDIF % 10 ))
#TXDIFI=$(( $TXDIF / 10 ))
#TXDIF="$TXDIFI"
#
#if [ $TXDIFF -ne 0 ]; then
#TXDIF=$( echo  "$TXDIFI.$TXDIFF" )
#fi
#echo "$TXDIF $SPEEDU"
