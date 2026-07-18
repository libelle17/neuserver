#!/bin/bash
# buint.sh - "Backup Intern": zentrales Turbomed-Kopierskript rund um den
# Windows-Terminalserver "wser"/wexp.fritz.box, komplexer Nachbar von
# butm.sh/bumo.sh. dash geht nicht: --exclude={,abc/,def/} wirkt nicht;
# zsh geht nicht, wegen der fehlenden Aufteilung der Variablen mit
# Leerzeichen. Soll alle sehr relevanten Daten kopieren, fuer z.B.
# halbstündlichen Gebrauch. Wenn es auf dem Hauptserver wexp.fritz.box das
# Verzeichnis /opt/turbomed gibt, so wird auf jedem Server /opt/turbomed
# als Quelle verwendet, sonst /amnt/virtwin/turbomed.
#
# Ablauf (Reihenfolge je nach $obvirt, per testobvirt() aus bugem.sh
# ermittelt - 0/2: /opt/turbomed existiert (ggf. als -wser-Variante), 1:
# nur virtuell erreichbar):
#   0. kopierwser(): kopiert direkt zwischen /opt/turbomed und dem
#      Windows-Server "wser" (per SSH+WSL-rsync, "sturm@wser:/mnt/c/
#      turbomed/..."), inklusive Prüfung, ob Turbomeds objects.idx gerade
#      gesperrt ist (per angehängtem "call"-Trick über cmd.exe), und bei
#      -kill notfalls Beenden des FastObjects-Dienstes bzw. Neustart der
#      lokalen VM, um die Sperre loszuwerden.
#   1. Interner Kopierdurchlauf zwischen /opt/turbomed und dem zu diesem
#      Host gehörigen virtuellen PC ($gpc, aus virtnamen.sh) per
#      kopiermt() (aus bugem.sh), Richtung ebenfalls von $obvirt abhängig.
#   2. Nur wenn mit -m ("mehr", $obmehr) aufgerufen UND auf $LINEINS: ruft
#      für jede Nummer in $ziele (Vorgabe "0 3 7 8") butm.sh mit -nv auf,
#      um von wexp.fritz.box weiter auf die jeweiligen (nicht-virtuellen)
#      Reserve-Linux-Server zu kopieren.
#   3. Danach (ebenfalls nur bei -m) für dieselben $ziele: prüft/weckt bei
#      Bedarf deren virtuelle PCs, mountet deren CIFS-Freigabe (mit
#      SMB-Versions-Fallback wie in weckalle.sh) und ruft dort per SSH
#      rekursiv "buint.sh -e" auf, damit der jeweilige Reserve-Server sich
#      selbst um seinen eigenen virtuellen PC kümmert (der "$dreieck"-Zweig
#      davor ist laut eigenem Kommentar im Code nie erreichbar - die
#      Variable wird nirgends gesetzt).
# Aufruf: buint.sh [bugem.sh-Parameter, u.a. -e, -m/-mehr, -k/-kill, -z
# "<nummern>"].
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost=linux1 festlegen
# ziele="0 3 7 8"; # Vorgaben für Ziel-Servernummern: linux1ur, linux3 usw., abwandelbar durch Befehlszeilenparameter -z
ziele="0 3 7 8"; # Vorgaben für Ziel-Servernummern: linux1ur, linux3 usw., abwandelbar durch Befehlszeilenparameter -z
ZL=; # dann werden die cifs-Laufwerke verwendet
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
# nurdrei=1;
# nurzweidrei=1;
[ "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;}
wirt=$buhost;
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
# gpc= z.B. virtwin, virtwin0, virtwin3, virtwin7, virtwin8, gast= Win10
VzLg="PraxisDB StammDB DruckDB Dictionary Vorlagen Formulare KVDT Dokumente Daten labor LaborStaber"; # VzL groß
VzLk="PraxisDB StammDB DruckDB Dictionary"; # VzL klein

kopierwser() {
  if [ ! "$nurdrei" -a ! "$nurzweidrei" ]; then
    diensttot=;
    for iru in 1 2 3; do
      [ "$verb" ]&&printf "Prüfe die Offenheit von $mudat auf $blau$gpc$reset\n";
      if ssh administrator@wser cmd /c "(>>c:\turbomed\StammDB\objects.idx (call ) )&&exit||exit /b 1" 2>/dev/nul; then offen=ja; else offen=nein; fi;
      [ "$verb" ]&&{ printf "iru: $iru; offen: $blau$offen$reset\n"; };
      if [ "$offen" = ja ]; then
        break;
      else
        if [ "$obkill" ]; then
          if [ "$iru" = 1 ]; then
            ausf "$tush 'mv /$ot/lauf /$ot/lau  2>/dev/null||touch /$ot/lau'&&sleep 80s";
          else
            diensttot=1;
            ssh administrator@wser taskkill /im FastObjectsServer64.exe /f
          fi;
        else
          printf "$blau$mudat$reset gesperrt. $blau-k$reset nicht angegeben. Kann nicht kopieren.\n";
          break;
        fi; #  [ "$obkill" ]
      fi;
    done;
    if [ "$offen" = ja ]; then
     for Vz in $VzLk; do # kleine Liste
      [ "$obforce" ]&&testdt=||case $Vz in PraxisDB|StammDB|DruckDB)testdt="objects.dat";;Dictionary)testdt="_objects.dat";;*)testdt=;;esac;
      case $Vz in Vorlagen|Formulare|KVDT|Dokumente|Daten|labor|LaborStaber)obOBDEL=;;*)obOBDEL="--delete";;esac; 
        # obOBDEL=$OBDEL, wenn Benutzer es einstellen können soll
      uz=$Vz; [ "$Vz" = PraxisDB ]&&{ case $obvirt in 1) uz=$resD;; 2) uz=$wserD;; esac;};
      uq=$Vz;
      if [ $obvirt = 2 ]; then
        ausf "ssh sturm@wser del c:\\turbomed\\$uq\\.objects* 2>nul"; # Reste alter Kopierversuche löschen
        ausf "rsync -avu -e ssh  --rsync-path='wsl rsync' sturm@wser:/mnt/c/turbomed/$uq/ /opt/turbomed/$uz/ $obOBDEL"; # -P hat keinen Sinn
        ausf "rsync -avu -e ssh  --rsync-path='wsl rsync' sturm@wser:/mnt/c/turbomed/Daten/Var/earztbrief/ /opt/turbomed/Daten/Var/earztbrief/ $obOBDEL"; # -P hat keinen Sinn
      else # $obvirt = 0 -o $obvirt = 1
        ausf "rm -rf /opt/turbomed/$uz/.objects*"; # Reste alter Kopierversuche löschen
        ausf "rsync -avu -e ssh  --rsync-path='wsl rsync' /opt/turbomed/$uz/ sturm@wser:/mnt/c/turbomed/$uq/ $obOBDEL"; # -P hat keinen Sinn
      fi; # obvirt = 2 else

        # hier sind immer $wirt und $ZL leer
#          kopiermt "$ur/$uq/" "$hin/$uz" "" "$obOBDEL" "$testdt" "1800" 1; # ohne --iconv
     done;
    fi;
    if [ "$diensttot" ]; then
#     ssh administrator@wser sc start "Fastobjects server (x64) 12.0" # ging nicht
     ssh administrator@wser powershell start-service -name "FastObjects*"
    fi;
  fi;
} # kopierwser


testobvirt;
if [ $obvirt = 0 -o $obvirt = 2 ]; then # wenn es auf wexp.fritz.box /opt/turbomed/PraxisDB gibt oder PraxisDB-wser
  VzL="$VzLg";
  ur=$ot # opt/turbomed
  hin=amnt/$gpc/turbomed;
  text="von $buhost nach $gpc"
  if [ $obvirt = 0 ]; then
    if [ "$buhost"/ != "$LINEINS"/ -a ! -d "$otP" ]; then
      if [ -d "$otr" ]; then
        ausf "mv $otr $otP" $blau; # # dann ggf. die linux-Datenbank umbenennen
      elif [ -d "$otw" ]; then
        ausf "mv $otw $otP" $blau; # # dann ggf. die linux-Datenbank umbenennen
      fi;
    fi;
    tex2="von $buhost nach wser";
  else # $obvirt = 2
    if [ "$buhost"/ != "$LINEINS"/ -a ! -d "$otw" ]; then
      if [ -d "$otr" ]; then
        ausf "mv $otr $otw" $blau; # # dann ggf. die linux-Datenbank umbenennen
      elif [ -d "$otP" ]; then
        ausf "mv $otP $otw" $blau; # # dann ggf. die linux-Datenbank umbenennen
      fi;
    fi;
    tex2="von wser nach $buhost";
  fi;
else  # $obvirt = 1
  VzL="$VzLk";
  ur=amnt/$gpc/turbomed; 
  hin=$ot;
  if [ "$buhost"/ != "$LINEINS"/ -a ! -d "$otr" ]; then
    if [ -d "$otP" ]; then
      ausf "mv $otP $otr" $blau; # # dann ggf. die linux-Datenbank umbenennen
    elif [ -d "$otw" ]; then
      ausf "mv $otw $otr" $blau; # # dann ggf. die linux-Datenbank umbenennen
    fi;
  fi;
  text="von $gpc nach $buhost"
  tex2="von $buhost nach wser";
fi;
[ "$verb" ]&&printf "obsh: ${blau}$obsh$reset\n";
[ "$verb" ]&&printf "obvirt: ${blau}$obvirt$reset\n";
mudat="c:\\\turbomed\\StammDB\\objects.idx";
altEXFEST=$EXFEST;EXFEST=; # keine festen Ausnahmen in kompiermt
if [ -z "$nurdrei" -a -z "$nurzweidrei" ]; then
  if [ $obvirt = 0 -o $obvirt = 2 ]; then
    printf "${lila}0. $tex2 kopieren\n${reset}";
    kopierwser;
  fi;
  printf "${lila}1. intern $text kopieren\n${reset}";
# Kopieren ohne cifs würde gehen mit:
# rsync -avPu -e ssh  --rsync-path='wsl rsync' sturm@amd:/mnt/c/turbomed/StammDB ./StammDB_2
# auf windows server 2019:
# https://github.com/yosukes-dev/FedoraWSL
  for iru in 1 2 3; do
    [ "$verb" ]&&printf "Prüfe die Offenheit von $mudat auf $blau$gpc$reset\n";
    if ssh administrator@$gpc cmd /c "(>>c:\turbomed\StammDB\objects.idx (call ) )&&exit||exit /b 1" 2>/dev/nul; then offen=ja; else offen=nein; fi;
    [ "$verb" ]&&{ printf "iru: $iru; offen: $blau$offen$reset\n"; };
    if [ "$offen" = ja ]; then
      break;
    else
      if [ "$obkill" ]; then
        if [ "$iru" = 1 ]; then
          ausf "$tush 'mv /$ot/lauf /$ot/lau  2>/dev/null||touch /$ot/lau'&&sleep 80s";
        else
          VBoxManage controlvm Win10 poweroff; VBoxManage startvm Win10 --type headless;
        fi;
      else
        printf "$blau$mudat$reset gesperrt. $blau-k$reset nicht angegeben. Kann nicht kopieren.\n";
        break;
      fi; #  [ "$obkill" ]
    fi;
  done;
  if [ "$offen" = ja ]; then
   for Vz in $VzL; do
    [ "$obforce" ]&&testdt=||case $Vz in PraxisDB|StammDB|DruckDB)testdt="objects.dat";;Dictionary)testdt="_objects.dat";;*)testdt=;;esac;
    case $Vz in Vorlagen|Formulare|KVDT|Dokumente|Daten|labor|LaborStaber)obOBDEL=;;*)obOBDEL="--delete";;esac; 
      # obOBDEL=$OBDEL, wenn Benutzer es einstellen können soll
    uq=$Vz; [ "$Vz" = PraxisDB ]&&{ case $obvirt in 2) uq=$wserD;; esac;};
    uz=$Vz; [ "$Vz" = PraxisDB ]&&{ case $obvirt in 1) uz=$resD;; esac;};
    ausf "rm -rf /$hin/$uz/.objects*"; # Reste alter Kopierversuche löschen
    if [ ! "$nurdrei" -a ! "$nurzweidrei" ]; then
      # hier sind immer $wirt und $ZL leer
      kopiermt "$ur/$uq/" "$hin/$uz" "" "$obOBDEL" "$testdt" "1800" 1; # ohne --iconv
    fi;
   done;
  fi;
  # [ "$offen" = nein -o ! "$verb" ]&&echo ""; # echo "neue Zeile 2";
  if [ $obvirt = 1 ]; then
    printf "${lila}1.5. $tex2 kopieren\n${reset}";
    kopierwser;
  fi;
  [ "$obkill" ]&&{ mv /$ot/lau /$ot/lauf 2>/dev/null||touch /$ot/lauf;} # zurückbenennen, damit Turbomed wieder starten kann
fi;

if [ "$obmehr" -a "$buhost" = "$LINEINS" ]; then
  if ! [ "$nurdrei" ]; then
    printf "${lila}2. butm aufrufen, um von wexp.fritz.box nach linux{$ziele} zu kopieren${reset}\n";
# 2. wenn mehr, dann von hier aus auf die anderen nicht-virtuellen Server kopieren
    for ziel in $ziele; do
      [ "$obecht" ]&&echtpar=" -e"||echtpar=;
      [ "$verb" ]&&verbpar=" -v"||verbpar=;
#      echo ${MUPR%/*}/butm.sh linux$ziel -nv$echtpar$verbpar;
      ausf "${MUPR%/*}/butm.sh linux$ziel -nv$echtpar$verbpar -mz $maxz" "" direkt;
    done;
  fi; # nurdrei

  printf "\n${lila}3. intern von linux{$ziele} nach virtwin{$ziele} kopieren${reset}\n";
  # 3. wenn mehr, dann (von hier aus über ssh) den anderen nicht-virtuellen auf die anderen virtuellen Server kopieren
  ZL=;
  for nr in $ziele; do
    wirt=linux$nr;
    [ $verb ]&&printf "\nPrüfe PC ${blau}$wirt$reset ...";
    if pruefpc $wirt; then
      echo "Nach Pruefpc, zur zum Finden der freien Zeile"
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
        HOST=$(hostname);HOST=${HOST%%.*}; # wexp.fritz.box usw.
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
          printf "$lila$gpc$reset, wirt: $lila$wirt$reset:\n" # , cifs: $lila$cifs$reset:\n";
          for vers in 3.11 3.11 3.02 3.02 3.0 3.0 2.1 2.1 2.0 2.0 1.0 1.0; do
            if ! mountpoint -q $cifs; then
              ausf "mount //$gpc/Turbomed $cifs -t cifs -o nofail,vers=$vers,credentials=/home/schade/.wincredentials >/dev/null 2>&1 " $blau
            else
       #       printf " ${blau}$cifs$reset gemountet!\n"
              break;
            fi;
          done;
        fi; # [ ! "$ok" ]; then else
        if mountpoint -q $cifs; then
          printf "$blau$cifs$reset gemountet.\n"; 
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
        uz=$Vz; # [ "$Vz" = PraxisDB ]&&{ case $obvirt in 1) uz=$resD;; 2) uz=$wserD;; esac;}; # auskommentiert 15.1.23
        hin=amnt/$gpc/turbomed;
        hres=amnt/${gpc/virtwin/vw}/turbomed; # vw0
        ausf "rm -rf /$hin/$uq/.objects*"; # Reste alter Kopierversuche löschen
        if [ $dreieck ]; then # kommt sonst nirgends vor
          # wirt ist linux$nr, ZL ist leer, würde hierher auf das cifs-Laufwerk kopiert
          kopiermt "$ot/$uz/" "$hin/$uq" "" "$obOBDEL" "$testdt" "1800" 1; # ohne --iconv
        else
          # kopiert auf wirt von dort auf das dortige cifs-Laufwerk
#          echo "vor ssh $wirt 'zl=/$hin;mkdir -p \$zl;mountpoint -q \$zl||mount \$zl; mountpoint -q \$zl&&rsync -avu /$ot/$uz/ \$zl/$uq/' ";
#          ausf "ssh $wirt 'for sv in \"$hin\" \"$hres\"; do zl=/\$sv;mkdir -p \$zl;mountpoint -q \$zl||mount \$zl; mountpoint -q \$zl&&{ rsync -avu /$ot/$uz/ \$zl/$uq/;break;}; done;'" $blau;
          ausf "ssh $wirt 'buint.sh -e'" $blau;
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
[ "$verb" ]&&printf "am Schluss von $blau$MUPR$reset\n";
EXFEST=$altEXFEST;
