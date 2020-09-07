#!/bin/zsh
# kopiert die aktuellen Turbomed-Dateien, fuer haufigen Gebrauch
function kopier {
 echo ""
 echo `date +%Y:%m:%d\ %T` "vor /$1" >> $PROT
 tue="rsync \"$Q/$1\" \"$Z/$2\" $4 -avu --exclude=Papierkorb --exclude=mnt ""$3"
 echo $tue
 eval $tue
}
function kopieros {
  kopier $1 "" "--exclude='.*.swp'"
}
function kopieretc {
  kopier etc/$1 "etc/"
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
  Z=${2%%:*}; # z.B. linux0:
  ANDERER=$Z; # z.B. linux0
  Z=$Z:;
else
  Q=$LINEINS; # linux1:
  Z="";
  ANDERER=$Q; # linux1
  Q=$Q:;
fi;
ping -c1 $ANDERER >/dev/null || exit;
blau="\033[1;34m";
rot="\e[1;31m";
reset="\033[0m";
[ "$1"/ = -d/ ]&&OBDEL="--delete"||OBDEL="";
PROT=/var/log/${$(basename $0)%%.*}prot.txt
echo Prot: $PROT
echo `date +%Y:%m:%d\ %T` "vor chown" >$PROT
chown root:root -R /root/.ssh
chmod 600 -R /root/.ssh
for Vz in PraxisDB StammDB DruckDB Dictionary; do
 wz="opt/turbomed"
 kopier "$wz/$Vz" "$wz" "$OBDEL"
done;
Dt=DATA; 
mountpoint -q /$Dt || mount /$Dt;
ssh $ANDERER mountpoint -q /$Dt 2>/dev/null || ssh $ANDERER mount /$Dt;
if mountpoint -q /$Dt && ssh $ANDERER mountpoint -q /$Dt 2>/dev/null; then
 kopier "$Dt/turbomed" "$Dt/" "$OBDEL"
fi;
P=Patientendokumente
kopier "$Dt/$P/eingelesen" "$Dt/$P/" "$OBDEL"
