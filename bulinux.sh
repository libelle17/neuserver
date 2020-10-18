#!/bin/zsh
# soll alle relevanten Datenen kopieren, fuer regelmaessigen Gebrauch

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
  kopiermt "root/$1" "root" "" "--exclude='.*.swp'"
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
echo `date +%Y:%m:%d\ %T` "vor chown" > $PROT
chown root:root -R /root/.ssh
chmod 600 -R /root/.ssh
# EXCL=--exclude={
Dt=DATA; 
kopiermt "opt/turbomed" "opt/" "" "$OBDEL"
kopieros ".vim"
kopieros ".smbcredentials"
kopieros "crontabakt"
kopieros ".getmail"
kopieros ".7zpassw"
kopieros ".mysqlpwd"
V=/root/bin/;rsync -avu --prune-empty-dirs --include="*/" --include="*.sh" --exclude="*" "$Q$V" "$Z$V"
# kopieros "root/bin" # auskommentiert 29.7.19
# kopieros "root/" # auskommentiert 29.7.19
mountpoint -q /$Dt || mount /$Dt;
ssh $ANDERER mountpoint -q /$Dt 2>/dev/null || ssh $ANDERER mount /$Dt;
if mountpoint -q /$Dt && ssh $ANDERER mountpoint -q /$Dt 2>/dev/null; then
 for A in Patientendokumente turbomed shome eigene\\\ Dateien sql Mail TMBack rett down DBBack ifap vontosh Oberanger att; do
  kopiermt "$Dt/$A" "$Dt/" "" "$OBDEL";
  EXCL=${EXCL}"$A/,";
 done;
 EXCL=${EXCL}"TMBackloe,DBBackloe,sqlloe}";
 kopiermt "$Dt" "" "$EXCL" "-W $OBDEL";
fi;
# kopieretc "samba" # auskommentiert 29.7.19
# kopieretc "hosts" # hier muesste noch eine Zeile geaendert werden!
# kopieretc "vsftpd.conf" # auskommentiert 29.7.19
# kopieretc "my.cnf" # auskommentiert 29.7.19
# kopieretc "fstab.cnf" # auskommentiert 29.7.19
kopiermt "gerade" "/" "" "$OBDEL"
kopiermt "ungera" "/" "" "$OBDEL"
systemctl stop mysql
pkill -9 mysqld
VLM="var/lib/mysql";
kopiermt "$VLM/" "${VLM}_1" "$OBDEL"
systemctl start mysql
# kopieretc "openvpn" # auskommentiert 29.7.19
echo `date +%Y:%m:%d\ %T` "vor ende.sh" >> $PROT
scp $PROT $ANDERER:/var/log/
if mountpoint -q /$Dt && ssh $ANDERER mountpoint -q /$Dt 2>/dev/null; then
 scp $PROT $ANDERER:/$Dt/
fi;
if [ $HOSTK/ != $LINEINS/ ]; then
  NES=~/neuserver;
  LOS=los.sh;
  if test -d $NES -a -f $NES/$LOS; then
    cd $NES;
    sh $LOS mysqlneu -v;
    cd -;
  fi;
fi;

# exit
# echo `date +%Y:%m:%d\ %T` "vor /etc/hosts" >> $PROT
# rsync $Q:/etc/samba $Q:/etc/hosts $Q:/etc/vsftpd*.conf $Q:/etc/my.cnf $Q:/etc/fstab $Z/etc/ -avuz # keine Anführungszeichen um den Stern!
