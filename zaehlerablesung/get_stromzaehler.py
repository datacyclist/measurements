#!/usr/bin/python
# -*- coding: utf-8 -*-
import math
import time
import os
#import datetime
#import dateutil
from datetime import datetime,date
from time import gmtime,strftime
import httplib, urllib
import pytz
# import bme280

# dieses Script wird in einem systemd-service gestartet

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

############################
# 
############################

import RPi.GPIO as GPIO

# GPIO ueber Nummern ansprechen
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

# Pin fuer Taster als Input-Pin setzen
GPIO.setup(13, GPIO.IN)
# Pin fuer Fototransistor als Input-Pin setzen
GPIO.setup(18, GPIO.IN)
# Pin fuer LED als Output-Pin setzen
GPIO.setup(26, GPIO.OUT)

#dtobj = datetime.now(tzinfo=utc)
#print(dtobj)

##############################
# fünfmal Blinken der LED beim Start
##############################

for i in range(5):
   GPIO.output(26, GPIO.HIGH)
   time.sleep(0.2)
   GPIO.output(26, GPIO.LOW)
   time.sleep(0.1)

# Taster testen
# input_13=GPIO.input(13)
# print input_13

tz = pytz.timezone('Europe/Zurich')

while True:
    if GPIO.input(18) == 1:
        # LED Ausschalten
        GPIO.output(26, GPIO.LOW)
        c=1
    else:
        # LED Einschalten
        GPIO.output(26, GPIO.HIGH)
#        time.sleep(0.2)
        while(c>0):
            c=0
            ts=time.time()
            sttime = datetime.fromtimestamp(ts,tz=tz).strftime('%Y-%m-%d %H:%M:%S.%f%z')
            filenamedate = datetime.fromtimestamp(ts).strftime('%Y%m%d')
            print(sttime)
            append_new_line('/var/tmp/'+filenamedate+'-stromzaehler-ping.csv', sttime+',1')

        #log='/var/tmp/test.txt'
        #with open(log, 'a') as logfile:
        #    logfile.write("\n")
        #    logfile.write(sttime + ' 1')

# (chip_id, chip_version) = bme280.readBME280ID(      )
# print "Chip ID :", chip_id
# print "Version :", chip_version

# bmp280temperature,bmp280pressure,bmp280humidity = bme280.readBME280All()

#bmp280pressureshort = str(round(float(bmp280pressure),1))
#bmp280humidityshort = str(round(float(bmp280humidity),1))

# print "Temperature : ", bmp280temperature, "C"
# print "Pressure : ", bmp280pressure, "hPa"
# print "Pressure short : ", bmp280pressureshort, "hPa"
# print "Humidity : ", bmp280humidity, "%"
# print "Humidity short : ", bmp280humidityshort, "%"

##############################
# alles in Files ablegen
##############################

#ftempbmp = open('/var/tmp/bmp280_temperature', 'w')	
#ftempbmp.write(str(bmp280temperature))
#ftempbmp.close()
#
#fpressbmp = open('/var/tmp/bmp280_pressure', 'w')	
#fpressbmp.write(str(bmp280pressureshort))
#fpressbmp.close()
#
#fhumbmp = open('/var/tmp/bmp280_humidity', 'w')	
#fhumbmp.write(str(bmp280humidityshort))
#fhumbmp.close()
