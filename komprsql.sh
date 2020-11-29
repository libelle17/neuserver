#!/bin/bash
find /DATA/sql -maxdepth 1 -mtime +14 -size +1M -name "*.sql" -print0|xargs -0 -n1 -I{} -t sh -c "rm -f '{}.7z'; ionice -c3 nice -n19 7z a '{}.7z' '{}' -mx=9 -mtc=on -mmt=on&&{ touch -r '{}' '{}.7z'; rm '{}';};" 
# -40 3 * * * mountpoint -q "/DATA" && /usr/bin/ionice -c 3 /usr/bin/7z a "/DATA/TMBack/TM`date +\%Y\%m\%d_\%H\%M\%S`.7z" /opt/turbomed/StammDB /opt/turbomed/PraxisDB -mx=9 -mtc=on -mmt=on >>/var/log/cron.log 2>>/var/log/cronf.log 
