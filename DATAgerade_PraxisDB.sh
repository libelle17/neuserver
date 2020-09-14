#!/bin/zsh
7z u /DATA/gerade/TurbomedDB.7z /opt/turbomed/PraxisDB /opt/turbomed/StammDB /opt/turbomed/DruckDB /opt/turbomed/Dictionary /opt/turbomed/linux -mx=4 -mtc=on -mmt=on
# pgrep -c -f "dorsync.sh.* /DATA/gerade/PraxisDB" || dorsync.sh --delete /opt/turbomed/PraxisDB/ /DATA/gerade/PraxisDB >>/var/log/dorsync-Aufruf-DATAgerade.log 2>&1
# pgrep -c -f "dorsync.sh.* /DATA/gerade/StammDB"  || dorsync.sh --delete /opt/turbomed/StammDB/  /DATA/gerade/StammDB  >>/var/log/dorsync-Aufruf-DATAgerade.log 2>&1 

