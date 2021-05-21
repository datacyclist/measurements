#!/bin/bash
IMGDIR="/var/tmp/"
#echo $HOME                                                                                                                                                   
DATETIME=$(date '+%Y-%m-%d-%H-%M')                                                                                                                                      
echo $DATE                                                                                                                                                    
                                                                                                                                                              
#echo "switch power logger started on" >> ~/tmp/uptimelog.txt                                                                                                 
#echo 'datetime power' >> ~/nextcloud/powerlog/powerlog.txt                                                                                                   
                                                                                                                                                              
#CAM0_FILE="${IMGDIR}/${DATETIME}_video0_wasser.jpg"                                                                                                                    
CAM0_FILE="${IMGDIR}/${DATETIME}_video0_gas.jpg"                                                                                                                    
#echo 'date time power' > ${LOGFILE}   

#/usr/bin/fswebcam -d /dev/video0 -r 640x480 $CAM0_FILE
#sleep 2
/usr/bin/fswebcam -d /dev/video0 -r 640x480 $CAM0_FILE
