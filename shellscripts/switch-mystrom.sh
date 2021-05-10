#!/bin/bash

# anschalten
# curl -X GET http://192.168.0.145/relay?state=1
# ausschalten
# curl -X GET http://192.168.0.145/relay?state=0
# toggle
# curl -X GET http://192.168.0.145/toggle

##############################
# Switch 1
##############################

if [ "$1" == "1" ]; then

	if [ "$2" == "off" ]; then
		curl -X GET http://192.168.0.45/relay?state=0
	fi
	# anschalten
	if [ "$2" == "on" ]; then
		curl -X GET http://192.168.0.45/relay?state=1
	fi
	# toggle
	if [ "$2" == "toggle" ]; then
		curl -X GET http://192.168.0.45/toggle
	fi
fi

##############################
# Switch 2
##############################

if [ "$1" == "2" ]; then

	if [ "$2" == "off" ]; then
		curl -X GET http://192.168.0.46/relay?state=0
	fi
	# anschalten
	if [ "$2" == "on" ]; then
		curl -X GET http://192.168.0.46/relay?state=1
	fi
	# toggle
	if [ "$2" == "toggle" ]; then
		curl -X GET http://192.168.0.46/toggle
	fi
fi

##############################
# Switch 3
##############################

if [ "$1" == "3" ]; then

	if [ "$2" == "off" ]; then
		curl -X GET http://192.168.0.47/relay?state=0
	fi
	# anschalten
	if [ "$2" == "on" ]; then
		curl -X GET http://192.168.0.47/relay?state=1
	fi
	# toggle
	if [ "$2" == "toggle" ]; then
		curl -X GET http://192.168.0.47/toggle
	fi
fi

##############################
# Switch 4
##############################

if [ "$1" == "4" ]; then

	if [ "$2" == "off" ]; then
		curl -X GET http://192.168.0.48/relay?state=0
	fi
	# anschalten
	if [ "$2" == "on" ]; then
		curl -X GET http://192.168.0.48/relay?state=1
	fi
	# toggle
	if [ "$2" == "toggle" ]; then
		curl -X GET http://192.168.0.48/toggle
	fi
fi

##############################
# Switch 5
##############################

if [ "$1" == "5" ]; then

	if [ "$2" == "off" ]; then
		curl -X GET http://192.168.0.54/relay?state=0
	fi
	# anschalten
	if [ "$2" == "on" ]; then
		curl -X GET http://192.168.0.54/relay?state=1
	fi
	# toggle
	if [ "$2" == "toggle" ]; then
		curl -X GET http://192.168.0.54/toggle
	fi
fi

##############################
# Switch 6
##############################

if [ "$1" == "6" ]; then

	if [ "$2" == "off" ]; then
		curl -X GET http://192.168.0.55/relay?state=0
	fi
	# anschalten
	if [ "$2" == "on" ]; then
		curl -X GET http://192.168.0.55/relay?state=1
	fi
	# toggle
	if [ "$2" == "toggle" ]; then
		curl -X GET http://192.168.0.55/toggle
	fi
fi

# 
# 	sudo echo '1' > /sys/class/gpio/gpio8/value
# 	sleep 0.5
# 	sudo echo '1' > /sys/class/gpio/gpio6/value
# 	echo 'on' > /var/tmp/heizstatus
