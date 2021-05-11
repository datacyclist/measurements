#!/usr/bin/python
# import Adafruit_DHT
# import Adafruit_BMP.BMP085 as BMP085
import Adafruit_CharLCD as LCD
import math
import os
from datetime import datetime
from time import gmtime,strftime
import time
# import httplib, urllib
# import bme280

# 2020-12-08, mail@georgruss.ch
# alle Messwerte aufs LCD im HWR schreiben

# Warten, weil innerhalb vom Cronjob gestartet und weil Daten aus Files eingelesen werden.
time.sleep(12)

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
#time = strftime("%H:%M")
timedate = strftime("%Y-%m-%d %H:%M")
# print(time)

# count=0                                                                                                                 
# while count < 4:                                                                                                        

# alle Variablen aus Files lesen

# Kesseltemperatur
ftempDS18B20 = open('/var/tmp/ds18b20_temperature','r')                                                                     
tempDS18B20 = ftempDS18B20.read()                                                                                   
ftempDS18B20.close()                                                                                                
#print(tempDS18B20)

# Aussentemperatur
ftempbmp085 = open('/var/tmp/bmp085_temperature','r')                                                                     
tempbmp085 = ftempbmp085.read()                                                                                   
ftempbmp085.close()                                                                                                
#print(tempbmp085)

# HWR-Temperatur
ftempbmp280 = open('/var/tmp/bmp280_temperature','r')                                                                     
tempbmp280 = ftempbmp280.read()                                                                                   
ftempbmp280.close()                                                                                                
#print(tempbmp280)

#line1 = time + "       " + tempshort + chr(223) + "C"
#line1 = timedate + "       " + mintemp + chr(223) + "C"
line1 = "  " + timedate + "  "
line2 = "Aussen: " + str(tempbmp085) + chr(223) + "C"
line3 = "HWR   : " + tempbmp280+chr(223)+"C  "
line4 = "Kessel: " + tempDS18B20+chr(223)+"C"
#line2 = humishort + "%      " + presshort + "hPa"
#line3 = presshort + "hPa" + humishort + "%"
#line3 = presshort + "hPa"
#line3 = " "

# Print a four line message
lcd.message(line1 + "\n" + line2 + "\n" + line3 + "\n" + line4)
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
#    line2 = "Ist: " + tempDS18B20+ chr(223) + "C " + heizstatus                                                         
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
