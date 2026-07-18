#!/bin/bash
# komprsql.sh - komprimiert ältere SQL-Dumps in /DATA/sql: alle *.sql-Dateien
# direkt in diesem Verzeichnis, älter als 14 Tage und größer als 1 MB, werden
# einzeln per 7z (mit niedriger IO-/CPU-Priorität ionice/nice) archiviert; ein
# evtl. vorhandenes altes .7z wird vorher gelöscht, das .7z bekommt danach den
# Zeitstempel der Originaldatei (touch -r) und die Original-.sql wird gelöscht
# - aber nur, wenn die 7z-Erstellung erfolgreich war (&&). Aufruf ohne Parameter.
find /DATA/sql -maxdepth 1 -mtime +14 -size +1M -name "*.sql" -print0|xargs -0 -n1 -I{} -t sh -c "rm -f '{}.7z'; ionice -c3 nice -n19 7z a '{}.7z' '{}' -mx=9 -md=32m -mmt=4 -mtc=on&&{ touch -r '{}' '{}.7z'; rm '{}';};"
# -40 3 * * * mountpoint -q "/DATA" && /usr/bin/ionice -c 3 /usr/bin/7z a "/DATA/TMBack/TM`date +\%Y\%m\%d_\%H\%M\%S`.7z" /opt/turbomed/StammDB /opt/turbomed/PraxisDB -mx=9 -mtc=on -mmt=on >>/var/log/cron.log 2>>/var/log/cronf.log 
