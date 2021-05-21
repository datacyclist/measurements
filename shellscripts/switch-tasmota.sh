#!/bin/bash

# Schalten der Tasmota-Switches (Sonoff-Hardware)

# anschalten
# curl -X GET http://192.168.0.145/relay?state=1
# ausschalten
# curl -X GET http://192.168.0.145/relay?state=0
# toggle
# curl -X GET http://192.168.0.145/toggle

##############################
# Switch 4 
##############################

if [ "$1" == "4" ]; then

	# anschalten
	if [ "$2" == "on" ]; then
		curl -X GET http://192.168.0.78/cm?cmnd=Power%20on
	fi
	# ausschalten
	if [ "$2" == "off" ]; then
		curl -X GET http://192.168.0.78/cm?cmnd=Power%20off
	fi
	# toggle
	if [ "$2" == "toggle" ]; then
		curl -X GET http://192.168.0.78/cm?cmnd=Power%20TOGGLE
	fi
fi
