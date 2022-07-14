#!/usr/bin/python
# -*- coding:utf-8 -*-
import sys
import os
import logging
import epaper
import time
from PIL import Image,ImageDraw,ImageFont
import traceback

logging.basicConfig(level=logging.INFO)

# dimensions: 296x152 px

#print(ac1)
#if os.path.getsize('/var/log/AC_kWh') == 0:
##if len(file1.read()) == 0:
#    AC_kWh="0"
#else:
#    AC_kWh=float(file1.read())
#file1.close()                                                                                                
#print(AC_kWh)

#file1 = open('/var/log/AC_kWh','r')                                                                     
#ac1 = float(file1.read())
#print(file1.read())
#print(len(file1.read()))
#ac1 = file1.read()).strip()
#print(ac1)
#file1 = open('/var/log/AC_kWh','r')                                                                     
#print(file1.read())
#print(len(file1.read()))
#if len(file1.read())==0:
#    AC_kWh="0"
#else:
#AC_kWh=str(round(ac1,2))
#file1.close()                                                                                                

#time.sleep(5)

#try:
    # logging.info("epd2in66 Demo")
    
    # epd = epd2in66.EPD()
epd = epaper.epaper('epd2in66').EPD()
#logging.info("init and Clear")
epd.init(0) # =full refresh
epd.Clear()
# logging.info(epd.height)
# logging.info(epd.width)

font24 = ImageFont.truetype("/usr/share/fonts/truetype/msttcorefonts/verdana.ttf", 24)
font18 = ImageFont.truetype("/usr/share/fonts/truetype/msttcorefonts/verdana.ttf", 18)
font14 = ImageFont.truetype("/usr/share/fonts/truetype/msttcorefonts/verdana.ttf", 14)

# Drawing vertically
#logging.info("4.Drawing on the Vertical image...")
# draw = ImageDraw.Draw(Limage)
# draw.text((2, 0), 'hello world', font = font18, fill = 0)
# draw.text((2, 20), '2.66inch epd', font = font18, fill = 0)
# draw.text((10, 40), u'微雪电子', font = font24, fill = 0)
# draw.line((10, 90, 60, 140), fill = 0)
# draw.line((60, 90, 10, 140), fill = 0)
# draw.rectangle((10, 90, 60, 140), outline = 0)
# draw.line((95, 90, 95, 140), fill = 0)
# draw.line((70, 115, 120, 115), fill = 0)
# draw.arc((70, 90, 120, 140), 0, 360, fill = 0)
# draw.rectangle((10, 150, 60, 200), fill = 0)
# draw.chord((70, 150, 120, 200), 0, 360, fill = 0)
# epd.display(epd.getbuffer(Limage))

Himage = Image.new('1', (epd.height, epd.width), 0xFF)  # 0xFF: clear the frame
draw = ImageDraw.Draw(Himage)
draw.text((10, 0), 'System Startup, waiting... ', font = font18, fill = 0)
epd.display(epd.getbuffer(Himage))

# wait after machine startup
time.sleep(15)

epd.init(0) # =full refresh
epd.Clear()

Limage = Image.new('1', (epd.width, epd.height), 0xFF)  # 0xFF: clear the frame
# partial update, mode 1
epd.init(1) # = partial refresh mode
epd.Clear()
time_draw = ImageDraw.Draw(Limage)
num = 0

while (True):

    # get data
    timedate = time.strftime("%d.%m.%Y %H:%M:%S")

    # Raumtemperatur Buero (lokaler Sensor)

    if os.path.getsize('/var/log/bmp180_temperature') <= 1:
        tempbuero="NA"
    else:
        file1 = open('/var/log/bmp180_temperature','r')
        tempbuero=str(round(float(file1.read()),1))
        file1.close()                                                                                                

    #ftempbuero = open('/var/log/am2302_temperature','r')                                                                     
    #tempbuero = str(round(float(ftempbuero.read()),1))

    # Luftdruck (lokaler Sensor)
    if os.path.getsize('/var/log/bmp180_airpressure') == 1:
        airpressure="NA"
    else:
        file1 = open('/var/log/bmp180_airpressure','r')
        airpressure=str(file1.read()).strip()
        file1.close()                                                                                                
        
    # Aussentemperatur (kommt aus influx-query)
    file1 = open('/var/log/aussentemperatur','r')                                                                     
    aussentemperatur = str(round(float(file1.read()),1))
    file1.close()                                                                                                
    
    # Verbrauch A/C (aus influx-query)
    
    if os.path.getsize('/var/log/AC_kWh') == 1:
        AC_kWh="NA"
    else:
        file1 = open('/var/log/AC_kWh','r')
        AC_kWh=str(round(float(file1.read()),2))
        file1.close()                                                                                                

    # Netzbezug Wh (aus influx)
    print("os.path.getsize('/var/log/netzbezug_Wh'")
    print(os.path.getsize('/var/log/netzbezug_Wh'))
    print("os.path.getsize('/var/log/solar_kWh'")
    print(os.path.getsize('/var/log/solar_kWh'))

    #if os.path.getsize('/var/log/netzbezug_Wh') <= 1:
    #    netzbezug_Wh="NA"
    #else:
    file1 = open('/var/log/netzbezug_Wh','r')                                                                     
    #   netzbezug_Wh = str(round(float(file1.read())/1000,2))
    netzbezug_Wh = file1.read().strip()
    file1.close()                                                                                                

    # Solar-Leistung aktuell (aus influx)
    if os.path.getsize('/var/log/solar_W') <= 1:
        solar_W="NA"
    else:
        file1 = open('/var/log/solar_W','r')
        solar_W = file1.read().strip()
        file1.close()                                                                                                

    # PC-Leistung aktuell (aus influx)
    if os.path.getsize('/var/log/PC_W') <= 1:
        PC_W="NA"
    else:
        file1 = open('/var/log/PC_W','r')
        PC_W= file1.read().strip()
        file1.close()                                                                                                

    # Solar-Erzeugung heute (aus influx)
    if os.path.getsize('/var/log/solar_kWh') <= 1:
        solar_kWh="NA"
    else:
        file1 = open('/var/log/solar_kWh','r')                                                                     
        solar_kWh = str(float(file1.read()))
        file1.close()                                                                                                
    
    # this triggers partial update for the whole specified area (=the whole display here)
    time_draw.rectangle((0, 0, 152, 296), fill = 255)
    #time_draw.text((0, 10), time.strftime('%H:%M:%S'), font = font24, fill = 0)
    time_draw.text((0, 00), timedate, font = font14, fill = 0)
    time_draw.line((0, 22, 152, 22), fill = 0)
    time_draw.text((0, 22), "aktuell", font = font14, fill = 0)
    time_draw.line((0, 37, 152, 37), fill = 0)
    time_draw.text((0, 40), tempbuero+"°C Büro", font = font18, fill = 0)
    time_draw.text((0, 60), airpressure+"bar", font = font18, fill = 0)
    time_draw.text((0, 80), aussentemperatur+"°C aussen", font = font18, fill = 0)
    time_draw.text((0, 100), solar_W+" W Solar", font = font18, fill = 0)
    time_draw.text((0, 120), PC_W+" W PC/Büro", font = font18, fill = 0)
    time_draw.line((0, 145, 152, 145), fill = 0)
    time_draw.text((0, 145), "Mengen heute", font=font14, fill = 0)
    time_draw.line((0, 160, 152, 160), fill = 0)
    time_draw.text((0, 165), AC_kWh+" kWh A/C", font = font18, fill = 0)
    time_draw.text((0, 185), solar_kWh+" kWh Solar", font = font18, fill = 0)
    time_draw.text((0, 205), netzbezug_Wh+" Wh Netz", font = font18, fill = 0)
    epd.display(epd.getbuffer(Limage))
        
        #num = num + 1
        #if(num == 5):
        #    break
    # font installation might be necessary with "apt install ttf-mscorefonts-installer"
    #font24 = ImageFont.truetype("arial.ttf", 24)
    # font18 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 18)
    #font18 = ImageFont.truetype("Helvetica", 18)
    #font18 = ImageFont.load_default()
    
    # Drawing on the Horizontal image
    # logging.info("1.Drawing on the Horizontal image...")
    # Himage = Image.new('1', (epd.height, epd.width), 0xFF)  # 0xFF: clear the frame
    # draw = ImageDraw.Draw(Himage)
    # draw.text((10, 0), 'Mein Messwerte-Bilderrahmen mit E-Ink-Display :-) ', font = font18, fill = 0)
    # # draw.text((10, 0), 'hello world', fill = 0)
    # draw.text((10, 20), '2.66inch e-Paper', font = font24, fill = 0)
    # draw.text((10, 100), u'微雪电子', font = font24, fill = 0)
    # draw.line((20, 50, 70, 100), fill = 0)
    # draw.line((70, 50, 20, 100), fill = 0)
    # draw.rectangle((20, 50, 70, 100), outline = 0)
    # draw.line((165, 50, 165, 100), fill = 0)
    # draw.line((140, 75, 190, 75), fill = 0)
    # draw.arc((140, 50, 190, 100), 0, 360, fill = 0)
    # draw.rectangle((80, 50, 130, 100), fill = 0)
    # draw.chord((200, 50, 250, 100), 0, 360, fill = 0)
    # epd.display(epd.getbuffer(Himage))
    # time.sleep(5)
    
    # logging.info("2.read bmp file")
    # Himage = Image.open(os.path.join(picdir, '2.66inch-9.bmp'))
    # epd.display(epd.getbuffer(Himage))
    # time.sleep(5)
    # 
    # logging.info("3.read bmp file on window")
    # Himage2 = Image.new('1', (epd.height, epd.width), 255)  # 255: clear the frame
    # bmp = Image.open(os.path.join(picdir, '100x100.bmp'))
    # Himage2.paste(bmp, (50,20))
    # epd.display(epd.getbuffer(Himage2))
    # time.sleep(5)
    
            
    # logging.info("Clear...")
    # epd.init(0)
    # epd.Clear()
    # 
    # logging.info("Goto Sleep...")
    # epd.sleep()
