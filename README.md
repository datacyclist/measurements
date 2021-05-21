# measurements

Collect, crunch and visualize data from my home.

What's collected:

- Heating parameters for all rooms
- Central heating parameters (Viessmann via optolink)
- Different inside and outside temperature sensors
- Electrical power consumption (central)
- Electrical power consumption (single large consumption points like A/C)
- Readings from gas and water meters

## automatic/manual readings

### power readings

- Power readings are automated (S0)

The power meter is read through a photo transistor (one LED blink per Wh), some
details in German here:
[https://dc.georgruss.ch/2021/02/24/elektrischer-datendurchstich/](https://dc.georgruss.ch/2021/02/24/elektrischer-datendurchstich/)

Daily power consumption is crunched into a one-line-per-day csv file in the
cache dir. Readings are copied manually from this file into the csv readings
file.

### water readings

- Water readings are automated (S0, 2021-05-21)

### gas readings

- Gas readings are still manual (from a meter photo).
- Data is entered into a csv file manually.

## heating/thermostats

The remote-controlled MAX thermostats transmit a lot of readings to FHEM. Those
are crunched and uploaded to an InfluxDB, where Grafana gets that data for dashboards.

# directories

## cache

This dir stores some auxiliary data.

- Daily calculated consumption is here in *dfdays.csv*.
- Power meter readings (from the blink LED) in *$date-zaehlerstaende_strom_errechnet.csv*.

## csv

- Daily readings are **manually** entered here in *ablesewerte-zum-eintragen.csv*.

## figs

Any figure output from R is put into this folder. Folder contents are not usually
checked in.

## lcd

Two scripts to write temperature data to the blue 20x4 LCD.

## sensors

- Python scripts for temperature and pressure readings.
- bash script to log sensors to InfluxDB
- bash script to log thermostat readings to InfluxDB

## script

R scripts for data handling and graphics generation go in here.

## shellscripts

- remote control for wifi switches
- remote control for Viessmann heating

## zaehlerablesung

- python scripts for power and water readings
- service files for systemd (power/water)
- shell scripts to log power/water to influxDB
