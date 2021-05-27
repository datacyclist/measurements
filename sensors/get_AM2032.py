#!/usr/bin/python
import Adafruit_DHT
import Adafruit_BMP.BMP085 as BMP085
import Adafruit_CharLCD as LCD
import math
import time
import os
from datetime import datetime
from time import gmtime,strftime
import httplib, urllib
import bme280

##############################
# erstmal den einen Sensor auslesen
##############################

sensor=Adafruit_DHT.DHT22
pin=7
humidity, temperature = Adafruit_DHT.read_retry(sensor, pin)
# print humidity
# print temperature

humishort = str(round(float(humidity),1))
tempshort = str(round(float(temperature),1))


##############################
# dann den anderen Sensor
##############################

sensorbmp = BMP085.BMP085()
# pressure = format(sensorbmp.read_pressure())
# print 'Pressure = {0:0.2f} Pa'.format(sensorbmp.read_pressure())
# print 'Temp = {0:0.2f} *C'.format(sensorbmp.read_temperature())

tempbmp = str(float(format(sensorbmp.read_temperature()))-0)
# print tempbmp

pressure = sensorbmp.read_pressure()
presshort = str(round(float(pressure)/100,1))
# print presshort

############################
# dann den BMP280
############################

# (chip_id, chip_version) = bme280.readBME280ID()
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
# Innentemperatur vom Raspberry Pi nehmen
##############################
# temprasp = int(float(os.system("cat /sys/class/thermal/thermal_zone0/temp")))+500
# temprasp = str(float(os.system("cat /sys/class/thermal/thermal_zone0/temp")/1000))
# print temprasp+1
temprasp = str(round(float(open("/sys/class/thermal/thermal_zone0/temp").read())/100)/10)
# temprasp = temprasp/10
# print temprasp


##############################
# minimale Temperatur bestimmen
##############################

mintemp = str(min(float(format(sensorbmp.read_temperature()))-0,round(float(temperature),1)))
#print mintemp

##############################
# alles in Files ablegen
##############################

temperature = open('/var/tmp/temperature', 'w')	
temperature.write(tempshort)
temperature.close()

ftempbmp = open('/var/tmp/tempbmp', 'w')	
ftempbmp.write(tempbmp)
ftempbmp.close()

fmintemp = open('/var/tmp/mintemp', 'w')	
fmintemp.write(mintemp)
fmintemp.close()

humidity = open('/var/tmp/humidity', 'w')	
humidity.write(humishort)
humidity.close()

humidity = open('/var/tmp/bmp280humidity', 'w')	
humidity.write(str(bmp280humidityshort))
humidity.close()

pressure = open('/var/tmp/pressure', 'w')	
pressure.write(presshort)
pressure.close()

pressure = open('/var/tmp/bmp280pressure', 'w')	
pressure.write(str(bmp280pressureshort))
pressure.close()

ftempbmp = open('/var/tmp/bmp280temperature', 'w')	
ftempbmp.write(str(bmp280temperature))
ftempbmp.close()

##############################
# LCD konfigurieren
# https://learn.adafruit.com/character-lcd-with-raspberry-pi-or-beaglebone-black/usage
##############################
# Raspberry Pi pin configuration:
lcd_rs        = 27  # Note this might need to be changed to 21 for older revision Pi's.
lcd_en        = 22
lcd_d4        = 25
lcd_d5        = 24
lcd_d6        = 23
lcd_d7        = 18
lcd_backlight = 4

# Define LCD column and row size for 16x2 LCD.
lcd_columns = 20
lcd_rows    = 4

# Initialize the LCD using the pins above.
lcd = LCD.Adafruit_CharLCD(lcd_rs, lcd_en, lcd_d4, lcd_d5, lcd_d6, lcd_d7, 
                           lcd_columns, lcd_rows, lcd_backlight)

##############################
# Daten aufs LCD schreiben
##############################

#time = strftime("%d.%m. %H:%M")
time = strftime("%H:%M")
timedate = strftime("%Y-%m-%d %H:%M")
# print(time)

#line1 = time + "       " + tempshort + chr(223) + "C"
#line1 = timedate + "       " + mintemp + chr(223) + "C"
line1 = "  " + timedate + "  "
line2 = "Innen: " + str(round(bmp280temperature*10)/10) + chr(223) + "C"
line3 = "N: " + tempbmp+chr(223)+"C  " + presshort+"hPa"
line4 = "S: " + tempshort+chr(223)+"C"
#line2 = humishort + "%      " + presshort + "hPa"
#line3 = presshort + "hPa" + humishort + "%"
#line3 = presshort + "hPa"
#line3 = " "

# Print a four line message
lcd.message(line1 + "\n" + line2 + "\n" + line3 + "\n" + line4)

##############################
# Daten nach thingspeak loggen
##############################

params = urllib.urlencode({
			'field1': float(mintemp), 
			'field2': float(tempbmp), 
			'field3': float(tempshort), 
			'field4': humishort, 
			'field5':presshort, 
			'field6':bmp280temperature, 
			'field7':bmp280humidityshort, 
			'field8':bmp280pressureshort, 
			'key':'2RQSI3CAKS7HLSEL'
})
headers = {"Content-type": "application/x-www-form-urlencoded","Accept":  "text/plain"}
conn = httplib.HTTPConnection("api.thingspeak.com:80")
conn.request("POST", "/update", params, headers)
response = conn.getresponse()
# print response.status, response.reason
# 200 OK
data = response.read()
conn.close()
