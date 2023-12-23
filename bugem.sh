#!/bin/bash
# dash geht nicht: --exclude={,abc/,def/} wirkt nicht
# soll alle relevanten Datenen kopieren, aufgerufen aus bulinux.sh, butm.sh, buint.sh
#im aufrufenden Programm soll QL und buhost (z.B. durch bul1.sh) und kann ZL (je ohne Doppelpunkt) definiert werden, sonst ZL als commandline-Parameter
EXFEST=",Papierkorb/";
blau="\033[1;34m";
lila="\033[1;35m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
reset="\033[0m";

# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...")
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
ausf() {
	[ "$verb" -o "$2" ]&&{ anzeige=$(echo "$2$1$reset"|sed 's/%/%%/'); printf "$anzeige";}; # escape für %, soll kein printf-specifier sein
  if test "$3"/ = direkt/; then
    "$1";
  elif test "$3"; then 
    echo erstens: eval "$1";
    eval "$1"; 
  else 
#    ne=$(echo "$1"|sed 's/\([\]\)/\\\\\1/g;s/\(["]\)/\\\\\1/g'); # neues Eins, alle " und \ noch ein paar Mal escapen; funzt nicht
#    printf "$rot$ne$reset";
    resu=$(eval "$1"); 
  fi;
  ret=$?;
  if [ "$verb" ]; then
    printf " -> ret: $blau$ret$reset";
    if [ "$3" ]; then printf '\n'; else printf ", resu:\n$blau"; echo "$resu"|sed -e '$ a\'; printf "$reset"; fi;
  elif [ "$2" ]; then
    printf "\n";
  fi;
} # ausf

ausfd() {
  ausf "$1" "$2" direkt;
} # ausfd

# Befehlszeilenparameter auswerten
commandline() {
	while [ $# -gt 0 ]; do
   case "$1" in 
     SD=*) sdneu=2; SDQ=${1##*SD=};SD=${SDQ##*/};;
     SD) sdneu=1; SDQ=$(readlink -f $0);SDQ=${SDQ%/*}/$SD;
         [ ! -f "$SD" ]&&{ 
           printf "Option '${blau}SD$reset' angegeben, aber $blau$SD$reset nicht in "$blau$(readlink -f $0)$reset" gefunden, ${rot}breche ab$reset.\n";
           exit 3;
         };;
     -*|/*)
      para=${1#[-/]};
      case $para in
        d|-del) obdel=1;;
        e|-echt) obecht=1;;
        f|-force) obforce=1;;
        h|-h|-help|-hilfe) obhilfe=1;; # Achtung: das Fragezeichen würde expaniert
        k|-kill) obkill=1;;
        m|-mehr) obmehr=1;;
        nv|-nichtvirt) obnv=1;;
        nd|-nurdrei) nurdrei=1;;
        v|-verbose) verb=1;;
        z|-ziele) shift; ziele="$1";
                  echo "$ziele"|egrep -q "^[0-9 ]*$"||{ printf "Kann Kopierziele: $blau$ziele$reset nicht auflösen. Breche ab.\n"; exit; };;
      esac;;
     *)
#      [ "$ZL" ]&&QL=$ZL; # z.B. linux0 linux7 # The source and destination cannot both be remote.
      ZL=${1%%:*};; # z.B. linux0
   esac;
   shift;
	done;
  QmD=$QL:;QmD=${QmD#:};
  ZmD=$ZL:;ZmD=${ZmD#:};
	if [ "$verb" ]; then
    printf "Parameter: $blau-v$reset => gesprächig\n";
		printf "obecht: $blau$obecht$reset\n";
		[ $obdel ]&&printf "obdel: $blau$obdel$reset => in butm.sh rsync mit --delete aufrufen\n";
		[ $obforce ]&&printf "obforce: $blau$obforce$reset => in butm.sh und buint.sh kopiermt ohne Altersprüfung aufrufen\n";
    [ $obkill ]&&printf "obkill: $blau$obkill$reset => in butm.sh und buint.sh ggf. Turboed-Verbindungen zu Windows-Server killen zum Kopieren\n";
    [ $obmehr ]&&printf "obmehr: $blau$obmehr$reset => in buint.sh auch 2. auf linux{$ziele} und dort auf virtuelle Windows-Server kopieren\n";
    [ $obnv ]&&printf "obnv: $blau$obnv$reset => in butm.sh nicht auf virtuellen Windows-Server weiter kopieren\n"; 
		[ $sdneu ]&&printf "sdneu: $blau$sdneu$reset => Schutzdatei $SD wird verteilt\n";
		printf "SD: $blau$SD$reset\n";
		printf "SDQ: $blau$SDQ$reset\n";
		printf "ZL: $blau$ZL$reset\n";
		printf "nichtvirt: $blau$obnv$reset\n";
		[ $nurdrei ]&&printf "nurdrei: $blau$nurdrei$reset => in buint.sh nur auf Zielrechnern zwischen virt.Windows und Linux kopieren\n";
	fi;
} # commandline

#  USB:
#    QL=; 
#    ZL=;
#  weg:
#    QL=;
#    ZL=linux7
#  her:
#    QL=LINEINS
#    ZL=;
#    QVos=/ Pfad/zum/qv / # zum Kopieren der Schutzdatei
#    QVofs=/ Pfad/zum/qv[/]
#    obsub 1: qv, obsub: qv/
#    obdat 1: obsub und /Pfad/zum/qv = Datei
#    ZVos=/ Pfad/zum/zv / oder / Pfad/zum/zv/qv /, falls obsub # zum Vergleich einer Datei darin
#    ZVofs=/ Pfad/zum/zv/ oder / Pfad/zum/zv/qv, falls obdat

# ob eine Datei auf dem Zielsystem alt genug ist zum Kopieren, aufgerufen aus kopiermt: $1= Dateipfad, $2= Mindestalter [s]
# wird nicht aufgerufen, wenn nur eine Datei kopiert wird
obalt() {
	# $1 = Datei auf $QV und $ZV, deren Alter verglichen werden soll 
	# $2 = Zahl der Sekunden Altersunterschied, ab der kopiert werden soll
  # liefert 0, wenn auf Quelle vorhanden und (alt genug oder auf Ziel fehlend), sonst 1
  machssh;
  [ "$obdat" ]&&DaQ="/${QVos%/*}${1#/}"||DaQ="/$QVos/${1#/}";
  [ "$obdat" ]&&DaZ="/${ZVos%/*}${1#/}"||DaZ="/$ZVos/${1#/}";
	[ "$verb" ]&&{
		echo obalt "$1" "$2" "$3" "$4"
	  echo DaQ: $DaQ, DaZ: $DaZ
	}
  [ "$sdneu" ]&&return 0; # Altersprüfung im Modus der Schutzdateiverteilung nicht sinnvoll => hier immer weiter machen
	faq=; # <> "" = Datei fehlt auf Quelle
  # das Leerzeichen nach &1 schützt vor ambiguous redirect-Fehler
  eval "$qssh 'stat \"$DaQ\" >/dev/null 2>&1 '||{ faq=1; printf \"${blau}$DaQ ${rot}fehlt auf Quelle$reset\n\"; }"
	[ "$faq" ]&& return 1;
	ret=; # <> "" = Datei fehlt auf Ziel
  eval "$zssh 'stat \"$DaZ\" >/dev/null 2>&1 '||{ ret=0; printf \"${blau}$DaZ ${rot}fehlt auf Ziel$reset\n\"; }"
  if [ -z "$ret" ]; then
    ausf "$qssh 'date +%s -r \"$DaQ\"'"; geaenq=$resu;
    awk 'BEGIN{printf strftime("geändert Quelle: '$blau'%15s'$reset' s ('$blau'%d.%m.%Y %T'$reset' %z)\n", '$geaenq');}';
    ausf "$zssh 'date +%s -r \"$DaZ\"'"; geaenz=$resu;
    awk 'BEGIN{printf strftime("geändert   Ziel: '$blau'%15s'$reset' s ('$blau'%d.%m.%Y %T'$reset' %z)\n", '$geaenz');}';
  #	geaenq=$(expr $geaenq + 2000);
    diff=$(awk "BEGIN{print $geaenq-$geaenz+0}");
    ret=$(awk "BEGIN{print ($diff<$2);}"); # wenn richtig, liefert awk 1, sonst 0
  #  ! awk "func abs(v){return v<0?-v:v}; BEGIN{ exit abs($alterdort-$alterhier)>$2 }";
    printf "Altersdifferenz $blau $diff ";if test $ret/ = 0/; then printf ">="; else printf "<";fi; printf "$2$reset s\n";
    # wenn die Funktion 0 zurückliefert, wird in in "if obalt" verzweigt
  fi;
  return $ret;
} # obalt

# kopiere mit Test auf ausreichenden Speicher
kopiermt() { # mit test
  # $1 = Verzeichnis auf Quelle
  # $2 = Verzeichnis auf Ziel
  # $3 = excludes
  # $4 = Optionen 
	# $5 = Pfad zur Datei, die als Alterskriterium geprüft werden soll
	# $6 = Zahl der Sekunden Altersunterschied, ab der kopiert werden soll
  # $7 = ob ohne Platzprüfung
  # vorher müssen ggf. Quellrechner in $QL (z.Zt. nur: leer oder linux1) und Zielrechner in $ZL hinterlegt sein
  # P1obs=$(echo "$1"|sed 's/\\//g'); # Parameter 1 ohne backslashes

  QVofs=$(echo ${1#/}|sed 's/\([^\\]\) /\1\\ /g'); # Quellverzeichnis ohne führenden slash, mit "\ " statt " "
  QVos=${QVofs%/}; # letzten Slash entfernen
  case $QVofs in */)obsub=;;*)obsub=1;;esac;
  machssh;
  [ "$obsub" ]&&{ eval "$qssh '[ -f \"/$QVos\" ]'&&obdat=1||obdat=";}; # obdat=1 heisst, /$QVos ist eine Datei
  [ "$obsub" ]&&{ $qssh "[ -f \"/$QVos\" ]"&&obdat=1||obdat=;}; # das geht nicht mit zsh
  if [ -z "$2" -o "$2" = "..." ]; then ZVofs=${QVofs%/*}/; [ "$ZVofs" = "$QVofs/" ]&&ZVofs=""; else # letzteres für QVofs ohne /
  ZVofs=$(echo ${2#/}|sed 's/\([^\\]\) /\1\\ /g'); fi; # Zielverzeichnis ohne führenden slash, mit "\ " statt " "
  ZVos=${ZVofs%/}; ZVofs=$ZVos/; [ "$obsub" ]&&ZVos=$ZVos/${QVofs##*/};
  ZVos=${ZVos#/}; ZVofs=${ZVofs#/}; # bei QVofs ohne / noch nötig
  [ "$obdat" ]&&ZVofs=$ZVofs${QVofs##*/};
  echo "";
  echo `date +%Y:%m:%d\ %T` "vor /$QVos" >> $PROT
  printf "${blau}kopiermt$reset Q: $blau$1$reset, Z: $blau$2$reset, Ex: $blau$3$reset, Opt: $blau$4$reset, AltPrf: $blau$5$reset, >s: $blau$6$reset, oPlP: $blau$7$reset, QL: $blau$QL$reset, /QVos: /$blau$QVos$reset, QVofs: $blau$QVofs$reset, ZL: $blau$ZL$reset, ZVos: $blau$ZVos$reset, ZVofs: $blau$ZVofs$reset, obsub: $blau$obsub$reset, obdat: $blau$obdat$reset, qssh: $blau$qssh$reset, zssh: $blau$zssh$reset\n";
  [ "$QL" ]&&{ 
    echo Überprüfe $QL
#    ping -c1 -W1 "$QL">/dev/null 2>&1 && QL=192.168.178.2${QL#linux};
    if ping -c1 -W1 "$QL">/dev/null 2>&1; then printf "$blau$QL$reset anpingbar.\n"; else printf "$blau$QL$rot nicht anpingbar, verlasse Funktion$reset\n"; return;fi;
  }; 
  [ "$ZL" ]&&{ 
    echo Überprüfe $ZL
#    ping -c1 -W1 "$ZL">/dev/null 2>&1 && ZL=192.168.178.2${ZL#linux};
    if ping -c1 -W1 "$ZL">/dev/null 2>&1; then printf "$blau$ZL$reset anpingbar.\n"; else printf "$blau$ZL$rot nicht anpingbar, verlasse Funktion$reset\n"; return;fi;
  }; 
  for zute in "/$QVos" "/$ZVos"; do # zutesten
    if test "$zute/" = "/$QVos/"; then hsh="$qssh"; Lfw=$QL; else hsh="$zssh"; Lfw=$ZL; fi;
    [ "$Lfw" ]||Lfw=$buhost" (hier) ";
    echo $zute|grep '^/amnt/' >/dev/null && isamnt=1||isamnt=;
    echo $zute|grep '^/mnt/' >/dev/null && ismnt=1||ismnt=;
    if [ "$isamnt" -o "$ismnt" ]; then # wenn offenbar zu mountendes Laufwerk drin
      ok=;
      zuteh=${zute%/}; # ohne letzten slash
      testz="$zuteh";
      gpc=${zute#/mnt/}; gpc=${zute#/amnt/}; gpc=${gpc%%/*}; # virtwinx
      [ "$gpc" ]&&{
        if ping -c1 -W1 "$gpc" >/dev/null 2>&1; then ok=1; else
          ok=;
          printf "$blau$gpc$reset nicht anpingbar, versuche ihn zu starten\n";
          nr=${gpc#virtwin};
          [ $nr/ = / ]&& wirt=linux1||wirt=linux$nr;
          pruefpc $wirt kopiermt;
          ausf "$tush VBoxManage startvm Win10 --type headless";      
          for iru in $(seq 1 1 120); do 
            if ping -c1 -W1 "$gpc" >/dev/null 2>&1; then ok=1; break; fi;
          done;
          [ "$ok" ]&&printf "brauchte $blau$iru$reset Durchläufe;\n";
        fi; 
      }
      while :; do # rausfinden, ob nicht ein linker Teil des Verzeichnispfades schon gemountet ist
        [ "$testz" ]||break;
        findmnt "$testz" -n >/dev/null&&{ ok=1;break;}
        testz=${testz%/*};
      done;
      [[ $ismnt && ! $ok ]]&&while :; do # wenn nicht, dann schauen, was zu mounten ist # [ $ismnt -a ! $ok ] => !: binary operator expected
        [ "$zuteh" -a "$zuteh" != /mnt ]||break;
        if [ -d "$zuteh" ]; then # das sollte dann ein schon bestehendes Verzeichnis sein
          echo "$hsh 'mountpoint -q \"$zuteh\"'"
  #        $hsh "mountpoint -q \"$zuteh\"||mount \"$zuteh\" >/dev/null 2>&1";
          for vers in 3.11 3.11 3.02 3.02 3.0 3.0 2.1 2.1 2.0 2.0 1.0 1.0; do
           if ! $hsh "mountpoint -q \"$zuteh\""; then
             # das Leerzeichen nach &1 schützt vor ambiguous redirect-Fehler
             ausf "$hsh \"mount '$zuteh' -t cifs -o nofail,vers=$vers,credentials=/home/schade/.wincredentials >/dev/null 2>&1 \"" $blau
             # das würde gehen:
#            ausf "$hsh \"mount $zuteh -t cifs -o nofail,vers=$vers,credentials=/home/schade/.wincredentials >/dev/null 2>&1 \"" $blau
             # hier geht gar nix:
#             ausf "$hsh \"mount \\\\\"$zuteh\\\\\" -t cifs -o nofail,vers=$vers,credentials=/home/schade/.wincredentials >/dev/null 2>&1 \"" $blau
             echo "";
           else
      #       printf " ${blau}$cifs$reset gemountet!\n"
             break;
           fi;
          done;
          if $hsh "mountpoint -q \"$zuteh\""; then ok=1; break; fi; # wenn eins gemountet is, o.k.
        fi;
        zuteh=${zuteh%/*}; # die Unterverzeichnisse raufhangeln
      done;
      [ "$ok" ]||{
        printf "Laufwerk $blau$zute$reset auf $blau$Lfw$reset weder gemountet noch zumounten, breche ab!\n";
        return 7;
      }
    fi;
  done;

#  case $QVos in */)ZVos=${ZVos%/};;*)ZVos=${ZVos%/}/${QVos##*/};QVos=${QVos%/};;esac;
#  QVos=${QVofs%/}; # Quellverzeichnis (ohne abschließenden slash)
#  [ "$2" = ... ]&&case $QVofs in */)ZVK=$QVofs;;*)ZVK=${QVos%/*};;esac||ZVK=$(echo ${2#/}|sed 's/\([^\\]\) /\1\\ /g'); # Ziel-Verzeichnis kurz; rsync-Grammatik berücksichtigen
# Zielverzeichnis: wegen der rsync-Grammatik das letzte Verzeichnis von $1 noch an $2 anhängen, falls kein / am Schluss; erstes / streichen
#  ZV=$ZVK;
#  case $QVofs in */);;*)ZV=${ZV%/}/$(echo ${1##*/}|sed 's/\([^\\]\) /\1\\ /g');ZV=${ZV#/};;esac;
# falls Alterskriterium nicht erfuellt, dann abbrechen	

  obaltgepr=; # ob Alter geprüft
  [ "$5" -a "$6" -a -z "$obdat" ]&&{
   obalt "$5" "$6"&&obaltgepr=1||return 1;
   [ "$faq" ]&&return 2;
	}
  EXREST=$EXGES;
  EXAKT=;
  while [ "$EXREST" ]; do
    EXHIER=$(readlink -f "${EXREST##*,}"); EXREST=${EXREST%,*};
    case "$EXHIER" in $(readlink -f "/$QVofs")*) EXAKT="$EXAKT,"${EXHIER%/}"/";; esac;
  done;
  EX="$3$EXAKT$EXFEST";
  [ "$verb" ]&&printf "EX: $blau$EX$reset\n"
# falls nur die Schutzdatei überall etabliert werden soll
# beim Kopieren einzelner Dateien hierauf verzichten
  [ "$sdneu" -a ! "$obdat" ]&&{
      # scp wird hier auch lokal verwendet, da es besser mit "\ " umgehen kann als cp
      if [ -z "$QL" ]; then
        tue="cp -a \"$SDQ\" \"/$QVos/$SD\"";
      else
        tue="scp -p \"$SDQ\" \"$QL:/$QVos/$SD\"";
      fi;
      if [ -z "$ZL" ]; then
        tu2="mkdir -p /$ZVos; cp -a \"$SDQ\" \"/$ZVos/$SD\"";
      else
        tu2="$zssh 'mkdir -p /$ZVos'; scp -p \"$SDQ\" \"$ZL:/$ZVos/$SD\"";
      fi;
      if [ "$obecht" ]; then
        ausf "$tue";
        ausf "$tu2";
      else
        printf "$dblau$tue$reset\n";
        printf "$dblau$tu2$reset\n";
      fi;
    return 0;
  }
# Schutzdatei ggf. vergleichen, beim Kopieren einzelner Dateien hierauf verzichten
  [ "$SD" -a ! "$obdat" ]&&{
    if [ "$QL" ]; then
      PZiel=$QL;
      diffbef="ssh $QL cat \"/$QVos/$SD\" 2>/dev/null| diff - /$ZVos/$SD 2>/dev/null";
    elif [ "$ZL" ]; then
      PZiel=$ZL;
      diffbef="ssh $ZL cat \"/$ZVos/$SD\" 2>/dev/null| diff - /$QVos/$SD 2>/dev/null";
    else
      PZiel=;
      diffbef="diff /$QVos/$SD /$ZVos/$SD 2>/dev/null";
    fi;
    AND="$QL";[ "$AND" ]||AND=$ZL;
    [ "$PZiel" ]&&if ! ping -c1 -W100 "$AND" >/dev/null 2>&1; then 
      printf "$rot$AND$reset nicht anpingbar! Kehre zurueck!\n";
      return 1;
    fi;
#    printf "${blau}$diffbef$reset\n"
    ausf "$diffbef";
    if [ $ret/ != 0/ ]; then
      printf "Liebe Praxis,\nbeim Versuch der Sicherheitskopie fand sich ein Unterschied zwischen\n${Q:-$LINEINS:}$SDHIER und\n$ZL$SDDORT.\nDer Fehler trat auf beim Befehl:\n$diffbef\nDa so etwas auch durch Ransomeware verursacht werden könnte, wurde die Sicherheitskopie für dieses Verzeichnis unterlassen.\nBitte den Systemadiminstrator verständigen!\nMit besten Grüßen, Ihr Linuxrechner"|mail -s "Achtung, Sicherheitswarnung von ${QL:-$LINEINS:} zu /$QVos vor Kopie auf $ZL!" diabetologie@dachau-mail.de
      printf "${rot}keine Übereinstimmung bei \"$SD\"!$reset\n"
      return 1;
    fi
  }
  if [ "$7" -o \( -z "$QL" -a -z "$ZL" \) ]; then
  # keine Platzprüfung
    rest=1;
  else
    # Platz ausrechnen:
#    ausf "$zssh 'df /${ZVos%%/*}|sed -n \"/\//s/[^ ]* *[^ ]* *[^ ]* *\([^ ]*\).*/\1/p\"'"; rest=${resu:-0}; # die vierte Spalte der df-Ausgabe
    ausf "$zssh 'df /${ZVos%%/*}'| awk '/\//{print \$4*1}'"; rest=${resu:-0}; # *1024 => Bytes
    echo $rest|LC_ALL=de_DE.UTF-8 awk '{printf "verfügbar           : '$blau'%'"'"'15d'$reset' kB\n", $1}';
    if test $rest -gt 0; then
      # je nach dem, von wo aus der Befehl aufgerufen wird und ob es sich um ein Verzeichnis oder eine Datei handelt
      ausf "$zssh 'test -d \"/$ZVos\"&&{ du /$ZVos -d0;:;}||{ stat /$ZVos -c %s||echo 1;}'|awk -F $'\t' '{print \$1*1}'"; schonda=${resu:-0};
      echo $schonda|LC_ALL=de_DE.UTF-8 awk '{printf "schonda             : '$blau'%'"'"'15d'$reset' kB\n", $1}';
      ausf "$qssh 'test -f \"/$QVos\"&&{ stat /$QVos -c %s||echo 0;:;}||du /$QVos -d0;'|awk '{print \$1*1}'"; zukop=${resu:-0}; # mit doppelten " ging's nicht von beiden Seiten
      echo $zukop|LC_ALL=de_DE.UTF-8 awk '{printf "zukopieren          : '$blau'%'"'"'15d'$reset' kB\n", $1}';
      rest=$(expr $rest - $zukop + $schonda);
      [ "$EX" ]&&for E in $(echo $EX|sed 's/ //g;s/,/ /g');do
         E=$(echo $E|sed 's/\\/\\ /g');
         case $E in /*) zQ=/${E#/};zZ=$zQ;;*) zQ=/$QVos/${E#/};zZ=/$ZVos/${E#/};;esac;
         echo E: $E, QVos: $QVos, ZVos: $ZVos, zZ: $zZ, zQ: $zQ 
         [ "$verb" ]&&printf "E: $blau$E$reset\n";
         [ "$verb" ]&&printf "ZVos: $blau$ZVos$reset\n";
         ausf "$zssh 'test -d \"$zZ\" && du $zZ -d0'|awk '{print \$1*1}'"; papz=${resu:-0};
         ausf "$qssh 'test -d \"$zQ\" && du $zQ -d0'|awk '{print \$1*1}'"; papq=${resu:-0};
         rest=$(expr $rest - $papz + $papq);
      done;
      echo $rest|LC_ALL=de_DE.UTF-8 awk '{printf "Nach Kopie verfügbar: '$blau'%'"'"'15d'$reset' kB\n", $1}';
    fi;
  fi; # if [ "$7" ]
  if test $rest -gt 0; then
		case $QVos in *var/lib/mysql*)
			printf "stoppe mysql auf $blau$ZL$reset\n";
			ausf "$zssh 'systemctl stop mysql'";
      ausf "$zssh 'pkill -9 mysqld'";
			echo "Fertig mit Stoppen von mysql";;
	  esac;
    # die Excludes funktionieren so unter bash und zsh, aber nicht unter dash
    [ "$QL" -o "$ZL" ]&&ergae="--rsync-path='$kopbef'"||ergae=;
    Quelle=$QmD/$QVofs;[ "$QL" ]&&Quelle=\"$Quelle\";
    altverb=$verb;
    verb=1;
    [ "$EX" ]&&AUSSCHL=" --exclude={""$EX""}"||AUSSCHL=;
#    QVos=/ Pfad/zum/qv / # zum Kopieren der Schutzdatei
#    QVofs=/ Pfad/zum/qv[/]
#    obsub 1: qv, obsub: qv/
#    obdat 1: obsub und /Pfad/zum/qv = Datei
#    ZVos=/ Pfad/zum/zv / oder / Pfad/zum/zv/qv /, falls obsub # zum Vergleich einer Datei darin
#    ZVofs=/ Pfad/zum/zv/ oder / Pfad/zum/zv/qv, falls obdat
    [ $obaltgepr ]&&attr="av"||attr="avu";
    if [ "$obecht" ]; then
      ausf "$kopbef $Quelle \"$ZmD/$ZVofs\" $4 -$attr $ergae$AUSSCHL" $dblau;
    else
      printf "Befehl wäre: $dblau$kopbef $Quelle \"$ZmD/$ZVofs\" $4 -$attr $ergae$AUSSCHL$reset\n";
    fi;
    verb=$altverb;
		ausf "$qssh 'test -d \"/$(echo $QVos|sed s/\\\\//g)\"'";[ $ret/ = 0/ ]&&EXGES=${EXGES},/$QVos/;
    [ "$verb" ]&&printf "EXGES: $blau$EXGES$reset\n";
		case $QVos in *var/lib/mysql*)
			echo starte mysql auf $ZL;
			ausf "$zssh 'systemctl start mysql'";
			echo "Fertig mit Starten von mysql";;
	  esac;
		return 0;
  else
    printf "${rot}Kopieren nicht begonnen${reset}, Speicherreserve: $blau$rest$reset\n";
		return 1;
  fi;
} # kopiermt

kopieros() {
  kopiermt root/$1 "root" "" "--exclude='.*.swp'" "" "" 1
}

kopieretc() {
  kopiermt etc/$1 "etc/" "" "" "" "" 1
}

pruefpc() {
  [ $verb ]&&printf "${blau}pruefpc()$reset \"$1\", aufgerufen aus \"$2\"\n";
  [ "$1" ]||break;
  for iru in 1 2; do
    [ $verb ]&&printf "iru: $iru, vor ping -c1 -W10 \"$1\" \>/dev/null 2\>\&1\n"
    if ping -c1 -W10 "$1" >/dev/null 2>&1; then break; fi;
    [ $verb ]&&printf "iru: $iru, nach ping -c1 -W10 \"$1\" \>/dev/null 2\>\&1\n"
    if [ $iru = 1 -a ! $2/ = kurz/ ]; then
      transverb=; [ $verb ]&&transverb=-v;
      weckalle.sh "$1" -grue $transverb; # muss noch klären, warum er ohne grue linux8 nicht weckt
      [ $verb ]&&printf "Nach weckalle.sh\n";
      for ii in $(seq 1 1 2); do # 100
        [ $verb ]&&printf "ii: $ii, vor ping -c1 -W10 \"$1\" \>/dev/null 2\>\&1\n"
        ping -c1 -W10 "$1" >/dev/null 2>&1&&{
        [ $verb ]&&printf "nach erfolgreichem ping -c1 -W10 \"$1\" \>/dev/null 2\>\&1\n"
        [ $gewdat ]||gewdat=${MUPR%/*}/geweckt$((1 + $RANDOM % 100000))
        printf "${blau}gewdat: ${rot}$gewdat$reset\n";
        printf "füge $1 hinzu\n";
        cat $gewdat;
         if [ -f "$gewdat" ]; then 
           cat $gewdat|grep -q "$1"||printf "$1 " >>$gewdat;
         else
           printf "$1 " >$gewdat;
         fi;
         break;
        }
        [ $verb ]&&printf "ii: $ii, nach erfolglosem ping -c1 -W10 \"$1\" \>/dev/null 2\>\&1\n"
      done;
      [ $verb ]&&printf "nach for ii in \$(seq 1 1 2)\n";
      [ $verb ]&&printf "nach for ii in \$(seq 1 1 2)\n";
#      sleep 10;
      [ "$verb" ]&&printf "${lila}gewdat: ${blau}%s$reset\n" "$gewdat";
      [ "$verb" ]&&{ gdi=;[ $gewdat ]&&gdi="$(cat $gedat)"; printf "${lila}gewdat: ${blau}%s$reset\n" "$gdi";};
      [ $verb ]&&printf "nach for ii in \$(seq 1 1 2)\n";
    else
     printf "$1 nicht erreichbar";[ ! $2/ = kurz/ ]&&printf "und nicht weckbar.";printf " Lasse ihn aus.\n";
     return 1;
    fi;
    [ $verb ]&&printf "nach if \[ \$iru\n";
  done;
  [ $verb ]&&printf "Ende ${blau}pruefpc()$reset \"$1\", aufgerufen aus \"$2\"\n";
} # pruefpc

gutenacht() {
  [ $verb ]&&printf "${blau}gutenacht()$reset\n";
  if [ "$gewdat" -a -f "$gewdat" ]; then 
    [ "$verb" ]&&printf "${rot}gewdat: ${blau}%s$reset\n ${blau}%s$reset\n" "$gewdat" "$(cat "$gewdat")";
    for pc in $(cat "$gewdat");do  
     printf "$rot$Fahre PC $blau$pc$rot herunter!$reset\n";
     ssh $pc shutdown now;
    done;
    rm "$gewdat";
  fi;
} # gutenacht

machssh() {
[ "$QL" ]&&{ qssh="ssh $QL";pruefpc "$QL" "machssh";:;}||qssh="sh -c";
[ "$ZL" ]&&{ zssh="ssh $ZL";pruefpc "$ZL" "machssh";:;}||zssh="sh -c";
# [ "$QL" ]&&qssh="ssh $QL"||qssh="sh -c";
# [ "$ZL" ]&&zssh="ssh $ZL"||zssh="sh -c";
#  [ "$verb" ]&&printf "qssh: \'$blau$qssh$reset\', zssh: \'$blau$zssh$reset\'\n";
}

# hier geht's los
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
reset="\033[0m";
kopbef="ionice -c3 nice -n19 rsync";
SD="Schutzdatei_bitte_belassen.doc"
LINEINS=linux1;
verb=;
obecht=;
obdel=;
obforce=;
obkill=;
obmehr=;
obnv=;
obhilfe=;
sdneu=;
nurdrei=;
commandline "$@"; # alle Befehlszeilenparameter übergeben, ZL aus commandline festlegen
case $0 in bu*)
if [ \( "${0##*/}" != buint.sh -a "${0##*/}" != budbaus.sh -a "$buhost"/ = "$LINEINS"/ -a -z "$ZL" \) -o "$obhilfe" ]; then 
  printf "%b\n" \
  "$blau$0$reset, Syntax: $blau"$(basename $0)" <-d/-e/-f/-k/-m/-nv/-z\"\"> <zielhost> <SD=/Pfad/zur/Schutzdatei>$reset" \
  " ${blau}-d$reset bewirkt auf dem Zielrechner Loeschen der auf dem Quellrechner nicht vorhandenen Dateien" \
  " ${blau}SD[=/Pfad/zur/Schutzdatei]${reset} bewirkt Kopieren jener Datei auf alle Quellen und Ziele und anschließenden Vergleich dieser Dateien vor jedem Kopiervorgang" \
  " ${blau}-e${reset} bewirkt echten Lauf" \
  " ${blau}-f${reset} bewirkt, dass auch kopiert wird, wenn die Testdatei ${blau}objects.dat${reset} nicht aelter ist" \
  " ${blau}-h${reset} bewirkt das Anzeigen dieser Hilfe" \
  " ${blau}-k${reset} bewirkt, dass ggf. die virtuellen Windows-Server neu gestartet werden, wenn gesperrt";
    if [ $(basename $0) == buint.sh ]; then
  printf "%b\n" \
  " ${blau}-m${reset} bewirkt, dass noch mehr getan wird (Dateien auf ${blau}/opt${reset} auf andere Server kopiert und von dort aus auf die virtuallen Windowsserver)" \
  " ${blau}-nv${reset} bewirkt, dass die Dateien auf dem virtuellen Windows-Server nicht mit kopiert werden." \
  " ${blau}-z|--zielev${reset} verwendet den nächsten Parameter zur Bestimmung der Kopierziele, z.B. '0 7' => linux0, linux7";
    fi;
  printf "%b\n" \
  " ${blau}-v${reset} bewirkt gesprächigere Ausgabe";
  exit;
fi;;
esac;

[ "$sdneu"/ = 2/ ]&&{
  [ "$SD" -a ! -f "$SDQ" ]&&{ printf "$rot$SDQ$reset nicht gefunden. Breche ab.\n"; exit 1; }
  sed -i.bak "/^SD=/c\\SD=\"$SD\"" "$0"
  echo SD: $SD;
  echo SDQ: $SDQ;
  [ "$SD" ]||exit 0;
}

PROT=/var/log/$(echo $0|sed 's:.*/::;s:\..*::')prot.txt;
[ "$verb" ]&&printf "Prot: $blau$PROT$reset\n"
[ "$obdel" ]&&OBDEL="--delete"||OBDEL=;
[ "$verb" ]&&echo QL: $QL, ZL: $ZL;
# [ "$verb" ]&&echo `date +%Y:%m:%d\ %T` "vor chown" > $PROT
chown root:root -R /root/.ssh
chmod 600 -R /root/.ssh
