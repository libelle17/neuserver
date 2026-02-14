#!/bin/bash
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost=linux1 festlegen
ziele="0 7"; # Vorgaben für Ziel-Servernummern: linux1ur, linux3 usw., abwandelbar durch Befehlszeilenparameter -z
ZL=; # dann werden die cifs-Laufwerke verwendet
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
# nurdrei=1;
# nurzweidrei=1;
[ "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;}
dopweg.sh
find /DATA/Patientendokumente/dok -iname "zulöschen*" -delete
obOBDEL=--delete
wirt=$buhost;
for ziel in $ziele; do
  ZL=linux$ziel;
  ZmD=$ZL:;
  kopiermt "/DATA/Patientendokumente/dok" "/DATA/Patientendokumente/" "" "$obOBDEL" "" ""; # ohne --iconv
  kopiermt "/DATA/Patientendokumente/eingelesen" "/DATA/Patientendokumente/" "" "$obOBDEL" "" ""; # ohne --iconv
  ZL=;
  ZmD=;
  mount /mnt/wser/indamed
  kopiermt "/mnt/wser/indamed" "/wrz" "" "$obOBDEL" "" "";
  EXGES="";
done;
