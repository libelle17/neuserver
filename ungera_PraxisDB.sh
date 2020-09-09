#!/bin/zsh
ZV=/ungera
mkdir -p $ZV
Ziel=$ZV/TurbomedDB.7z
Q=/opt/turbomed
7z u $Ziel $Q/PraxisDB $Q/StammDB $Q/DruckDB $Q/Dictionary $Q/linux -mx=4 -mtc=on -mmt=on
mountpoint -q /DATA&&{ mkdir -p /DATA$ZV; cp -a $Ziel /DATA$Ziel;}
#pgrep -c -f "dorsync.sh.* /ungera/PraxisDB" || dorsync.sh --delete /opt/turbomed/PraxisDB/ /ungera/PraxisDB >>/var/log/dorsync-Aufruf-ungerade.log 2>&1
#pgrep -c -f "dorsync.sh.* /ungera/StammDB"  || dorsync.sh --delete /opt/turbomed/StammDB/  /ungera/StammDB  >>/var/log/dorsync-Aufruf-ungerade.log 2>&1 
