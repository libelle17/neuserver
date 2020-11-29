#!/bin/zsh
ZV=/gerade
mkdir -p $ZV
Ziel=$ZV/TurbomedDB.7z
Q=/opt/turbomed
ionice -c3 nice -n19 7z u $Ziel $Q/PraxisDB $Q/StammDB $Q/DruckDB $Q/Dictionary $Q/linux -mx=4 -mtc=on -mmt=on
mountpoint -q /DATA&&{ mkdir -p /DATA$ZV; cp -a $Ziel /DATA$Ziel;}
# pgrep -c -f "dorsync.sh.* /gerade/PraxisDB" || dorsync.sh --delete /opt/turbomed/PraxisDB/ /gerade/PraxisDB >>/var/log/dorsync-Aufruf-gerade.log 2>&1 
# pgrep -c -f "dorsync.sh.* /gerade/StammDB"  || dorsync.sh --delete /opt/turbomed/StammDB/  /gerade/StammDB  >>/var/log/dorsync-Aufruf-gerade.log 2>&1 

