## scripts for optolink connection to gas heating

Anything in here is only to be executed on the Raspi that has the USB/Serial
connection to the heating.

## commands

get commands:
vclient -c 'getTempWWsoll'

set commands:
vclient -c 'setTempWWsoll 35'

## tested commands
- getTempA
- getTempAtp
- getTempAged
- getTempWWist
- getTempWWsoll und 'setTempWWsoll xx'
- getBetriebArtM1
- setBetriebArtM1:
    - 'setBetriebArtM1 NORM' (H+WW) 
    - 'setBetriebArt RED' (WW)
- getTempStp2
- getSpeichervorrang
- getTempKOffset
- getTempKist
- getTempAbgas
- getVolStrom
- getBrennerStatus
- getBrennerStarts
- getBrennerStunden1
- getLeistungIst
- getNeigungM1 und setNeigungM1
- getNiveauM1 und setNiveauM1
- getTempVListM1
- getTempVLsollM1
- getTempRL17A
- getTempRaumNorSollM1 und set...
- getPumpeStatusM1
- getPumpeDrehzahlIntern
- getAnlagenschema


