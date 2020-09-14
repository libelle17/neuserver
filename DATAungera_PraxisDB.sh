#!/bin/zsh
7z u /DATA/ungera/TurbomedDB.7z /opt/turbomed/PraxisDB /opt/turbomed/StammDB /opt/turbomed/DruckDB /opt/turbomed/Dictionary /opt/turbomed/linux -mx=4 -mtc=on -mmt=on
# pgrep -c -f "dorsync.sh.* /DATA/ungera/PraxisDB" || dorsync.sh --delete /opt/turbomed/PraxisDB/ /DATA/ungera/PraxisDB >>/var/log/dorsync-Aufruf-DATAungerade.log 2>&1
# pgrep -c -f "dorsync.sh.* /DATA/ungera/StammDB"  || dorsync.sh --delete /opt/turbomed/StammDB/  /DATA/ungera/StammDB  >>/var/log/dorsync-Aufruf-DATAungerade.log 2>&1 

