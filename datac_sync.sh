#!/bin/bash
# datac_sync.sh - sichert MO, mp4 und wser von /DATB (die lokalen, nicht in
# /DATA gespiegelten linux7-eigenen Daten) zusaetzlich auf die separate
# Platte /DATAC, damit sie bei einem Ausfall von sdc (der /DATB-Platte)
# nicht verloren gehen. Nur auf linux7 sinnvoll (dort gibt es /DATB und
# /DATAC in dieser Aufteilung seit 3.9.2026, s. Git-Historie) - per Cron
# mit Hostpruefung eingebunden, s. Crontab. Aufruf ohne Parameter.
set -u
LOG=/var/log/datac_sync.log
mountpoint -q /DATB || exit 0
mountpoint -q /DATAC || exit 0
for d in MO mp4 wser; do
  ionice -c3 nice -n19 rsync -a --delete "/DATB/$d/" "/DATAC/$d/" >>"$LOG" 2>&1
done
echo "$(date '+%F %T') OK" >>"$LOG"
