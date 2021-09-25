#!/bin/dash
# zsh geht nicht, wegen der fehlenden Aufteilung der Variablen mit Leerzeichen
# soll alle sehr relevanten Datenen kopieren, fuer z.B. halbstündlichen Gebrauch
# wenn es auf dem Hauptserver linux1 das Verzeichnis /opt/turbomed gibt, so wird auf jedem Server /opt/turbomed als Quelle verwendet, sonst /mnt/virtwin/turbomed
# mountvirt.sh -a
MUPR=$(readlink -f $0); # Mutterprogramm
wirt=$(hostname); wirt=${wirt%%.*}; # linux1, linux0 oder linux7
[ $(hostname) != $LINEINS ]&&QL=$LINEINS;
[ $wirt = linux1 ]&&obsh="sh -c"||obsh="ssh linux1";
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tussh
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $QL, $ZL, $qssh, $zssh festlegen
ot=/opt/turbomed;
res=$ot-res;
if eval "$obsh 'test -d $ot/PraxisDB'"; then # wenn es auf linux1 /opt/turbomed/PraxisDB gibt, 
  obvirt=;                                   # also nicht die virtuelle Installation verwendet wird
  VzL="PraxisDB StammDB DruckDB Dictionary Vorlagen Formulare KVDT Dokumente Daten labor LaborStaber";
  ur=$ot; 
  hin=mnt/$gpc/turbomed;
else 
  obvirt=1; 
  VzL="PraxisDB StammDB DruckDB Dictionary";
  ur=mnt/$gpc/turbomed; 
  hin=$res;
fi;
if [ $wirt/ != $LINEINS/ ]; then
  if [ "$obvirt" ]; then
    [ -d $ot -a ! -d $res ]&& mv $ot $res;
  else
    [ -d $res -a ! -d $ot ]&& mv $res $ot;
  fi;
fi;
[ "$verb" ]&&printf "obsh: ${blau}$obsh$reset\n";
[ "$verb" ]&&printf "obvirt: ${blau}$obvirt$reset\n";
altEXFEST=$EXFEST;EXFEST=;
for Vz in $VzL; do
  case $Vz in PraxisDB|StammDB|DruckDB)testdt="objects.dat";;Dictionary)testdt="_objects.dat";;*)testdt=;;esac;
  case $Vz in Vorlagen|Formulare|KVDT|Dokumente|Daten|labor|LaborStaber)obOBDEL=;;*)obOBDEL="--delete";;esac; 
    # obOBDEL=$OBDEL, wenn Benutzer es einstellen können soll
  kopiermt "$ur/$Vz" "$hin/" "" "$obOBDEL" "$testdt" "1800" 1; # ohne --iconv
done;
exit;
ZL=$altZL;
EXFEST=$altEXFEST;
