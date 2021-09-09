#!/bin/zsh
# soll alle relevanten Datenen kopieren, aufgerufen aus bulinux.sh, butm.sh

# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...")
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
ausf() {
	[ "$verb" -o "$2" ]&&{ anzeige=$(echo "$2$1$reset\n"|sed 's/%/%%/'); printf "$anzeige";}; # escape für %, soll kein printf-specifier sein
	if test "$3"; then 
    eval "$1"; 
  else 
    resu=$(eval "$1"); 
  fi;
  ret=$?;
  [ "$verb" ]&&{
    printf "ret: $blau$ret$reset"
    [ "$3" ]||printf ", resu: \"$blau$resu$reset\"";
    printf "\n";
  }
} # ausf

ausfd() {
  ausf "$1" "$2" direkt;
} # ausfd

# Befehlszeilenparameter auswerten
commandline() {
	while [ $# -gt 0 ]; do
   case "$1" in 
     SD=*) sdneu=1;SDQ=${1##*SD=};SD=${1##*/};;
     -*|/*)
      para=$(echo "$1"|sed 's;^[-/];;');
      case $para in
        v|-verbose) verb=1;;
        d) obdel=1;;
      esac;
      [ "$verb" = 1 ]&&printf "Parameter: $blau-v$reset => gesprächig\n";;
     *)
      ZoD=${1%%:*};; # z.B. linux0
   esac;
   shift;
	done;
	if [ "$verb" ]; then
		printf "obdel: $blau$obdel$reset\n";
		printf "sdneu: $blau$sdneu$reset\n";
		printf "SD: $blau$SD$reset\n";
		printf "ZoD: $blau$ZoD$reset\n";
	fi;
} # commandline


# ob eine Datei auf dem Zielsystem alt genug ist zum Kopieren, aufgerufen aus kopiermt: $1= Dateipfad, $2= Mindestalter [s]
obalt() {
	# $1 = Datei auf $QV und $ZV, deren Alter verglichen werden soll 
	# $2 = Zahl der Sekunden Altersunterschied, ab der kopiert werden soll
  DaQ="/$QV/${1#/}";
  DaZ="/$ZV/${1#/}";
  [ "$sdneu" ]&&return 0; # Altersprüfung im Modus der Schutzdateiverteilung nicht sinnvoll => hier immer weiter machen
	faq=; # <> "" = Datei fehlt auf Quelle
  [ "$USB" -o "$ZL" -o $ANDERER/ = localhost/ ]&&obssh=||obssh="ssh $ANDERER";
  eval "$obssh stat \"$DaQ\" >/dev/null 2>&1||{ faq=1; printf \"${blau}$DaQ ${rot}fehlt auf Quelle$reset\n\"; }"
	faz=; # <> "" = Datei fehlt auf Ziel
  [ "$USB" -o -z "$ZL" -o $ANDERER/ = localhost/ ]&&obssh=||obssh="ssh $ANDERER";
  eval "$obssh stat \"$DaZ\" >/dev/null 2>&1||{ faz=1; printf \"${blau}$DaZ ${rot}fehlt auf Ziel$reset\n\"; }"
	[ "$faq" -o "$faz" ]&& return 0;
  [ "$USB" -o "$ZL" -o $ANDERER/ = localhost/ ]&&obssh=||obssh="ssh $ANDERER";
  eval "geaenq=\$($obssh date +%s -r \"$DaQ\")";
  printf "geändert Quelle: $blau%15d$reset s\n" $geaenq;
  [ "$USB" -o -z "$ZL" -o $ANDERER/ = localhost/ ]&&obssh=||obssh="ssh $ANDERER";
  eval "geaenz=\$($obssh date +%s -r \"$DaZ\")";
  printf "geändert Ziel  : $blau%15d$reset s\n" $geaenz;
#	geaenq=$(expr $geaenq + 2000);
  diff=$(awk "BEGIN{print $geaenq-$geaenz+0}");
	ret=$(awk "BEGIN{print ($diff<$2);}"); # wenn richtig, liefert awk 1, sonst 0
#  ! awk "func abs(v){return v<0?-v:v}; BEGIN{ exit abs($alterdort-$alterhier)>$2 }";
  printf "Altersdifferenz $blau $diff ";if test $ret = 0; then printf ">="; else printf "<";fi; printf "$2$reset s\n";
	# wenn die Funktion 0 zurückliefert, wird in in "if obalt" verzweigt
  return $ret;
} # obalt

# kopiere mit Test auf ausreichenden Speicher
kopiermt() { # mit test
  # $1 = Verzeichnis auf Quelle, mit "\ " statt Leerzeichen
  # $2 = Verzeichnis auf Ziel
  # $3 = excludes
  # $4 = Optionen 
	# $5 = Pfad zur Datei, die als Alterskriterium geprüft werden soll
	# $6 = Zahl der Sekunden Altersunterschied, ab der kopiert werden soll
  # $7 = ob ohne Platzprüfung
  # P1obs=$(echo "$1"|sed 's/\\//g'); # Parameter 1 ohne backslashes
  QVofs=$(echo ${1#/}|sed 's/\([^\\]\) /\1\\ /g'); # Quellverzeichnis ohne führenden slash, mit "\ " statt " "
  QV=${QVofs%/}; # Quellverzeichnis (ohne slashes)
# Zielverzeichnis: wegen der rsync-Grammatik das letzte Verzeichnis von $1 noch an $2 anhängen, falls kein / am Schluss; erstes / streichen
  if [ "$USB" ]; then
    ZV=$(echo $ZL/$QV|sed 's/\([^\\]\) /\1\\ /g');
  else
    ZV=$(echo ${2%/}|sed 's/\([^\\]\) /\1\\ /g');
    case $QVofs in */);;*)ZV=$ZV/${1##*/};;esac;
  fi;
  ZV=${ZV#/};
# falls Alterskriterium nicht erfuellt, dann abbrechen	
  echo ""
  echo `date +%Y:%m:%d\ %T` "vor /$QV" >> $PROT
  printf "${blau}kopiermt $1 $2 $3 $4 $5 $6 $7, QL: $QL, /QV: /$QV, ZL: $ZL, /ZV: /$ZV$reset\n";
  [ "$5" -a "$6" ]&&{
   if ! obalt "$5" "$6"; then return 1; fi; 
	}
  EXFEST=",Papierkorb/,mnt/";
  EXREST=$EXGES;
  EXAKT=;
  while [ "$EXREST" ]; do
    EXHIER=$(readlink -f ${EXREST##*,}); EXREST=${EXREST%,*};
    case $EXHIER in $(readlink -f /$QVofs)*) EXAKT="$EXAKT,$EXHIER";; esac;
  done;
  EX="$3$EXAKT$EXFEST";
# falls nur die Schutzdatei überall etabliert werden soll
  [ "$sdneu" -a ! -f "/$ZV" ]&&{
    # beim Kopieren einzelner Dateien hierauf verzichten
    echo ZV: $ZV
    echo QV: $QV
    [ ! -f "/$ZV" -a ! -f "/$QV" ]&&{
      # scp wird hier auch lokal verwendet, da es besser mit "\ " umgehen kann als cp
      if [ "$USB" ]; then
        tue="cp -a \"$SDQ\" /$QV/$SD";
        mkdir -p /$ZV;
        tu2="cp -a \"$SDQ\" /$ZV/$SD";
      elif [ "$ZL" ]; then
        tue="scp -p \"$SDQ\" /$QV/$SD";
        ssh "$ZL" mkdir -p /$ZV;
        tu2="scp -p \"$SDQ\" $ZL/$ZV/$SD";
      else
        tue="scp -p \"$SDQ\" \"$ZL/$QV/$SD\"";
        mkdir -p /$ZV;
        tu2="scp -p \"$SDQ\" /$ZV/$SD";
      fi
      ausf "$tue";
      ausf "$tu2";
    }
    return 0;
  }
# Schutzdatei ggf. vergleichen, beim Kopieren einzelner Dateien hierauf verzichten
  [ "$SD" -a ! -f "/$ZV" -a ! -f "/$QV" ]&&{
    if [ "$ZL" -o "$USB" ]; then
      SDHIER=/$QV/$SD
      SDDORT=/$ZV/$SD
    else
      SDHIER=/$ZV/$SD
      SDDORT=/$QV/$SD
    fi;
    if [ "$USB" ]; then
      diffbef="diff $SDHIER $SDDORT 2>/dev/null";
    else
      diffbef="ssh $ANDERER \"cat $SDDORT\" 2>/dev/null| diff - $SDHIER 2>/dev/null";
    fi;
#    printf "${blau}$diffbef$reset\n"
    ausf "$diffbef";
    if [ $ret/ != 0/ ]; then
      printf "Liebe Praxis,\nbeim Versuch der Sicherheitskopie fand sich ein Unterschied zwischen\n${Q:-$LINEINS:}$SDHIER und\n$ZL$SDDORT.\nDa so etwas auch durch Ransomeware verursacht werden könnte, wurde die Sicherheitskopie für dieses Verzeichnis unterlassen.\nBitte den Systemadiminstrator verständigen!\nMit besten Grüßen, Ihr Linuxrechner"|mail -s "Achtung, Sicherheitswarnung von ${QL:-$LINEINS:} zu /$QV vor Kopie auf $ZoD!" diabetologie@dachau-mail.de
      printf "${rot}keine Übereinstimmung bei \"$SD\"!$reset\n"
      return 1;
    fi
  }
  if [ "$7" -o "$USB" ]; then
  # keine Platzprüfung
    rest=1;
  else
  # Platz ausrechnen:
  [ "$USB" -o -z $ZL -o $ZoD/ = localhost/ ]&&{ obssh=; QVa=$QV;:; }||{ obssh="ssh $ZoD"; };
    verfueg=$(eval "$obssh df /${ZV%%/*}"|sed -n '/\//s/[^ ]* *[^ ]* *[^ ]* *\([^ ]*\).*/\1/p'); # die vierte Spalte der df-Ausgabe
    printf "verfuegbar          : $blau%15d$reset Bytes\n" $verfueg;
  # je nach dem, von wo aus der Befehl aufgerufen wird und ob es sich um ein Verzeichnis oder eine Datei handelt
    schonda=$(eval "$obssh [ -d \"/$ZV\" ]&&{ $obssh du \"/$ZV\" -maxd 0;:; }||{ $obssh stat /$ZV -c %s ||echo 1; }"|awk -F $'\t' '{print $1*1024}')
    printf "schonda             : $blau%15d$reset Bytes\n" $schonda;
    [ "$USB" -o "$ZL" -o $QoD/ = localhost/ ]&&{ obssh=; QVa=/$QV;:; }||{ obssh="ssh $QoD"; QVa=\'/$QV\'; }
    zukop=$(eval "$obssh [ -f \"/$QV\" ]&&{ $obssh stat /$QV -c %s ||echo 0;:; }||$obssh du $QVa -maxd 0;"|cut -f1|awk '{print $1*1024}') # mit doppelten Anführungszeichen geht's nicht von beiden Seiten
    printf "zukopieren          : $blau%15d$reset Bytes\n" $zukop;
    rest=$(expr $verfueg - $zukop + $schonda);
    printf "Nach Kopie verfügbar: $blau%15d$reset Bytes\n" $rest;
    for E in $(echo $EX|sed 's/,/ /g');do
      E=${E#/};
      papz=$(test -d "$ZL/$ZV/$E" && du $ZL/$ZV/$E -maxd 0|cut -f1|awk '{print $1*1024}'||echo 0)
      [ "$USB" -o -z $ZL -o $QoD/ = localhost/ ]&&obssh=||obssh="ssh $QoD";
      papq=$($obssh test -d "/$QV/$E" && $obssh du /$QV/$E -maxd 0|cut -f1|awk '{print $1*1024}'||echo 0)
      rest=$(expr $rest - $papz + $papq);
    done;
  fi; # if [ "$7" ]
  if test $rest > 0; then
    [ "$USB" -o -z "$ZL" -o $ZoD/ = localhost/ ]&&obssh=||obssh="ssh $ZoD";
		case $QV in *var/lib/mysql*)
			echo stoppe mysql auf $ZL;
			eval "$obssh systemctl stop mysql";
      eval "$obssh pkill -9 mysqld";
			echo "Fertig mit Stoppen von mysql";;
	  esac;
    [ "$2" = ... ]&&case $QVofs in */)ZVK=$QVofs;;*)ZVK=${1%/*};;esac||ZVK=$2; # Ziel-Verzeichnis kurz; rsync-Grammatik berücksichtigen
    # die Excludes funktionieren so unter bash und zsh, aber nicht unter dash
#    [ "$USB" ]&&ergae="--iconv=utf8,latin1"||ergae="--rsync-path=\"$kopbef\"";
    [ "$USB" ]||ergae="--rsync-path=\"$kopbef\"";
    Quelle=$QL/$QVofs;[ "$QL" ]&&Quelle=\"$Quelle\";
    ausf "$kopbef $Quelle \"$ZL/${ZVK#/}\" $4 -avu $ergae --exclude={""$EX""}";
    [ "$USB" -o "$ZL" -o $QoD/ = localhost/ ]&&obssh=||obssh="ssh $QoD";
		eval "$obssh [ -d \"/$(echo $QV|sed 's/\\\\//g')\" ]"&&EXGES=${EXGES},/$QV/;
		case $QV in *var/lib/mysql*)
			echo starte mysql auf $ZL;
			eval "$obssh systemctl start mysql";
			echo "Fertig mit Starten von mysql";;
	  esac;
		return 0;
  else
    echo Kopieren nicht begonnen, Speicherreserve: $rest
		return 1;
  fi;
} # kopiermt

kopieros() {
  kopiermt root/$1 "root" "" "--exclude='.*.swp'" "" "" 1
}

kopieretc() {
  kopiermt etc/$1 "etc/" "" "" "" "" 1
}

# hier geht's los
blau="\033[1;34m";
dblau="\e[0;34;1;47m";
rot="\e[1;31m";
reset="\033[0m";
kopbef="ionice -c3 nice -n19 rsync";
SD="Schutzdatei_bitte_belassen.doc"
LINEINS=linux1;
[ "$HOST" ]||HOST=$(hostname);
verb=;
obdel=;
sdneu=;
commandline "$@"; # alle Befehlszeilenparameter übergeben
HOSTK=${HOST%%.*}; # $HOST kurz, also z.B. linux1 anstatt linux1.site
if [ "$USB" ]; then
  QL=;
  QoD=;
  ZoD=${ZoD%/}; # muss im aufrufenden Programm (als Gesamtpfad) definiert werden
  if [ -z "$ZoD" ]; then
    printf "$blau$0$reset wurde aufgerufen (Mutterprogrammvariable MUPR: $blau$MUPR$reset), ohne dass dort die Variable ${blau}ZoD$reset definiert wurde, breche ab\n";
    exit;
  fi;
  ZL=$ZoD;
elif [ $HOSTK/ = $LINEINS/ ]; then
  QL=;
  QoD=localhost; # Quelle ohne Doppelpunkt
#  ZL=${2%%:*}; # z.B. linux0: # jetzt in commandline
  if [ -z "$ZoD" ]; then
    printf "$blau$0$reset, Syntax: \n $blau"$(basename $0)" <-d/\"\"> <zielhost> <SD=/Pfad/zur/Schutzdatei\n-d$reset bewirkt Loeschen auf dem Zielrechner der auf dem Quellrechner nicht vorhandenen Dateien\n ${blau}SD=/Pfad/zur/Schutzdatei${reset} bewirkt Kopieren dieser Datei auf alle Quellen und Ziele und anschließender Vergleich dieser Dateien vor jedem Kopiervorgang\n";
    exit;
  fi;
  ANDERER=$ZoD; # z.B. linux0
  ZL=$ZoD:;
else
  QoD=$LINEINS;     # Quelle ohne Doppelpunkt, linux1
  QL=$QoD:;      # linux1:
  ZL=;         # Ziel
  ZoD=;         # Ziel ohne Doppelpunkt
  ANDERER=$QoD; # linux1
fi;
ZL=${ZL%/}; # der Eingangs-slash muss ggf. dran bleiben!
[ "$sdneu" ]&&{
  [ "$SD" -a ! -f "$SDQ" ]&&{ printf "$rot$SDQ$reset nicht gefunden. Breche ab.\n"; exit 1; }
  sed -i.bak "/^SD=/c\\SD=\"$SD\"" "$0"
  echo SD: $SD;
  echo SDQ: $SDQ;
  [ "$SD" ]||exit 0;
}
PROT=/var/log/$(echo $0|sed 's:.*/::;s:\..*::')prot.txt;
[ "$verb" ]&&echo Prot: $PROT
[ "$verb" ]&&printf "ANDERER: $blau$ANDERER$reset\n";
[ "$USB" ]||{ ping -c1 $ANDERER >/dev/null ||{ echo $ANDERER nicht anpingbar; exit; } };
[ "$obdel" ]&&OBDEL="--delete"||OBDEL="";
[ -z $ZoD ]&&ZoD=$HOSTK
[ "$verb" ]&&echo QL: $QL, ZL: $ZL, ZoD: $ZoD
[ "$verb" ]&&echo `date +%Y:%m:%d\ %T` "vor chown" > $PROT
chown root:root -R /root/.ssh
chmod 600 -R /root/.ssh
