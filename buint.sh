#!/bin/bash
# dash geht nicht: --exclude={,abc/,def/} wirkt nicht
# zsh geht nicht, wegen der fehlenden Aufteilung der Variablen mit Leerzeichen
# soll alle sehr relevanten Datenen kopieren, fuer z.B. halbstündlichen Gebrauch
# wenn es auf dem Hauptserver linux1 das Verzeichnis /opt/turbomed gibt, so wird auf jedem Server /opt/turbomed als Quelle verwendet, sonst /mnt/virtwin/turbomed
# mountvirt.sh -a
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
ziele="0 3 7 8"; # Vorgaben für Ziel-Servernummern: linux0, linux3 usw., abwandelbar durch Befehlszeilenparameter -z
QL=;ZL=; # dann werden die cifs-Laufwerke verwendet
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
[ "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;}
wirt=$buhost;
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
[ "$gpc" ]||exit; # auf linux3 gibts keinen virtuellen Server
ot=opt/turbomed;
otP=/$ot/PraxisDB;
resD=PraxisDB-res;
otr=/$ot/$resD;
VzLg="PraxisDB StammDB DruckDB Dictionary Vorlagen Formulare KVDT Dokumente Daten labor LaborStaber"; # VzL groß
VzLk="PraxisDB StammDB DruckDB Dictionary"; # VzL klein
if eval "$tush 'test -d $otP'"; then # wenn es auf linux1 /opt/turbomed/PraxisDB gibt, 
  obvirt=;                                   # also nicht die virtuelle Installation verwendet wird
  VzL="$VzLg";
  ur=$ot # opt/turbomed
  hin=mnt/$gpc/turbomed;
  if [ "$buhost"/ != "$LINEINS"/ -a -d "$otr" -a ! -d "$otP" ]; then
    ausf "mv $otr $otP" $blau; # # dann ggf. die linux-Datenbank umbenennen
  fi;
else 
  obvirt=1; 
  VzL="$VzLk";
  ur=mnt/$gpc/turbomed; 
  hin=$ot;
  if [ "$buhost"/ != "$LINEINS"/ -a -d "$otP" -a ! -d "$otr" ]; then
    ausf "mv $otP $otr" $blau; # dann ggf. die linux-Datenbank umbenennen
  fi;
fi;
[ "$verb" ]&&printf "obsh: ${blau}$obsh$reset\n";
[ "$verb" ]&&printf "obvirt: ${blau}$obvirt$reset\n";
altEXFEST=$EXFEST;EXFEST=; # keine festen Ausnahmen in kompiermt
printf "${lila}1. intern hier kopieren${reset}";
for iru in 1 2 3; do
  if ssh administrator@$gpc cmd /c "(>>c:\turbomed\StammDB\objects.idx (call ) )&&exit||exit /b 1" 2>/dev/nul; then offen=1; else offen=; fi;
  [ "$verb" ]&&{ printf "\niru: $iru; offen: $offen\n"; };
  if [ "$offen" ]; then
    break;
  else
    echo "";
    [ "$obkill" ]&&{
      if [ "$iru" = 1 ]; then
        ausf "$tush 'mv /$ot/lauf /$ot/lau  2>/dev/null||touch /$ot/lau'&&sleep 80s";
      else
        VBoxManage controlvm Win10 poweroff; VBoxManage startvm Win10 --type headless;
      fi;
    }
  fi;
  [ "$obkill" ]||break;
done;
if [ "$offen" ]; then
 for Vz in $VzL; do
  [ "$obforce" ]&&testdt=||case $Vz in PraxisDB|StammDB|DruckDB)testdt="objects.dat";;Dictionary)testdt="_objects.dat";;*)testdt=;;esac;
  case $Vz in Vorlagen|Formulare|KVDT|Dokumente|Daten|labor|LaborStaber)obOBDEL=;;*)obOBDEL="--delete";;esac; 
    # obOBDEL=$OBDEL, wenn Benutzer es einstellen können soll
  uq=$Vz;
  [ "$obvirt" -a $Vz = PraxisDB ]&&uz=$resD||uz=$Vz;
  kopiermt "$ur/$uq/" "$hin/$uz" "" "$obOBDEL" "$testdt" "1800" 1; # ohne --iconv
 done;
else
 echo "";
fi;
[ "$obkill" ]&&{ mv /$ot/lau /$ot/lauf 2>/dev/null||touch /$ot/lauf;} # zurückbenennen, damit Turbomed wieder starten kann
if [ "$obmehr" -a "$buhost"/ = "$LINEINS"/ ]; then
printf "${lila}2. butm aufrufen${reset}\n";
# 2. wenn mehr, dann von hier aus auf die anderen nicht-virtuellen Server kopieren
  for ziel in $ziele; do
    if [ "$obecht" ]; then
      echo butm.sh linux$ziel -nv -e;
      butm.sh linux$ziel -nv -e;
    else
      echo butm.sh linux$ziel -nv;
      butm.sh linux$ziel -nv;
    fi;
  done;
printf "${lila}3. intern drüben kopieren${reset}\n";
# 3. wenn mehr, dann von hier den anderen nicht-virtuellen auf die anderen virtuellen Server kopieren
  ZL=;
  for QLteil in $ziele; do
    QL=linux$QLteil;
    [ $verb ]&&printf "Prüfe PC ${blau}linux$QL$reset ...";
    if pruefpc $QL kurz; then
      [ $verb ]&&printf " fiel positiv aus.\n";
      for Vz in $VzLk; do
        [ $verb ]&&printf "Bearbeite Verzeichnis: $blau$Vz$reset.\n";
        [ "$obforce" ]&&testdt=||case $Vz in PraxisDB|StammDB|DruckDB)testdt="objects.dat";;Dictionary)testdt="_objects.dat";;*)testdt=;;esac;
        obOBDEL=;
          # obOBDEL=$OBDEL, wenn Benutzer es einstellen können soll
        uq=$Vz;
        [ "$obvirt" -a $Vz = PraxisDB ]&&uz=$resD||uz=$Vz;
        wirt=$QL;
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
        hin=mnt/$gpc/turbomed;
        kopiermt "$ot/$uz/" "$hin/$uq" "" "$obOBDEL" "$testdt" "1800" 1; # ohne --iconv
      done; # Vz in $VzLk; do
    else
      [ $verb ]&&printf" fiel negativ aus.\n";
    fi; # pruefpc $QL kurz; then
  done; # QL in $ziele; do
fi; # [ "$obmehr" -a "$buhost"/ = "$LINEINS"/ ]; then
EXFEST=$altEXFEST;
