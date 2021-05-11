#!/usr/bin/python
import math
import os
from datetime import datetime
#from time import gmtime,strftime
import time
import httplib, urllib

# Warten, weil innerhalb vom Cronjob gestartet und weil Daten aus Files eingelesen werden.
time.sleep(15)

# alle Variablen aus Files lesen

# Kesseltemperatur
ftempDS18B20 = open('/var/tmp/ds18b20_temperature','r')                                                                     
ds18b20_temperature = ftempDS18B20.read()                                                                                   
ftempDS18B20.close()                                                                                                
#print(tempDS18B20)

# Aussentemperatur
ftempbmp085 = open('/var/tmp/bmp085_temperature','r')                                                                     
bmp085_temperature = ftempbmp085.read()                                                                                   
ftempbmp085.close()                                                                                                
#print(tempbmp085)

# Luftdruck
fpressbmp085 = open('/var/tmp/bmp085_pressure','r')                                                                     
bmp085_pressure = fpressbmp085.read()                                                                                   
fpressbmp085.close()                                                                                                
#print(bmp085_pressure)

# HWR-Temperatur
ftempbmp280 = open('/var/tmp/bmp280_temperature','r')                                                                     
bmp280_temperature = ftempbmp280.read()                                                                                   
ftempbmp280.close()                                                                                                
#print(tempbmp280)

##############################
# Daten nach thingspeak loggen
##############################

params = urllib.urlencode({
			'field1': float(bmp085_temperature), 
			'field2': float(ds18b20_temperature), 
			'field3': float(bmp280_temperature), 
			'field4': float(bmp085_pressure), 
			'key':'2RQSI3CAKS7HLSEL'
})


# 'field5':presshort, 
# 'field6': float(tempshort), 
# 'field7':bmp280humidityshort, 
# 'field8':bmp280pressureshort, 

headers = {"Content-type": "application/x-www-form-urlencoded","Accept":  "text/plain"}
conn = httplib.HTTPConnection("api.thingspeak.com:80")
conn.request("POST", "/update", params, headers)
response = conn.getresponse()
# print response.status, response.reason
# 200 OK
data = response.read()
conn.close()

