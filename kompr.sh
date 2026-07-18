#!/bin/bash
# kompr.sh - komprimiert alte, nicht mehr aktiv gebrauchte Unterverzeichnisse
# zu je einem eigenen 7z-Archiv und löscht danach das Originalverzeichnis:
# aktiv sind aktuell nur die beiden letzten find-Zeilen (Ordner unter
# /DATA/Patientendokumente/HDI alt älter als 90 Tage, bzw. unter .../Dicom
# älter als 180 Tage). Die auskommentierten find-Zeilen darüber sind ältere/
# probeweise andere Varianten (anderes Zielverzeichnis, andere Fristen/
# Kompressionsoptionen) und derzeit inaktiv. Aufruf ohne Parameter.
#find ~/bin -mindepth 1 -type d -mtime -3 -print0 | /usr/bin/xargs -0  -i 7z a -t7z -mx=9 {} {} && ls {}
#find /DATA/Papierkorb/Patientendokumente/HDI\ alt -mindepth 1 -maxdepth 1 -type d -mtime +1595 -exec ls -d {} \;
#find /DATA/Papierkorb/Patientendokumente/HDI\ alt -mindepth 1 -maxdepth 1 -type d -mtime +1495 -exec 7z a -t7z -mx=9 -mtc=on -mmt=on {} {} \; -exec rm -rf {} \;

#find /DATA/Papierkorb/Patientendokumente/HDI\ alt -mindepth 1 -maxdepth 1 -type d -mtime +90 -exec 7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on {} {} \; -exec rm -rf {} \;
find /DATA/Patientendokumente/HDI\ alt -mindepth 1 -maxdepth 1 -type d -mtime +90 -exec ionice -c3 nice -n19 7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on {}.7z {} \; -exec rm -rf {} \;
find /DATA/Patientendokumente/Dicom -mindepth 1 -maxdepth 1 -type d -mtime +180 -exec echo \"\{\}\" \; -exec ionice -c3 nice -n19 7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on {}.7z {} \; -exec rm -rf {} \; -exec echo Fertig mit {} \;
