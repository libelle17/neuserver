#!/bin/zsh
# soll alle sehr relevanten Datenen kopieren, fuer z.B. halbstündlichen Gebrauch
# mountvirt.sh -a
wirt=$(hostname); wirt=${wirt%%.*};
[ $wirt = linux1 ]&&obsh=||obsh="ssh linux1";
ot=/opt/turbomed;
if $obsh test -d $ot/PraxisDB; then 
  obvirt=; 
  VzL="PraxisDB StammDB DruckDB Dictionary Vorlagen Formulare KVDT Dokumente Daten labor LaborStaber";
else 
  obvirt=1; 
  VzL="PraxisDB StammDB DruckDB Dictionary";
  ZoD=/mnt/
fi;
if [ $wirt != linux1 ]; then
  if [ "$obvirt" ]; then
    [ -d $ot -a ! -d $ot-res ]&& mv $ot $ot-res;
  else
    [ -d $ot-res -a ! -d $ot ]&& mv $ot-res $ot;
  fi;
fi;
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/virtnamen.sh # braucht $wirt
. ./virtnamen.sh
[ $obvirt ]&&ZoD=${ot#/}||ZoD=/mnt/$gpc;
. ${MUPR%/*}/bugem.sh
[ "$verb" ]&&echo obvirt: $obvirt;
altEXFEST=$EXFEST;EXFEST=;
for Vz in $VzL; do
  case $Vz in PraxisDB|StammDB|DruckDB)testdt="objects.dat";;Dictionary)testdt="_objects.dat";;*)testdt=;;esac;
  case $Vz in Vorlagen|Formulare|KVDT|Dokumente|Daten|labor|LaborStaber)obOBDEL=;;*)obOBDEL="--delete";;esac; 
    # obOBDEL=$OBDEL, wenn Benutzer es einstellen können soll
  [ $obvirt ]&&{ ur=mnt/$gpc/turbomed; hin=$ot-res;}||{ ur=$ot; hin=mnt/$gpc/turbomed;}
  kopiermt "$ur/$Vz" "$hin/" "" "$obOBDEL" "$testdt" "1800" 1; # ohne --iconv
done;
exit;
ZL=$altZL;
EXFEST=$altEXFEST;
