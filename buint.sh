#!/bin/dash
# zsh geht nicht, wegen der fehlenden Aufteilung der Variablen mit Leerzeichen
# soll alle sehr relevanten Datenen kopieren, fuer z.B. halbstündlichen Gebrauch
# wenn es auf dem Hauptserver linux1 das Verzeichnis /opt/turbomed gibt, so wird auf jedem Server /opt/turbomed als Quelle verwendet, sonst /mnt/virtwin/turbomed
# mountvirt.sh -a
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
QL=;ZL=; # dann werden die cifs-Laufwerke verwendet
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
[ "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;}
wirt=$buhost;
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast sowie aus $buhost: tush
ot=/opt/turbomed;
res=$ot-res;
if eval "$tush 'test -d $ot/PraxisDB'"; then # wenn es auf linux1 /opt/turbomed/PraxisDB gibt, 
  obvirt=;                                   # also nicht die virtuelle Installation verwendet wird
  VzL="PraxisDB StammDB DruckDB Dictionary Vorlagen Formulare KVDT Dokumente Daten labor LaborStaber";
  ur=$ot; 
  hin=mnt/$gpc/turbomed;
  if [ "$buhost"/ != "$LINEINS"/ -a -d "$res" -a ! -d "$ot" ]; then
    ausf "mv $res $ot" $blau; # # dann ggf. die linux-Datenbank umbenennen
  fi;
else 
  obvirt=1; 
  VzL="PraxisDB StammDB DruckDB Dictionary";
  ur=mnt/$gpc/turbomed; 
  hin=$res;
  if [ "$buhost"/ != "$LINEINS"/ -a -d "$ot" -a ! -d "$res" ]; then
    ausf "mv $ot $res" $blau; # dann ggf. die linux-Datenbank umbenennen
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
