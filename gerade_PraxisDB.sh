#!/bin/zsh
# gerade_PraxisDB.sh - Turbomed-Datenbanksicherung für gerade Kalendertage
# (Gegenstück: ungera_PraxisDB.sh für ungerade Tage - so bleiben durch
# tägliches Update per Cron immer zwei um einen Tag versetzte Generationen
# erhalten). Aktualisiert (7z u = update, nur geänderte Teile) ein
# 7z-Archiv $ZV/TurbomedDB.7z aus PraxisDB/StammDB/DruckDB/Dictionary/linux
# unter /opt/turbomed und kopiert es zusätzlich nach /DATA/gerade, falls
# /DATA gemountet ist. Die auskommentierten dorsync.sh-Zeilen sind ein nicht
# aktiver Alternativansatz (Verzeichnis-weise rsync statt 7z-Archiv).
# Aufruf ohne Parameter.
ZV=/gerade
mkdir -p $ZV
Ziel=$ZV/TurbomedDB.7z
Q=/opt/turbomed
ionice -c3 nice -n19 7z u $Ziel $Q/PraxisDB $Q/StammDB $Q/DruckDB $Q/Dictionary $Q/linux -mx=4 -mtc=on -mmt=on
mountpoint -q /DATA&&{ mkdir -p /DATA$ZV; cp -a $Ziel /DATA$Ziel;}
# pgrep -c -f "dorsync.sh.* /gerade/PraxisDB" || dorsync.sh --delete /opt/turbomed/PraxisDB/ /gerade/PraxisDB >>/var/log/dorsync-Aufruf-gerade.log 2>&1
# pgrep -c -f "dorsync.sh.* /gerade/StammDB"  || dorsync.sh --delete /opt/turbomed/StammDB/  /gerade/StammDB  >>/var/log/dorsync-Aufruf-gerade.log 2>&1

