#!/usr/bin/python
import math
import time
import os
from datetime import datetime
from time import gmtime,strftime
import httplib, urllib
import bme280

############################
# den BMP280 auslesen, Innenraum, direkt am RBPI
############################

(chip_id, chip_version) = bme280.readBME280ID()
# print "Chip ID :", chip_id
# print "Version :", chip_version

bmp280temperature,bmp280pressure,bmp280humidity = bme280.readBME280All()

bmp280pressureshort = str(round(float(bmp280pressure),1))
bmp280humidityshort = str(round(float(bmp280humidity),1))

# print "Temperature : ", bmp280temperature, "C"
# print "Pressure : ", bmp280pressure, "hPa"
# print "Pressure short : ", bmp280pressureshort, "hPa"
# print "Humidity : ", bmp280humidity, "%"
# print "Humidity short : ", bmp280humidityshort, "%"

##############################
# alles in Files ablegen
##############################

ftempbmp = open('/var/tmp/bmp280_temperature', 'w')	
ftempbmp.write(str(bmp280temperature))
ftempbmp.close()

fpressbmp = open('/var/tmp/bmp280_pressure', 'w')	
fpressbmp.write(str(bmp280pressureshort))
fpressbmp.close()

fhumbmp = open('/var/tmp/bmp280_humidity', 'w')	
fhumbmp.write(str(bmp280humidityshort))
fhumbmp.close()
