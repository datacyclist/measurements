#!/usr/bin/python
#import Adafruit_DHT
import Adafruit_BMP.BMP085 as BMP085
#import Adafruit_CharLCD as LCD
import math
import time
import os
from datetime import datetime
from time import gmtime,strftime
#import bme280

##############################
# den BMP085 auslesen
##############################

sensorbmp = BMP085.BMP085()
pressure = format(sensorbmp.read_pressure())
#print 'Pressure = {0:0.2f} Pa'.format(sensorbmp.read_pressure())
#print 'Temp = {0:0.2f} *C'.format(sensorbmp.read_temperature())

tempbmp = str(float(format(sensorbmp.read_temperature()))-0)
#print tempbmp
ftempbmp = open('/var/tmp/bmp085_temperature', 'w')	
ftempbmp.write(tempbmp)
ftempbmp.close()

pressure = sensorbmp.read_pressure()
presshort = str(round(float(pressure)/100,1))
#print presshort

fpressbmp = open('/var/tmp/bmp085_pressure', 'w')	
fpressbmp.write(presshort)
fpressbmp.close()

# humidity = open('/var/tmp/bmp085_humidity', 'w')	
# humidity.write(humishort)
# humidity.close()

