#!/bin/zsh
# kopiert die aktuellen Turbomed-Dateien, fuer haufigen Gebrauch

kopiermt() { # mit test
  # $1 = Verzeichnis auf Quelle
  # $2 = Verzeichnis auf Ziel
  # $3 = excludes
  # $4 = Optionen 
  EX="$3,Papierkorb,mnt";
  echo ""
  echo `date +%Y:%m:%d\ %T` "vor /$1" >> $PROT
  echo kopiermt "$1" "$2" "$3" "$4";
# Platz ausrechnen:
  ZV=$(echo $2|sed 's:/$::'); [ "$ZV" ]||ZV=$1;
  [ -d $Z/$ZV ]||mkdir -p $Z/$ZV;
  verfueg=$(df /$Z/$ZV|sed -n '/\//s/[^ ]* *[^ ]* *[^ ]* *\([^ ]*\).*/\1/p'); # die vierte Spalte der df-Ausgabe
  schonda=$(du $Z/$ZV -maxd 0|cut -d$'\t' -f1|awk '{print $1*1024}')
  zukop=$(ssh $QoD du /$1 -maxd 0|cut -f1|awk '{print $1*1024}')
  summe=$(expr $verfueg - $zukop + $schonda);
  for E in $(echo $EX|sed 's/,/ /g');do
    papz=$(test -d $Z/$ZV/$E && du $Z/$ZV/$E -maxd 0|cut -f1|awk '{print $1*1024}'||echo 0)
    papq=$(ssh $QoD test -d $1/$E && ssh $QoD du $1/$E -maxd 0|cut -f1|awk '{print $1*1024}'||echo 0)
    summe=$(expr $summe - $papz + $papq);
  done;
  if test $summe > 0; then
    tue="rsync \"$Q/$1\" \"$Z/$2\" $4 -avu --rsync-path=\"ionice -c3 nice -n19 rsync\" --exclude={""$EX""}";
    echo $tue
    eval $tue
  else
    echo Kopieren nicht begonnen, Speicherreserve: $summe
  fi;
}

kopier() {
 echo ""
 echo `date +%Y:%m:%d\ %T` "vor /$1" >> $PROT
 tue="rsync \"$Q/$1\" \"$Z/$2\" $4 -avu --rsync-path=\"ionice -c3 nice -n19 rsync\" --exclude=Papierkorb --exclude=mnt ""$3"
 echo $tue
 eval $tue
}

kopieros() {
  kopiermt $1 "" "" "--exclude='.*.swp'"
}

kopieretc() {
  kopiermt etc/$1 "etc/"
}

# hier geht's los
LINEINS=linux1;
[ "$HOST" ]||HOST=$(hostname);
HOSTK=${HOST%%.*};
if [ $HOSTK/ = $LINEINS/ ]; then
  if [ $# -lt 2 ]; then
    printf "$blau$0$reset, Syntax: \n $blau"$(basename $0)" <-d/\"\"> <zielhost>\n-d$reset bewirkt Loeschen auf dem Zielrechner der auf dem Quellrechner nicht vorhandenen Dateien\n";
    exit;
  fi;
  Q="";
  QoD=localhost;
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
ping -c1 $ANDERER >/dev/null || exit;
blau="\033[1;34m";
rot="\e[1;31m";
reset="\033[0m";
[ "$1"/ = -d/ ]&&OBDEL="--delete"||OBDEL="";
PROT=/var/log/$(echo $0|sed 's:.*/::;s:\..*::')prot.txt;
echo Prot: $PROT
echo `date +%Y:%m:%d\ %T` "vor chown" >$PROT
chown root:root -R /root/.ssh
chmod 600 -R /root/.ssh
for Vz in PraxisDB StammDB DruckDB Dictionary; do
 wz="opt/turbomed"
 kopiermt "$wz/$Vz" "$wz" "" "$OBDEL"
done;
Dt=DATA; 
mountpoint -q /$Dt || mount /$Dt;
ssh $ANDERER mountpoint -q /$Dt 2>/dev/null || ssh $ANDERER mount /$Dt;
if mountpoint -q /$Dt && ssh $ANDERER mountpoint -q /$Dt 2>/dev/null; then
 kopiermt "$Dt/turbomed" "$Dt/" "" "$OBDEL"
fi;
P=Patientendokumente
kopiermt "$Dt/$P/eingelesen" "$Dt/$P/" "" "$OBDEL"
