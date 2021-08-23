#!/bin/zsh
# soll alle relevanten Datenen kopieren, fuer regelmaessigen Gebrauch

# ob eine Datei auf dem Zielsystem alt genug ist zum Kopieren: $1= Dateipfad, $2= Mindestalter [s]
obalt() {
  [ "$sdneu" ]&&return 0;
  stat "$1" >/dev/null 2>&1 ||{ echo $1 fehlt hier; return 0;}
  ssh $ANDERER stat "$1" >/dev/null 2>&1 ||{ echo $1 fehlt dort; return 0;}
  alterhier=$(date +%s -r "$1");
  printf "geändert hier: $blau%15d$reset s\n" $alterhier;
  alterdort=$(ssh $ANDERER date +%s -r "$1");
  printf "geändert dort: $blau%15d$reset s\n" $alterdort;
  [ "$Z" ]&&vp="<"||vp=">=";
  diff=$(awk "BEGIN{print $alterhier-$alterdort+0}");
  ret=$(awk "BEGIN{print ($diff$vp$2);}");
#  ! awk "BEGIN{ exit $diff$vp$2 }";
#  ret=$?;
#  ! awk "func abs(v){return v<0?-v:v}; BEGIN{ exit abs($alterdort-$alterhier)>$2 }";
  printf "Altersdifferenz $blau $diff ";if test $ret = 0; then printf ">"; else printf "<";fi; printf "$2$reset s\n";
  return $ret;
}

# kopiere mit Test auf ausreichenden Speicher
kopiermt() { # mit test
  # $1 = Verzeichnis auf Quelle, mit "\ " statt Leerzeichen
  # $2 = Verzeichnis auf Ziel
  # $3 = excludes
  # $4 = Optionen 
  EX="$3,Papierkorb,mnt";
  echo ""
  echo `date +%Y:%m:%d\ %T` "vor /$1" >> $PROT
  printf "${blau}kopiermt $1 $2 $3 $4$reset\n";
#  ZV=$(echo $2|sed 's:/$::'); [ "$ZV" ]||ZV=$1;
# Zielverzeichnis: wegen der rsync-Grammatik das letzte Verzeichnis von $1 noch an $2 anhängen, falls kein / am Schluss; erstes / streichen
  ZV=${2%/};case $1 in */);;*)ZV=$ZV/${1##*/};;esac;ZV=${ZV#/};
#  echo ZV: $ZV
# falls nur die Schutzdatei überall etabliert werden soll
  [ "$sdneu" ]&&{
    # beim Kopieren einzelner Dateien hierauf verzichten
    [ ! -f "/$ZV" -a ! -f "/{1%/}" ]&&{
      # scp wird hier auch lokal verwendet, da es besser mit "\ " umgehen kann als cp
      echo ZV: $ZV
      if [ "$Z" ]; then
        tue="scp -p \"$SDQ\" \"/${1%/}/$SD\"";
        tu2="scp -p \"$SDQ\" \"$Z/$ZV/$SD\"";
      else
        tue="scp -p \"$SDQ\" \"$Z/${1%/}/$SD\"";
        tu2="scp -p \"$SDQ\" \"/$ZV/$SD\"";
      fi
      echo $tue;
      eval $tue;
      echo $tu2;
      eval $tu2;
    }
    return;
  }
# Schutzdatei ggf. vergleichen, beim Kopieren einzelner Dateien hierauf verzichten
  [ "$SD" -a ! -f "/$ZV" -a ! -f "/{1%/}" ]&&{
    if [ "$Z" ]; then
      SDHIER=/${1%/}/$SD
      SDDORT=/$ZV/$SD
    else
      SDHIER=/$ZV/$SD
      SDDORT=/${1%/}/$SD
    fi;
    diffbef="ssh $ANDERER \"cat $SDDORT\" 2>/dev/null| diff - $SDHIER 2>/dev/null";
#    printf "${blau}$diffbef$reset\n"
    if ! eval $diffbef; then
      printf "${rot}keine Übereinstimmung bei \"$SD\"!$reset\n"
      return;
    fi
  }
# Platz ausrechnen:
  verfueg=$(eval "test -z $Z&&df /${ZV%%/*}||ssh ${Z%:} df /${ZV%%/*}"|sed -n '/\//s/[^ ]* *[^ ]* *[^ ]* *\([^ ]*\).*/\1/p'); # die vierte Spalte der df-Ausgabe
  printf "verfuegbar          : $blau%15d$reset Bytes\n" $verfueg;
# je nach dem, von wo aus der Befehl aufgerufen wird und ob es sich um ein Verzeichnis oder eine Datei handelt
  schonda=$(eval "test -z $Z&&{ [ -d \"/$ZV\" ]&&{ du \"/$ZV\" -maxd 0;: }||{ stat \"/$ZV\" -c %s;: };: }||{ ssh ${Z%:} [ -d \"/$ZV\" ]&&{ ssh ${Z%:} du \"/$ZV\" -maxd 0;: }||{ ssh ${Z%:} stat \"/$ZV\" -c %s;: };: }"|cut -d$'\t' -f1|awk '{print $1*1024}')
  printf "schonda             : $blau%15d$reset Bytes\n" $schonda;
  zukop=$(eval "test -z $Z&&{ ssh $QoD [ -f \"/$1\" ]&&{ ssh $QoD stat \"/$1\" -c %s;: }||ssh $QoD du /$1 -maxd 0;: }||{ [ -f \"/$1\" ]&&{ stat \"/$1\" -c %s;: }||du /$1 -maxd 0;: }"|cut -f1|awk '{print $1*1024}')
  printf "zukopieren          : $blau%15d$reset Bytes\n" $zukop;
  rest=$(expr $verfueg - $zukop + $schonda);
  printf "Nach Kopie verfügbar: $blau%15d$reset Bytes\n" $rest;
  for E in $(echo $EX|sed 's/,/ /g');do
    papz=$(test -d $Z/$ZV/$E && du $Z/$ZV/$E -maxd 0|cut -f1|awk '{print $1*1024}'||echo 0)
    papq=$(ssh $QoD test -d $1/$E && ssh $QoD du $1/$E -maxd 0|cut -f1|awk '{print $1*1024}'||echo 0)
    rest=$(expr $rest - $papz + $papq);
  done;
  if test $rest > 0; then
    tue="$kopbef $Q/$1 \"$Z/$2\" $4 -avu --rsync-path=\"$kopbef\" --exclude={""$EX""}";
    echo $tue
    eval $tue
  else
    echo Kopieren nicht begonnen, Speicherreserve: $rest
  fi;
}

kopieros() {
  kopiermt "root/$1" "root" "" "--exclude='.*.swp'"
}

kopieretc() {
  kopiermt etc/$1 "etc/"
}

# hier geht's los
blau="\033[1;34m";
rot="\e[1;31m";
reset="\033[0m";
kopbef="ionice -c3 nice -n19 rsync";
SD="Schutzdatei_bitte_belassen.doc"
sdneu=;[ $# -ge 3 ]&&case $3 in SD=*) sdneu=1;SDQ=${3##*SD=};SD=${3##*/};; esac;
[ "$sdneu" ]&&{
  [ "$SD" -a ! -f "$SDQ" ]&&{ printf "$rot$SDQ$reset nicht gefunden. Breche ab.\n"; exit 1; }
  sed -i.bak "/^SD=/c\\SD=\"$SD\"" "$0"
  echo SD: $SD;
  echo SDQ: $SDQ;
  [ "$SD" ]||exit 0;
}
LINEINS=linux1;
[ "$HOST" ]||HOST=$(hostname);
HOSTK=${HOST%%.*}; # $HOST kurz, also z.B. linux1 anstatt linux1.site
if [ $HOSTK/ = $LINEINS/ ]; then
  if [ $# -lt 2 ]; then
    printf "$blau$0$reset, Syntax: \n $blau"$(basename $0)" <-d/\"\"> <zielhost> <SD=/Pfad/zur/Schutzdatei\n-d$reset bewirkt Loeschen auf dem Zielrechner der auf dem Quellrechner nicht vorhandenen Dateien\n ${blau}SD=/Pfad/zur/Schutzdatei${reset} bewirkt Kopieren dieser Datei auf alle Quellen und Ziele und anschließender Vergleich dieser Dateien vor jedem Kopiervorgang\n";
    exit;
  fi;
  Q="";
  QoD=localhost; # Quelle ohne Doppelpunkt
  Z=${2%%:*}; # z.B. linux0:
  ANDERER=$Z; # z.B. linux0
  Z=$Z:;
else
  Q=$LINEINS; # linux1:
  QoD=$Q;
  Z="";
  ANDERER=$Q; # linux1
  Q=$Q:;
fi;
echo ANDERER: $ANDERER
ping -c1 $ANDERER >/dev/null || exit;
[ "$1"/ = -d/ ]&&OBDEL="--delete"||OBDEL="";
PROT=/var/log/$(echo $0|sed 's:.*/::;s:\..*::')prot.txt;
echo Prot: $PROT
echo `date +%Y:%m:%d\ %T` "vor chown" > $PROT
ziel=${Z%:} # für bulinux.sh benötigt, nicht für butm.sh
[ -z $ziel ]&&ziel=$HOSTK
echo Q: $Q, Z: $Z, ziel: $ziel
chown root:root -R /root/.ssh
chmod 600 -R /root/.ssh
