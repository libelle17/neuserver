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
      Z=${1%%:*};; # z.B. linux0:
   esac;
   shift;
	done;
	if [ "$verb" ]; then
		printf "obdel: $blau$obdel$reset\n";
		printf "sdneu: $blau$sdneu$reset\n";
		printf "SD: $blau$SD$reset\n";
	fi;
} # commandline


# ob eine Datei auf dem Zielsystem alt genug ist zum Kopieren, aufgerufen aus kopiermt: $1= Dateipfad, $2= Mindestalter [s]
obalt() {
	# $1 = Datei auf $QV und $ZV, deren Alter verglichen werden soll 
	# $2 = Zahl der Sekunden Altersunterschied, ab der kopiert werden soll
  [ "$sdneu" ]&&return 0; # Altersprüfung im Modus der Schutzdateiverteilung nicht sinnvoll => hier immer weiter machen
	faq=; # <> "" = Datei fehlt auf Quelle
  test -z $Z&&{ ssh $ANDERER stat "/$QV/$1" >/dev/null 2>&1||faq=1;:; }||{ stat "/$QV/$1" >/dev/null 2>&1||faq=1; }
	[ "$faq" ]&& printf "${blau}/$QV/$1 ${rot}fehlt auf Quelle$reset\n";
	faz=; # <> "" = Datei fehlt auf Ziel
  test -z $Z&&{ stat "/$ZV/$1" >/dev/null 2>&1||faq=1;:; }||{ ssh $ANDERER stat "/$ZV/$1" >/dev/null 2>&1||faz=1; }
	[ "$faq" ]&& printf "${blau}/$ZV/$1 ${rot}fehlt auf Ziel$reset\n";
	[ "$faq" -o "$faz" ]&& return 0;
  test -z $Z&&{ geaenq=$(ssh $ANDERER date +%s -r "/$QV/$1");:; }||{ geaenq=$(date +%s -r "/$QV/$1"); }
  printf "geändert Quelle: $blau%15d$reset s\n" $geaenq;
  test -z $Z&&{ geaenz=$(date +%s -r "/$ZV/$1");:; }||{ geaenz=$(ssh $ANDERER date +%s -r "/$ZV/$1"); }
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
  QV=${1%/};
# Zielverzeichnis: wegen der rsync-Grammatik das letzte Verzeichnis von $1 noch an $2 anhängen, falls kein / am Schluss; erstes / streichen
  ZV=${2%/};case $1 in */);;*)ZV=$ZV/${1##*/};;esac;ZV=${ZV#/};
# falls Alterskriterium nicht erfuellt, dann abbrechen	
  echo ""
  echo `date +%Y:%m:%d\ %T` "vor /$1" >> $PROT
  printf "${blau}kopiermt $1 $2 $3 $4 $5 $6 $7, QV: $QV, ZV: $ZV$reset\n";
  [ "$5" -a "$6" ]&&{
   if ! obalt "$5" "$6"; then return 1; fi; 
	}
  EX="$3,Papierkorb/,mnt/";
#  echo ZV: $ZV
# falls nur die Schutzdatei überall etabliert werden soll
  [ "$sdneu" ]&&{
    # beim Kopieren einzelner Dateien hierauf verzichten
    [ ! -f "/$ZV" -a ! -f "/$QV" ]&&{
      # scp wird hier auch lokal verwendet, da es besser mit "\ " umgehen kann als cp
      echo ZV: $ZV
      if [ "$Z" ]; then
        tue="scp -p \"$SDQ\" \"/$QV/$SD\"";
        tu2="scp -p \"$SDQ\" \"$Z/$ZV/$SD\"";
      else
        tue="scp -p \"$SDQ\" \"$Z/$QV/$SD\"";
        tu2="scp -p \"$SDQ\" \"/$ZV/$SD\"";
      fi
      ausf "$tue";
      ausf "$tu2";
    }
    return 0;
  }
# Schutzdatei ggf. vergleichen, beim Kopieren einzelner Dateien hierauf verzichten
  [ "$SD" -a ! -f "/$ZV" -a ! -f "/{1%/}" ]&&{
    if [ "$Z" ]; then
      SDHIER=/$QV/$SD
      SDDORT=/$ZV/$SD
    else
      SDHIER=/$ZV/$SD
      SDDORT=/$QV/$SD
    fi;
    diffbef="ssh $ANDERER \"cat $SDDORT\" 2>/dev/null| diff - $SDHIER 2>/dev/null";
#    printf "${blau}$diffbef$reset\n"
    ausf "$diffbef";
    if [ $ret/ != 0/ ]; then
      printf "Liebe Praxis,\nbeim Versuch der Sicherheitskopie fand sich ein Unterschied zwischen\n${Q:-$LINEINS:}$SDHIER und\n$Z$SDDORT.\nDa so etwas auch durch Ransomeware verursacht werden könnte, wurde die Sicherheitskopie für dieses Verzeichnis unterlassen.\nBitte den Systemadiminstrator verständigen!\nMit besten Grüßen, Ihr Linuxrechner"|mail -s "Achtung, Sicherheitswarnung von ${Q:-$LINEINS:} zu /$QV vor Kopie auf ${Z%:}!" diabetologie@dachau-mail.de
      printf "${rot}keine Übereinstimmung bei \"$SD\"!$reset\n"
      return 1;
    fi
  }
  if [ "$7" ]; then
    rest=1;
  else
  # Platz ausrechnen:
    verfueg=$(eval "test -z $Z&&df /${ZV%%/*}||ssh ${Z%:} df /${ZV%%/*}"|sed -n '/\//s/[^ ]* *[^ ]* *[^ ]* *\([^ ]*\).*/\1/p'); # die vierte Spalte der df-Ausgabe
    printf "verfuegbar          : $blau%15d$reset Bytes\n" $verfueg;
  # je nach dem, von wo aus der Befehl aufgerufen wird und ob es sich um ein Verzeichnis oder eine Datei handelt
    schonda=$(eval "test -z $Z&&{ [ -d \"/$ZV\" ]&&{ du \"/$ZV\" -maxd 0;:; }||{ stat \"/$ZV\" -c %s 2>/dev/null||echo 0; };:; }||{ ssh ${Z%:} [ -d \"/$ZV\" ]&&{ ssh ${Z%:} du \"/$ZV\" -maxd 0;:; }||{ ssh ${Z%:} stat \"/$ZV\" -c %s 2>/dev/null||echo 0; };:; }"|awk -F $'\t' '{print $1*1024}')
    printf "schonda             : $blau%15d$reset Bytes\n" $schonda;
    zukop=$(eval "test -z $Z&&{ ssh $QoD [ -f \"/$1\" ]&&{ ssh $QoD stat \"/$1\" -c %s 2>/dev/null||echo 0;:; }||ssh $QoD du /$1 -maxd 0;:; }||{ [ -f \"/$1\" ]&&{ stat \"/$1\" -c %s 2>/dev/null||echo 0;:; }||du /$1 -maxd 0; }"|cut -f1|awk '{print $1*1024}')
    printf "zukopieren          : $blau%15d$reset Bytes\n" $zukop;
    rest=$(expr $verfueg - $zukop + $schonda);
    printf "Nach Kopie verfügbar: $blau%15d$reset Bytes\n" $rest;
    for E in $(echo $EX|sed 's/,/ /g');do
      papz=$(test -d $Z/$ZV/$E && du $Z/$ZV/$E -maxd 0|cut -f1|awk '{print $1*1024}'||echo 0)
      papq=$(ssh $QoD test -d $1/$E && ssh $QoD du $1/$E -maxd 0|cut -f1|awk '{print $1*1024}'||echo 0)
      rest=$(expr $rest - $papz + $papq);
    done;
  fi; # if [ "$7" ]
  if test $rest > 0; then
		case $1 in *var/lib/mysql*)
			echo stoppe mysql auf $Z
			test -z "$Z"&&{ systemctl stop mysql;:; }||ssh ${Z%:} systemctl stop mysql;
 			test -z "$Z"&&{ pkill -9 mysqld;:; }||ssh ${Z%:} pkill -9 mysqld;
			echo "Fertig mit Stoppen von mysql";;
	  esac;
    # die Excludes funktionieren so unter bash und zsh, aber nicht unter dash
    ausf "$kopbef \"$Q/$1\" \"$Z/$2\" $4 -avu --rsync-path=\"$kopbef\" --exclude={""$EX""}";
		case $1 in *var/lib/mysql*)
			echo starte mysql auf $Z;
			test -z "$Z"&&{ systemctl start mysql;:; }||ssh ${Z%:} systemctl start mysql;
			echo "Fertig mit Starten von mysql";;
	  esac;
		return 0;
  else
    echo Kopieren nicht begonnen, Speicherreserve: $rest
		return 1;
  fi;
} # kopiermt

kopieros() {
  kopiermt "root/$1" "root" "" "--exclude='.*.swp'" "" "" 1
}

kopieretc() {
  kopiermt etc/$1 "etc/" "" "" "" "" 1
}

# hier geht's los
blau="\033[1;34m";
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
if [ $HOSTK/ = $LINEINS/ ]; then
  Q="";
  QoD=localhost; # Quelle ohne Doppelpunkt
#  Z=${2%%:*}; # z.B. linux0: # jetzt in commandline
  ANDERER=$Z; # z.B. linux0
  Z=$Z:;
else
  Q=$LINEINS; # linux1:
  QoD=$Q;
  Z="";
  ANDERER=$Q; # linux1
  Q=$Q:;
fi;
[ "$sdneu" ]&&{
  [ "$SD" -a ! -f "$SDQ" ]&&{ printf "$rot$SDQ$reset nicht gefunden. Breche ab.\n"; exit 1; }
  sed -i.bak "/^SD=/c\\SD=\"$SD\"" "$0"
  echo SD: $SD;
  echo SDQ: $SDQ;
  [ "$SD" ]||exit 0;
}
if [ $HOSTK/ = $LINEINS/ -a "$Z/" = : ]; then
  printf "$blau$0$reset, Syntax: \n $blau"$(basename $0)" <-d/\"\"> <zielhost> <SD=/Pfad/zur/Schutzdatei\n-d$reset bewirkt Loeschen auf dem Zielrechner der auf dem Quellrechner nicht vorhandenen Dateien\n ${blau}SD=/Pfad/zur/Schutzdatei${reset} bewirkt Kopieren dieser Datei auf alle Quellen und Ziele und anschließender Vergleich dieser Dateien vor jedem Kopiervorgang\n";
  exit;
fi;
[ "$verb" ]&&echo ANDERER: $blau$ANDERER$reset
ping -c1 $ANDERER >/dev/null || exit;
[ "$obdel" ]&&OBDEL="--delete"||OBDEL="";
PROT=/var/log/$(echo $0|sed 's:.*/::;s:\..*::')prot.txt;
[ "$verb" ]&&echo Prot: $PROT
[ "$verb" ]&&echo `date +%Y:%m:%d\ %T` "vor chown" > $PROT
ziel=${Z%:} # für bulinux.sh benötigt, nicht für butm.sh
[ -z $ziel ]&&ziel=$HOSTK
[ "$verb" ]&&echo Q: $Q, Z: $Z, ziel: $ziel
chown root:root -R /root/.ssh
chmod 600 -R /root/.ssh
