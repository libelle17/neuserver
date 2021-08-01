#!/bin/zsh
# soll alle relevanten Datenen kopieren, fuer regelmaessigen Gebrauch

# ob eine Datei auf dem Zielsystem alt genug ist zum Kopieren: $1= Dateipfad, $2= Mindestalter [s]
obalt() {
  stat "$1" >/dev/null 2>&1 ||{ echo $1 fehlt hier; return 0;}
  ssh $ANDERER stat "$1" >/dev/null 2>&1 ||{ echo $1 fehlt dort; return 0;}
  alterhier=$(date +%s -r "$1");
  echo Alter hier: $alterhier s
  alterdort=$(ssh $ANDERER date +%s -r "$1");
  echo Alter dort: $alterdort s
  ! awk "func abs(v){return v<0?-v:v}; BEGIN{ exit abs($alterdort-$alterhier)>$2 }";
  ret=$?;
  if test $ret = 0; then echo Altersdifferenz ">" $2 s; else echo Altersdifferenz "<" $2 s; fi;
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
  echo kopiermt "$1" "$2" "$3" "$4";
# Platz ausrechnen:
  ZV=$(echo $2|sed 's:/$::'); [ "$ZV" ]||ZV=$1;
  echo Z: $Z
  echo ZV: $ZV
  verfueg=$(eval "test -z $Z&&df /${ZV%%/*}||ssh ${Z%:} df /${ZV%%/*}"|sed -n '/\//s/[^ ]* *[^ ]* *[^ ]* *\([^ ]*\).*/\1/p'); # die vierte Spalte der df-Ausgabe
  echo verfuegbar: $verfueg Bytes
  schonda=$(eval "test -z $Z&&{ [ -d /$ZV ]&&du /$ZV -maxd 0||echo 0 0;:;}||{ ssh ${Z%:} [ -d /$ZV ]&&ssh ${Z%:} du /$ZV -maxd 0||echo 0 0;:;}"|cut -d$'\t' -f1|awk '{print $1*1024}')
  echo schonda: $schonda Bytes
  zukop=$(eval "test -z $Z&&ssh $QoD du /$1 -maxd 0||du /$1 -maxd 0"|cut -f1|awk '{print $1*1024}')
  echo zukopieren: $zukop Bytes
  rest=$(expr $verfueg - $zukop + $schonda);
  echo Rest: $rest Bytes
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
kopbef="ionice -c3 nice -n19 rsync";
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
ziel=${Z%:}
[ -z $ziel ]&&ziel=$HOSTK
echo Q: $Q, Z: $Z ziel: $ziel
chown root:root -R /root/.ssh
chmod 600 -R /root/.ssh
# EXCL=--exclude={
Dt=DATA; 
ot=opt/turbomed
pd=/$ot/PraxisDB/objects.dat
if obalt $pd 1800; then 
 kopiermt "$ot" "opt/" "" "$OBDEL"
fi
kopieros ".vim"
kopieros ".smbcredentials"
kopieros "crontabakt"
kopieros ".getmail"
kopieros ".7zpassw"
kopieros ".mysqlpwd"
V=/root/bin/;ionice -c3 nice -n19 rsync -avu --prune-empty-dirs --include="*/" --include="*.sh" --exclude="*" $Q$V "$Z$V"
# kopieros "root/bin" # auskommentiert 29.7.19
# kopieros "root/" # auskommentiert 29.7.19
mountpoint -q /$Dt || mount /$Dt;
ssh $ANDERER mountpoint -q /$Dt 2>/dev/null || ssh $ANDERER mount /$Dt;
if mountpoint -q /$Dt && ssh $ANDERER mountpoint -q /$Dt 2>/dev/null; then
# for uverz in $(find /$Dt/Mail/Thunderbird/Profiles -mindepth 1 -maxdepth 1 -type d); do
 for uverz in Praxis Schade Wagner Kothny Beraterinnen; do
  if test $uverz = Praxis || test $ziel != linux7; then
   qverz=$Dt/Mail/Thunderbird/Profiles/$uverz;
   find /$qverz -iname INBOX -print0|while IFS= read -r -d '' inbox; do
     echo Ergebnis: "$inbox";
     # eine Woche
     if obalt "$inbox" 604800; then 
       echo $qverz zu alt
       kopiermt $qverz/ $qverz "" -d;
       break;
     fi
   done;
  fi;
 done;
 for A in Patientendokumente turbomed shome eigene\\\ Dateien sql TMBack rett down DBBack ifap vontosh Oberanger att; do
  auslass=;
  [ $ziel = linux7 ]&&case $A in sql|TMBack|DBBack|vontosh|Oberanger|att) auslass=1; esac;
  [ -z $auslass ]&&kopiermt "$Dt/$A" "$Dt/" "" "$OBDEL";
  EXCL=${EXCL}"$A/,";
 done;
 EXCL=${EXCL}"TMBackloe,DBBackloe,sqlloe,TMExportloe}";
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
