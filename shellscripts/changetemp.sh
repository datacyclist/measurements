#!/bin/bash

# Script zum Steuern der FHEM/MAX-Thermostate
# 2020-01-16
# mail@georgruss.ch

# läuft ganz simpel via telnet
# telnet muss im FHEM erst aktiviert werden: 
# define telnetPort telnet 7072

# Benutzung:
# changetemp.sh buero 16 
# (setzt die Temperatur im Büro auf 16°C)

HOST='127.0.0.1'
PORT='7072'

#USER='User'
#PASSWD='Pass'
#CMD='set MAX_008bb8 desiredTemperature 18'

##############################
# Thermostat Wohnzimmer MAX_008cd0
##############################

if [ "$1" == "wohnzimmer" ]; then
 (
 echo open "$HOST $PORT"
 sleep 1
 echo "$CMD"
 echo "set MAX_008cd0 desiredTemperature $2"
 sleep 1
 echo "exit"
 ) | telnet

fi

##############################
# Thermostat Küche MAX_0090bf
##############################

if [ "$1" == "kueche" ]; then
 (
 echo open "$HOST $PORT"
 sleep 1
 echo "$CMD"
 echo "set MAX_0090bf desiredTemperature $2"
 sleep 1
 echo "exit"
 ) | telnet

fi

##############################
# Thermostat Bad MAX_00a661
##############################

if [ "$1" == "bad" ]; then
 (
 echo open "$HOST $PORT"
 sleep 1
 echo "$CMD"
 echo "set MAX_00a661 desiredTemperature $2"
 sleep 1
 echo "exit"
 ) | telnet

fi

##############################
# Thermostat Büro MAX_008bb8
##############################

if [ "$1" == "buero" ]; then
 (
 echo open "$HOST $PORT"
 sleep 1
 echo "$CMD"
 echo "set MAX_008bb8 desiredTemperature $2"
 sleep 1
 echo "exit"
 ) | telnet

fi

##############################
# Alle Heizkörper steuern mit Profilen
#
# Argument $2:
#
# ferien: Ferienmodus (alles aus auf Frostschutz)
# normal: normal (allein, ohne Gast, kühleres Bad)
# gast: Gast (wärmeres Bad, Küche, Gästezimmer)
#
##############################

if [ "$1" == "modus" ]; then
 (
 echo open "$HOST $PORT"
 sleep 1
 echo "$CMD"
 echo "set normal restore_topic $2"
 sleep 1
 echo "exit"
 ) | telnet

fi
