#!/usr/bin/python

import sys
import Adafruit_DHT
#import Adafruit_BMP.BMP085 as BMP085
import math
import time
import os
from datetime import datetime
from time import gmtime,strftime

humidity, temperature = Adafruit_DHT.read_retry(Adafruit_DHT.AM2302, 15)

if humidity is not None and temperature is not None and float(humidity)<105 :
    #print(temperature)
    humishort = str(round(float(humidity),1))
    tempshort = str(round(float(temperature),1))
    print('humidity_estrich value=' + humishort)
    print('temperature_estrich value=' + tempshort)
    #print('Temp={0:0.1f}*  Humidity={1:0.1f}%'.format(temperature, humidity))
else:
    sys.exit(1)
