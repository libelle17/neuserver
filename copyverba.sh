#!/bin/dash
# copyverba.sh - neuere/schlankere Sicherung auf das externe USB-Laufwerk
# "verbatim" (Mountpunkt /amnt/verbatim), beschränkt auf die Turbomed-
# Unterverzeichnisse unter /opt/turbomed (PraxisDB bzw. PraxisDB-res, je
# nachdem welches existiert, StammDB, labor, LaborStaber, KVDT, DruckDB,
# Dictionary, Vorlagen, _TMVS, Zertifikate, Dokumente, Lizenz) - anders als
# copyverb.sh (incopy.sh-basiert, sichert viel mehr Pfade) über die aus
# bugem.sh gesourcte Funktion kopiermt(). Aufruf ohne Parameter.
USB=verbatim
logf=/var/log/$USB.log
#ZoD=/amnt/seag
ZL=;
Ziel=/amnt/verbatim
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bugem.sh
mountpoint -q "$Ziel" || mount "$Ziel"
echo `date +"%d.%m.%Y %X"` "Fange an" >"$logf"
ot=opt/turbomed;
[ -d /$ot/PraxisDB ]&&PD=PraxisDB;
[ -d /$ot/PraxisDB-res ]&&PD=PraxisDB-res;
echo PD: $PD
for u in \
  $PD \
  StammDB \
  labor \
  LaborStaber \
  KVDT \
  DruckDB \
  Dictionary \
  Vorlagen \
  _TMVS \
  Zertifikate \
  Dokumente \
  Lizenz; \
do \
  kopiermt "opt/turbomed/$u/" "$Ziel/turbomed/$u/" "";
done;
