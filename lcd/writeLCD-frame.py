# write data to HD44780 LCD connected via i2c to raspberry pi

# endless loop, it is started in a systemctl service file

# Import LCD library
from RPLCD import i2c

import os

# Import sleep library
from time import sleep,gmtime,strftime
#import datetime
#import strftime

# constants to initialise the LCD
lcdmode = 'i2c'
cols = 16
rows = 4
charmap = 'A02'
i2c_expander = 'PCF8574'

# Generally 27 is the address;Find yours using: i2cdetect -y 1 
address = 0x27 
port = 1 # 0 on an older Raspberry Pi

# Initialise the LCD
lcd = i2c.CharLCD(i2c_expander, address, port=port, charmap=charmap,
                          cols=cols, rows=rows)

# # Write a string on first line and move to next line
# lcd.write_string('42')
# lcd.crlf()
# lcd.write_string('this works')
# lcd.crlf()
# lcd.write_string('')
# sleep(5)
# # Switch off backlight
# lcd.backlight_enabled = True
# # Clear the LCD screen
# lcd.close(clear=True)
#ip = str(os.system("ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'"))
#print(ip)
lcd.write_string('machine start...')
lcd.crlf()
lcd.write_string('----------------')
#lcd.crlf()

sleep(5) # wait 5s after machine startup
lcd.close(clear=True)

while True:
    # get data
    timedate = strftime("%Y-%m-%d %H:%M")
    #print(timedate)

    # occupancy

    if os.path.getsize('/var/log/occupancystring') <= 1:
        occupancystring="NA"
    else:
        file1 = open('/var/log/occupancystring','r')
        occupancystring=str(file1.read()).strip()
        file1.close()                                                                                                

    #occupancystring = occupancystring.strip()
    
    # Raumtemperatur Buero

    if os.path.getsize('/var/log/bmp180_temperature') <= 1:
        tempbuero="NA"
    else:
        file1 = open('/var/log/bmp180_temperature','r')
        tempbuero=str(round(float(file1.read()),1))
        file1.close()                                                                                                

    #ftempbuero = open('/var/log/am2302_temperature','r')                                                                     
    #tempbuero = str(round(float(ftempbuero.read()),1))

    # Luftdruck
    if os.path.getsize('/var/log/bmp180_airpressure') == 1:
        airpressure="NA"
    else:
        file1 = open('/var/log/bmp180_airpressure','r')
        airpressure=str(file1.read()).strip()
        file1.close()                                                                                                
    #ffeuchtebuero = open('/var/log/am2302_humidity','r')                                                                     
    #feuchtebuero = str(round(float(ffeuchtebuero.read()),1))
    #ffeuchtebuero.close()                                                                                                
     
    # Netzbezug Strom
    # fenergienetz = open('/var/tmp/netzbezug_Wh','r')                                                                    
    # energienetz = str(int(fenergienetz.read()))
    # fenergienetz.close()                                                                                                
    # 
    # # Wasserverbrauch
    # fwasserbezug = open('/var/tmp/wasser_l','r')                                                                     
    # wasserbezug = str(int(round(float(fwasserbezug.read()),0)))
    # fwasserbezug.close()                                                                                                
    # 
    # # Solarleistung
    # fsolarleistung = open('/var/tmp/solar_W','r')                                                                     
    # solarleistung = str(int(fsolarleistung.read()))
    # fsolarleistung.close()                                                                                                
    #print(solarleistung)
    
    # Write a string on first line and move to next line
    # line1 = "E_netz: " + energienetz + " Wh"
    # line2 = "P_solar: " + str(solarleistung) + " W"
    # line3 = "Wasser: " + wasserbezug + " Liter"
    #line4 = "HWR: " + tempHWR + chr(223) + "C " + feuchteHWR + "%"
    line1 = tempbuero + chr(223) + "C " + airpressure + "bar"
    line2 = occupancystring
    #line2 = "testtteehosan,.t"
    
    #print(line1)
    #lcd.write_string(energienetz "Wh ")
    lcd.write_string(line1)
    lcd.crlf()
    lcd.write_string(line2)
    lcd.crlf()
    #sleep(2)
    # Switch off backlight
    #lcd.backlight_enabled = True
    # Clear the LCD screen
    lcd.close(clear=False)
    
    sleep(2)
