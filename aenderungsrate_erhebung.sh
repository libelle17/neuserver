#!/bin/bash
# Erhebt Aenderungsraten unter /DATA in drei Zeitfenstern (1/5/15 Minuten), jeweils
# mit und ohne die bekannten Haushaltsverzeichnisse rett/ und Papierkorb/, um Schwelle
# und Intervall fuer massenaenderung_waechter.sh empirisch zu kalibrieren, statt sie
# nur aus einer einzelnen Stichprobe zu schaetzen (s. Anleitung_Ransomware_Vorsorge_
# und_Notfall.md). Nur zur Kalibrierung gedacht, KEIN Alarmmechanismus.
#
# Per Cron alle 5 Minuten aufrufen (mit verhdop.sh gegen Ueberlappung); ein einziger
# find-Durchlauf mit 16 Minuten Fenster deckt dank der 5-Minuten-Taktung alle drei
# Fenster lueckenlos ab, statt drei separate, teure Baumdurchlaeufe zu machen.

LOG=/var/log/aenderungsrate_erhebung.csv
NOW=$(date +%s)

[ -d /DATA ] || exit 0
mountpoint -q /DATA 2>/dev/null || exit 0

[ -f "$LOG" ] || echo "zeitpunkt;anzahl_1min_gesamt;anzahl_1min_ohne_rett_papierkorb;anzahl_5min_gesamt;anzahl_5min_ohne_rett_papierkorb;anzahl_15min_gesamt;anzahl_15min_ohne_rett_papierkorb" > "$LOG"

find /DATA -mmin -16 -type f -printf '%T@ %p\n' 2>/dev/null | awk -v now="$NOW" -v logdatei="$LOG" -v ts="$(date '+%Y-%m-%d %H:%M:%S')" '
{
  alter_min = (now - $1) / 60;
  pfad = substr($0, index($0, " ") + 1);
  obausgenommen = (pfad ~ /^\/DATA\/rett\// || pfad ~ /^\/DATA\/Papierkorb\//);
  if (alter_min <= 1)  { g1++;  if (!obausgenommen) o1++; }
  if (alter_min <= 5)  { g5++;  if (!obausgenommen) o5++; }
  if (alter_min <= 15) { g15++; if (!obausgenommen) o15++; }
}
END {
  printf "%s;%d;%d;%d;%d;%d;%d\n", ts, g1+0, o1+0, g5+0, o5+0, g15+0, o15+0 >> logdatei;
}'
