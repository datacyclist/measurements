#!/usr/bin/python
# -*- coding: utf-8 -*-
import math
import time
import os
#import datetime
#import dateutil
from datetime import datetime,date
from time import gmtime,strftime
import http.client, urllib
import pytz
import subprocess
# import bme280

#########################################
# dieses Script wird in einem systemd-service gestartet
########################################
# Anlegen des Services 'wasserzaehler.service' in /lib/systemd/system
# 
# [Unit]
# Description=Wasserzaehler-Logger
# After=multi-user.target
# 
# [Service]
# ExecStart=/usr/bin/python /home/russ/bin/zaehler/get_wasserzaehler.py
# 
# [Install]
# WantedBy=multi-user.target
########################################


def append_new_line(file_name, text_to_append):
    """Append given text as a new line at the end of file"""
    # Open the file in append & read mode ('a+')
    with open(file_name, "a+") as file_object:
        # Move read cursor to the start of file.
        file_object.seek(0)
        # If file is not empty then append '\n'
        data = file_object.read(100)
        if len(data) >= 0:
            # Append text at the end of file
            file_object.write(text_to_append)
            # append newline
            file_object.write("\n")

import RPi.GPIO as GPIO

# GPIO ueber Nummern ansprechen
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

# Pin fuer Taster als Input-Pin setzen
# GPIO.setup(13, GPIO.IN)
# Pin fuer Fototransistor als Input-Pin setzen
GPIO.setup(25, GPIO.IN)
# Pin fuer LED als Output-Pin setzen
# GPIO.setup(26, GPIO.OUT)

#dtobj = datetime.now(tzinfo=utc)
#print(dtobj)

# ##############################
# # fünfmal Blinken der LED beim Start
# ##############################
# 
# for i in range(5):
#    GPIO.output(26, GPIO.HIGH)
#    time.sleep(0.15)
#    GPIO.output(26, GPIO.LOW)
#    time.sleep(0.15)

# Taster testen
# input_13=GPIO.input(13)
# print input_13

tz = pytz.timezone('Europe/Zurich')


########################################
# Endlosschleife fuers Datenloggen (eine Zeile ins CSV pro S0-Impuls, ein CSV
# pro Tag, muss für Weiterverarbeitung z.B. per cronjob und rsync abgeholt
# werden:
#
# z.B. so in crontab (alle fuenf Minuten)
# */5 * * * * rsync --update /var/tmp/*wasser* /home/russ/mnt/nas/zaehlerlog/
########################################

while True:
    if GPIO.input(25) == 1:
        # LED Ausschalten
        # GPIO.output(26, GPIO.LOW)
        c=1
    else:
#        time.sleep(0.2)
        while(c>0):
            c=0
            ts=time.time()
            sttime = datetime.fromtimestamp(ts,tz=tz).strftime('%Y-%m-%d %H:%M:%S.%f%z')
            filenamedate = datetime.fromtimestamp(ts).strftime('%Y%m%d')
            #print(sttime)
            append_new_line('/var/tmp/'+filenamedate+'-wasserzaehler-ping.csv', sttime+',1')
            subprocess.run("/home/russ/bin/measurements/zaehlerablesung/influx_write_wasserzaehler.sh")
