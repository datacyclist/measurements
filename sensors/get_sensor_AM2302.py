#!/usr/bin/python

# this is an endless loop to write the sensor readings to a file in /var/log (on tmpfs)

# it will be started in a service file am2302.service for systemctl

import sys
import Adafruit_DHT
#import Adafruit_BMP.BMP085 as BMP085
import math
import time
import os
from datetime import datetime
from time import gmtime,strftime

while True:
    humidity, temperature = Adafruit_DHT.read_retry(Adafruit_DHT.AM2302, 18)

    if humidity is not None and temperature is not None and float(humidity)<105 :
        humishort = str(round(float(humidity),1))
        tempshort = str(round(float(temperature),1))
        ftempbmp = open('/var/log/am2302_temperature', 'w')	
        ftempbmp.write(tempshort)
        ftempbmp.close()
        ftempbmp = open('/var/log/am2302_humidity', 'w')	
        ftempbmp.write(humishort)
        ftempbmp.close()
        time.sleep(10)
    else:
        time.sleep(10)
