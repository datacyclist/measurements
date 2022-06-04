# Import LCD library
from RPLCD import i2c

import math
import os
from datetime import datetime
from time import gmtime,strftime,sleep
import time

# constants to initialise the LCD
lcdmode = 'i2c'
cols = 20
rows = 4
charmap = 'A02'
i2c_expander = 'PCF8574'

# Generally 27 is the address;Find yours using: i2cdetect -y 1 
address = 0x27 
port = 1 # 0 on an older Raspberry Pi

# Initialise the LCD
lcd = i2c.CharLCD(i2c_expander, address, port=port, charmap=charmap,
                          cols=cols, rows=rows)

lcd.backlight_enabled = True

# get data
timedate = strftime("%Y-%m-%d %H:%M")
#print(timedate)

# Temperatur HWR
ftempHWR = open('/var/tmp/bmp280_temperature','r')                                                                     
tempHWR = str(round(float(ftempHWR.read()),1))
ftempHWR.close()                                                                                                
# Luftfeuchte HWR
ffeuchteHWR = open('/var/tmp/bmp280_humidity','r')                                                                     
feuchteHWR = str(round(float(ffeuchteHWR.read()),1))
ffeuchteHWR.close()                                                                                                
# # print(tempKessel)
# 
# # Vorlauftemperatur
# ftempVorlauf = open('/var/tmp/vorlauftemp','r')                                                                     
# tempVorlauf = str(round(float(ftempVorlauf.read()),1))
# ftempVorlauf.close()                                                                                                
# # print(tempVorlauf)
# 
# # Abgastemperatur
# ftempAbgas = open('/var/tmp/abgastemp','r')                                                                     
# tempAbgas = str(round(float(ftempAbgas.read()),1))
# ftempAbgas.close()                                                                                           
# # print(tempAbgas)
 
# Netzbezug Strom
fenergienetz = open('/var/tmp/netzbezug_Wh','r')                                                                    
energienetz = str(int(fenergienetz.read()))
fenergienetz.close()                                                                                                

# Wasserverbrauch
fwasserbezug = open('/var/tmp/wasser_l','r')                                                                     
wasserbezug = str(int(round(float(fwasserbezug.read()),0)))
fwasserbezug.close()                                                                                                

# Solarleistung
fsolarleistung = open('/var/tmp/solar_W','r')                                                                     
solarleistung = str(int(fsolarleistung.read()))
fsolarleistung.close()                                                                                                
#print(solarleistung)

# Write a string on first line and move to next line
line1 = "E_netz: " + energienetz + " Wh"
line2 = "P_solar: " + str(solarleistung) + " W"
line3 = "Wasser: " + wasserbezug + " Liter"
#line4 = "HWR: " + tempHWR + chr(223) + "C " + feuchteHWR + "%"
line4 = "HWR: " + tempHWR + unichr(223) + "C " + feuchteHWR + "%"
#print(line1)
#lcd.write_string(energienetz "Wh ")
lcd.write_string(line1)
lcd.crlf()
lcd.write_string(line2)
lcd.crlf()
lcd.write_string(line3)
lcd.crlf()
lcd.write_string(line4)
lcd.crlf()
sleep(2)
# Switch off backlight
lcd.backlight_enabled = True
# Clear the LCD screen
lcd.close(clear=False)
#!/usr/bin/python
# import Adafruit_DHT
# import Adafruit_BMP.BMP085 as BMP085
# import httplib, urllib
# import bme280


# count=0                                                                                                                 
# while count < 4:                                                                                                        

# alle Variablen aus Files lesen


# HWR-Temperatur
# ftempbmp280 = open('/var/tmp/bmp280_temperature','r')                                                                     
# tempbmp280 = str(round(float(ftempbmp280.read()),1))
# ftempbmp280.close()                                                                                                
# print(tempbmp280)

#line1 = time + "       " + tempshort + chr(223) + "C"
#line1 = timedate + "       " + mintemp + chr(223) + "C"
#line1 = "  " + timedate + "  "
#line1 = "     Abgas: " + tempAbgas + chr(223)+"C"
#line2 = "   Vorlauf: " + tempVorlauf + chr(223)+"C"
#line3 = "Warmwasser: " + tempWW + chr(223)+"C"
#line4 = "Innen/HWR : " + tempbmp280 + chr(223)+"C  "
#line2 = humishort + "%      " + presshort + "hPa"
#line3 = presshort + "hPa" + humishort + "%"
#line3 = presshort + "hPa"
#line3 = " "

#print(line3)

# Print a four line message
#lcd.message(line3)
#lcd.message(line1 + "\n" + line2 + "\n" + line3 + "\n" + line4)
#  time.sleep(12)
#  count +=1

#    fsollwertsolo = open('/var/tmp/sollwertsolo','r')                                                                   
#    s = fsollwertsolo.read()                                                                                            
#    sollwertsolo = s.rstrip()                                                                                           
#    fsollwertsolo.close()                                                                                               
#
#    fbelegung = open('/var/tmp/belegung','r')                                                                           
#    s = fbelegung.read()                                                                                                
#    belegung = s.rstrip()                                                                                               
#    fbelegung.close()                                                                                                   
#
#    fheizstatus = open('/var/tmp/heizstatus','r')                                                                       
#    h = fheizstatus.read()                                                                                              
#    heizstatus = h.rstrip()                                                                                             
#    fheizstatus.close()                                                                                                 

#    uhrzeit = strftime("%H:%M")                                                                                         
#    line1 = "Soll " + sollwert + "/" + sollwertsolo + " " + belegung                                                    
#    line2 = "Ist: " + tempKessel+ chr(223) + "C " + heizstatus                                                         
#    lcd.message(line1 + "\n" + line2)                                                                                   
#    time.sleep(12)                                                                                                      
#    count +=1   


##############################
# Daten nach thingspeak loggen
##############################

# params = urllib.urlencode({
# 			'field1': float(mintemp), 
# 			'field2': float(tempbmp), 
# 			'field3': float(tempshort), 
# 			'field4': humishort, 
# 			'field5':presshort, 
# 			'field6':bmp280temperature, 
# 			'field7':bmp280humidityshort, 
# 			'field8':bmp280pressureshort, 
# 			'key':'2RQSI3CAKS7HLSEL'
# })
# headers = {"Content-type": "application/x-www-form-urlencoded","Accept":  "text/plain"}
# conn = httplib.HTTPConnection("api.thingspeak.com:80")
# conn.request("POST", "/update", params, headers)
# response = conn.getresponse()
# # print response.status, response.reason
# # 200 OK
# data = response.read()
# conn.close()
