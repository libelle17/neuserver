#!/bin/dash
# soll alle sehr relevanten Datenen von aktiven Server linux1 auf die Reserveserver kopieren, fuer z.B. halbstündlichen Gebrauch
# wenn des das Verzeichnis /opt/turbomed gibt, wird dieses für die Datenbank verwendet, sonst /mnt/virtwin/turbomed
# das auf den Reserveservern verwendete Verzeichnis hängt davon ab, ob es auf linux1 /opt/turbomed gibt
# mountvirt.sh -a
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $QL, $ZL, $qssh, $zssh festlegen
[ -z "$ZL" ]&&{ printf "${rot}Kein Ziel angegeben. Breche ab$reset.\n";exit;}
wirt=$QL;
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tussh
l1gpc=$gpc; # Gast-PC von Linux1
wirt=$ZL;
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tussh
rgpc=$gpc; # Gast-PC des Reserveservers

ot=/opt/turbomed;
res=$ot-res;
wirt=$(hostname); wirt=${wirt%%.*}; # linux1, linux0 oder linux7
case $wirt in linux1)obsh="sh -c";;*)obsh="ssh linux1";;esac
if eval "$obsh 'test -d $ot/PraxisDB'"; then # wenn es auf linux1 /opt/turbomed/PraxisDB gibt, 
  obvirt=;                                   # also nicht die virtuelle Installation verwendet wird
  ur=$ot/; 
  hin=$ot;
  ausf "$zssh '[ -d $res -a ! -d $ot ]&& mv $res $ot'" $blau; # umgekehrt
else 
  obvirt=1; 
  ur=mnt/$l1gpc/turbomed/; 
  hin=mnt/$rgpc/turbomed;
  QL=;
  ZL=; # dann werden die cifs-Laufwerke verwendet
  ausf "$zssh '[ -d $ot -a ! -d $res ]&& mv $ot $res'" $blau; # dann ggf. auf dem Zielrechner die linux-Datenbank umbenennen
fi;
[ "$verb" ]&&printf "obsh: ${blau}$obsh$reset\n";
[ "$verb" ]&&printf "obvirt: ${blau}$obvirt$reset\n";
kopiermt "$ur" "$hin" "" "$OBDEL" "PraxisDB/objects.dat" "1800" 1; # ohne --iconv
Dt=DATA; 
Pt=Patientendokumente;
ausf "$qssh 'mountpoint -q /$Dt 2>/dev/null||mount /$Dt'";
ausf "$zssh 'mountpoint -q /$Dt 2>/dev/null||mount /$Dt'";
ausf "$qssh 'mountpoint -q /${Dt} 2>/dev/null'&&$zssh 'mountpoint -q /${Dt} 2>/dev/null'"
if [ "$ret"/ = 0/ ]; then
 kopiermt "$Dt/turbomed" "$Dt/" "" "$OBDEL"
 kopiermt "$Dt/$Pt/eingelesen" "$Dt/$Pt/" "" "$OBDEL"
fi;
