#!/usr/bin/python
# coding=utf-8
# messprogramm.py
#----------------

import os, sys, time


def aktuelleTemperatur():
      
    # 1-wire Slave Datei lesen
    file = open('/sys/bus/w1/devices/28-0416c0c943ff/w1_slave')
    filecontent = file.read()
    file.close()

    # Temperaturwerte auslesen und konvertieren
    stringvalue = filecontent.split("\n")[1].split(" ")[9]
    temperature = float(stringvalue[2:]) / 1000

    # Temperatur ausgeben
    rueckgabewert = '%5.2f' % temperature 
    #rueckgabewert = '0:0.2f' % temperature 
    return(rueckgabewert)


messdaten = aktuelleTemperatur()
ds18b20temp = open('/var/tmp/ds18b20_temperature', 'w')
ds18b20temp.write(aktuelleTemperatur())
ds18b20temp.close()

# schleifenZaehler = 0
# schleifenAnzahl = 4
# schleifenPause = 8
# 
# 
# print "Temperaturabfrage für ", schleifenAnzahl, " Messungen alle ", schleifenPause ," Sekunden gestartet"

# while schleifenZaehler <= schleifenAnzahl:

#     messdaten = aktuelleTemperatur()
#     #print "Aktuelle Temperatur : ", messdaten, "°C",
#     #"in der ", schleifenZaehler, ". Messabfrage"
#     #time.sleep(schleifenPause)
#     #schleifenZaehler = schleifenZaehler + 1
#     ds18b20temp = open('/var/tmp/tempDS18B20', 'w')
#     ds18b20temp.write(aktuelleTemperatur())
#     ds18b20temp.close()
    

#print "Temperaturabfrage beendet"
