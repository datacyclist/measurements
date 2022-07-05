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

sleep(5) # wait 5s after machine startup

while True:
    # get data
    timedate = strftime("%Y-%m-%d %H:%M")
    #print(timedate)
    
    # Raumtemperatur Buero

    if os.path.getsize('/var/log/am2302_temperature') == 1:
        tempbuero="NA"
    else:
        file1 = open('/var/log/am2302_temperature','r')
        tempbuero=str(round(float(file1.read()),1))
        file1.close()                                                                                                

    #ftempbuero = open('/var/log/am2302_temperature','r')                                                                     
    #tempbuero = str(round(float(ftempbuero.read()),1))

    # Luftfeuchte Buero
    if os.path.getsize('/var/log/am2302_humidity') == 1:
        tempbuero="NA"
    else:
        file1 = open('/var/log/am2302_humidity','r')
        feuchtebuero=str(round(float(file1.read()),1))
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
    line1 = tempbuero + chr(223) + "C " + feuchtebuero + "%"
    line2 = timedate
    
    #print(line1)
    #lcd.write_string(energienetz "Wh ")
    lcd.write_string(line1)
    lcd.crlf()
    lcd.write_string(line2)
    lcd.crlf()
    #lcd.write_string(line3)
    #lcd.crlf()
    #lcd.write_string(line4)
    #lcd.crlf()
    #sleep(2)
    # Switch off backlight
    #lcd.backlight_enabled = True
    # Clear the LCD screen
    lcd.close(clear=False)
    
    sleep(2)
