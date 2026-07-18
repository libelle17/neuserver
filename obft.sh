#!/bin/bash
# obft.sh - "ob Feiertag": prüft, ob heute (in Bayern) ein gesetzlicher
# Feiertag ist, und hinterlegt das Ergebnis als Marker-Datei
# /root/heutefeiertag (Existenz = ja), die andere Skripte/Cron-Einträge
# abfragen können, um an Feiertagen z.B. Praxis-spezifische Läufe
# auszulassen. 24.12. und 31.12. gelten fest als "Feiertag" (auch ohne
# gesetzlichen Feiertagsstatus); alle anderen Tage werden per Kayaposoft-API
# (kayaposoft.com, Land "ger", Region "by") abgefragt. Aufruf ohne Parameter.
pruefe () {
  datei=/root/heutefeiertag
  today=$(date --date="0 days ago " +"%-d-%-m-%Y");
  touch $datei;
  if echo "$today"|grep -q ^24-12; then return 0; fi;
  if echo "$today"|grep -q ^31-12; then return 0; fi;
  # if echo "$today"|grep -q ^06-01; then return 0; fi;
  # if echo "$today"|grep -q ^01-11; then return 0; fi;
  json_return=$(curl -s https://www.kayaposoft.com/enrico/json/v2.0/?action=isPublicHoliday\&date=$today\&country=ger\&region=by )
  if echo "$json_return"|grep -q true; then return 0; fi;
  rm -f $datei;
  return 1;
}

pruefe;
