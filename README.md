# measurements

Create graphs and statistics from my home's consumption of gas, water and power
-- later also for solar power generation.

## manual readings

Yes, it still uses the google spreadsheet where I enter my daily consumption
data manually. Automation of meter readings is in progress.

## automatic readings

The power meter is read through a photo transistor (one LED blink per Wh), some
details in German here:
[https://dc.georgruss.ch/2021/02/24/elektrischer-datendurchstich/](https://dc.georgruss.ch/2021/02/24/elektrischer-datendurchstich/)

# directories

## cache

Data is read from the daily manual readings google spreadsheet. In order to a)
not re-read the spreadsheet to often and b) have a backup of the csv file, this
data is stored in this folder.

## figs

Any figure output from R is put into this folder. Folder contents are not
checked in.

## zaehlerablesung

This stores the script(s) that are being run on the Raspberry Pi to get the
meter readings. Currently only power meter.
