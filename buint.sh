#!/bin/bash
# dash geht nicht: --exclude={,abc/,def/} wirkt nicht
# zsh geht nicht, wegen der fehlenden Aufteilung der Variablen mit Leerzeichen
# soll alle sehr relevanten Datenen kopieren, fuer z.B. halbstündlichen Gebrauch
# wenn es auf dem Hauptserver linux1 das Verzeichnis /opt/turbomed gibt, so wird auf jedem Server /opt/turbomed als Quelle verwendet, sonst /amnt/virtwin/turbomed
# mountvirt.sh -a
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
# ziele="0 3 7 8"; # Vorgaben für Ziel-Servernummern: linux0, linux3 usw., abwandelbar durch Befehlszeilenparameter -z
ziele="0 3 7 8"; # Vorgaben für Ziel-Servernummern: linux0, linux3 usw., abwandelbar durch Befehlszeilenparameter -z
ZL=; # dann werden die cifs-Laufwerke verwendet
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
# nurdrei=1;
nurzweidrei=1;
[ "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;}
wirt=$buhost;
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
# gpc= z.B. virtwin, virtwin0, virtwin3, virtwin7, virtwin8, gast= Win10
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
  hin=amnt/$gpc/turbomed;
  if [ "$buhost"/ != "$LINEINS"/ -a -d "$otr" -a ! -d "$otP" ]; then
    ausf "mv $otr $otP" $blau; # # dann ggf. die linux-Datenbank umbenennen
  fi;
  text="von $buhost nach $gpc"
else 
  obvirt=1; 
  VzL="$VzLk";
  ur=amnt/$gpc/turbomed; 
  hin=$ot;
  if [ "$buhost"/ != "$LINEINS"/ -a -d "$otP" -a ! -d "$otr" ]; then
    ausf "mv $otP $otr" $blau; # dann ggf. die linux-Datenbank umbenennen
  fi;
  text="von $gpc nach $buhost"
fi;
[ "$verb" ]&&printf "obsh: ${blau}$obsh$reset\n";
[ "$verb" ]&&printf "obvirt: ${blau}$obvirt$reset\n";
altEXFEST=$EXFEST;EXFEST=; # keine festen Ausnahmen in kompiermt
printf "${lila}1. intern $text kopieren${reset}";
for iru in 1 2 3; do
  [ "$verb" ]&&printf "\nPrüfe die Überschreibbarkeit von c\:\\turbomed\\StammDB\\objects.idx auf $blau$gpc$reset\n";
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
  ausf "rm -rf /$hin/$uz/.objects*"; # Reste alter Kopierversuche löschen
  if [ ! "$nurdrei" -a ! "$nurzweidrei" ]; then
    # hier sind immer $wirt und $ZL leer
    kopiermt "$ur/$uq/" "$hin/$uz" "" "$obOBDEL" "$testdt" "1800" 1; # ohne --iconv
  fi;
 done;
fi;
[ ! "$offen" -o ! "$verb" ]&&echo "";
[ "$obkill" ]&&{ mv /$ot/lau /$ot/lauf 2>/dev/null||touch /$ot/lauf;} # zurückbenennen, damit Turbomed wieder starten kann
if [ "$obmehr" -a "$buhost"/ = "$LINEINS"/ ]; then

  printf "${lila}2. butm aufrufen, um von linux1 nach linux{$ziele} zu kopieren${reset}\n";
  if ! [ "$nurdrei" ]; then
# 2. wenn mehr, dann von hier aus auf die anderen nicht-virtuellen Server kopieren
    for ziel in $ziele; do
      [ "$obecht" ]&&echtpar=" -e"||echtpar=;
      [ "$verb" ]&&verbpar=" -v"||verbpar=;
      echo ${MUPR%/*}/butm.sh linux$ziel -nv$echtpar$verbpar;
      ${MUPR%/*}/butm.sh linux$ziel -nv$echtpar$verbpar;
    done;
  fi; # nurdrei

  printf "${lila}3. intern von linux{$ziele} nach virtwin{$ziele} kopieren${reset}\n";
  # 3. wenn mehr, dann (von hier aus über ssh) den anderen nicht-virtuellen auf die anderen virtuellen Server kopieren
  ZL=;
  for nr in $ziele; do
    wirt=linux$nr;
    [ $verb ]&&printf "\nPrüfe PC ${blau}$wirt$reset ...";
    if pruefpc $wirt; then
      [ $verb ]&&printf " fiel positiv aus.\n";
. ${MUPR%/*}/virtnamen.sh; # legt aus $wirt fest: $gpc, $gast, $tush
      # case $wirt in *0*) gpc=virtwin0; gast=Win10;;
      #               *1*) gpc=virtwin;  gast=Win10;;
      #               *3*) gpc=virtwin3; gast=Win10;;
      #               *7*) gpc=virtwin7; gast=Win10;;
      #               *8*) gpc=virtwin8; gast=Win10;;
      # esac;
      # case $wirt in $LINEINS)tush="sh -c ";;*)tush="ssh $wirt ";;esac
      [ $verb ]&&printf "${blau}gpc: $rot$gpc$reset\n";
      if [ "$gpc" ]; then
        HOST=$(hostname);HOST=${HOST%%.*}; # linux1 usw.
        [ $wirt = $HOST ]&&tush=||tush="ssh $wirt ";
        if ping -c1 -W1 "$gpc" >/dev/null 2>&1; then ok=1; else
         ok=;
         printf "$blau$wirt$reset zwar anpingbar, $blau$gpc$reset aber nicht, versuche ihn zu starten\n";
         ausf "${tush}mountpoint -q /DATA"
         [ $ret != 0 ]&&{ 
          ausf "${tush}mount /DATA"
          [ $ret != 0 ]&&{ 
            ausf "${tush}pkill -9 fsck"
            ausf "${tush}mount /DATA"
          }
         }
         # ausf "ssh linux3 VBoxManage list vms|grep -q \"Win10\""
         # echo $ret
         ausf "${tush}VBoxManage startvm $gast --type headless";      
         for iru in $(seq 1 1 120); do 
          if ping -c1 -W1 "$gpc" >/dev/null 2>&1; then ok=1; break; fi;
         done;
         [ "$ok" ]&&printf "brauchte $blau$iru$reset Durchläufe;\n";
        fi; #         if ping -c1 -W1 "$gpc" >/dev/null 2>&1; then ok=1; else
        if [ ! "$ok" ]; then
         printf "$blau$gpc$reset immer noch nicht anpingbar, überspringe ihn\n";
        else
          cifs=/amnt/$gpc/turbomed;
          printf "$lila$gpc$reset, wirt: $lila$wirt$reset: " # , cifs: $lila$cifs$reset:\n";
          for vers in 3.11 3.11 3.02 3.02 3.0 3.0 2.1 2.1 2.0 2.0 1.0 1.0; do
            if ! mountpoint -q $cifs; then
              printf "\n";
              ausf "mount //$gpc/Turbomed $cifs -t cifs -o nofail,vers=$vers,credentials=/home/schade/.wincredentials >/dev/null 2>&1 " $blau
              printf "\n";
            else
       #       printf " ${blau}$cifs$reset gemountet!\n"
              break;
            fi;
          done;
        fi; # [ ! "$ok" ]; then else
        if mountpoint -q $cifs; then
          [ "$verb" ]&&printf "$blau$cifs$reset gemountet.\n"; 
        else 
          printf "$blau$cifs${rot} kein mountpoint, verlasse Schleife$reset\n"; 
          continue;
        fi;
      fi; # if [ "$gpc" ]; then
      for Vz in $VzLk; do
        [ $verb ]&&printf "Bearbeite Verzeichnis: $blau$Vz$reset.\n";
        [ "$obforce" ]&&testdt=||case $Vz in PraxisDB|StammDB|DruckDB)testdt="objects.dat";;Dictionary)testdt="_objects.dat";;*)testdt=;;esac;
        obOBDEL=;
          # obOBDEL=$OBDEL, wenn Benutzer es einstellen können soll
        uq=$Vz;
        [ "$obvirt" -a $Vz = PraxisDB ]&&uz=$resD||uz=$Vz;
        hin=amnt/$gpc/turbomed;
        ausf "rm -rf /$hin/$uq/.objects*"; # Reste alter Kopierversuche löschen
        if [ $dreieck ]; then
          # wirt ist linux$nr, ZL ist leer, würde hierher auf das cifs-Laufwerk kopiert
          kopiermt "$ot/$uz/" "$hin/$uq" "" "$obOBDEL" "$testdt" "1800" 1; # ohne --iconv
        else
          # kopiert auf wirt von dort auf das dortige cifs-Laufwerk
          ausf "ssh $wirt 'zl=/$hin;mkdir -p \$zl;mountpoint -q \$zl||mount \$zl; mountpoint -q \$zl&&rsync -avu /$ot/$uz/ \$zl/$uq/' ";
          # für die Client-Zertifikate, könnte aber nicht gehen
#          rsync -avu /amnt/virtwin/turbomed/Programm/communicator /opt/turbomed/Programm/
#          rsync -avu /amnt/virtwin/turbomed/Daten/Var/aWinS /opt/turbomed/Daten/Var/
#          rsync -avu /amnt/virtwin/turbomed/Daten/Var/Konnektor /opt/turbomed/Daten/Var/
#          rsync -avu /amnt/virtwin/turbomed/Daten/Var/Passwort /opt/turbomed/Daten/Var/
#          rsync -avu /amnt/virtwin/turbomed/Daten/Var/UX /opt/turbomed/Daten/Var/
        fi;
      done; # Vz in $VzLk
      [ "$verb" ]&&printf "\n${rot}Nach der Schleife Bearbeite Verzeichnis$reset\n";
    else
      [ $verb ]&&printf " fiel negativ aus.\n";
    fi; # pruefpc $wirt kurz; then
    [ "$verb" ]&&printf "\n${rot}Nach pruefpc $wirt$reset\n";
  done; # nr in $ziele
  [ "$verb" ]&&printf "\n${rot}Nach nr in $ziele$reset\n";
fi; # [ "$obmehr" -a "$buhost"/ = "$LINEINS"/ ]; then
gutenacht;
[ "$verb" ]&&printf "\n${rot} ziemlich am Schluss von $MUPR$reset\n";
EXFEST=$altEXFEST;
