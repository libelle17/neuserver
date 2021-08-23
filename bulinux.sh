#!/bin/zsh
MUPR="$0"; # Mutterprogramm
. /root/bin/bugem.sh
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
     [ "$sdneu" ]||echo inbox: "$inbox";
     # eine Woche
     if obalt "$inbox" 604800; then 
       [ "$sdneu" ]||echo $qverz zu alt
       kopiermt $qverz/ $qverz "" -d;
       break;
     fi
   done;
  fi;
 done;
 for A in Patientendokumente turbomed shome eigene\\\ Dateien sql TMBack rett down DBBack ifap vontosh Oberanger att; do
  auslass=;
  [ $ziel = linux7 ]&&case $A in sql|TMBack|DBBack|vontosh|Oberanger|att) auslass=1;; esac;
  [ -z $auslass ]&&kopiermt "$Dt/$A" "$Dt/" "" "$OBDEL";
  EXCL=${EXCL}"$A/,";
 done;
 EXCL=${EXCL}"TMBackloe,DBBackloe,sqlloe,TMExportloe,Thunderbird/Profiles";
 kopiermt "$Dt" "" "$EXCL" "-W $OBDEL";
fi;
# kopieretc "samba" # auskommentiert 29.7.19
# kopieretc "hosts" # hier muesste noch eine Zeile geaendert werden!
# kopieretc "vsftpd.conf" # auskommentiert 29.7.19
# kopieretc "my.cnf" # auskommentiert 29.7.19
# kopieretc "fstab.cnf" # auskommentiert 29.7.19
kopiermt "gerade" "/" "" "$OBDEL"
kopiermt "ungera" "/" "" "$OBDEL"
VLM="var/lib/mysql";
if obalt "/$VLM/ibdata1" 86400; then 
  [ "$sdneu" ]||{
    echo stoppe mysql auf $Z
    test -z "$Z"&&{ systemctl stop mysql;: }||ssh ${Z%:} systemctl stop mysql;
    test -z "$Z"&&{ pkill -9 mysqld;: }||ssh ${Z%:} pkill -9 mysqld;
    echo Fertig mit Stoppen von mysql
  }
  kopiermt "$VLM/" "${VLM}_1" "$OBDEL"
  [ "$sdneu" ]||{
    echo starte mysql auf $Z
    test -z "$Z"&&{ systemctl start mysql;: }||ssh ${Z%:} systemctl start mysql;
    echo Fertig mit Starten von mysql
  }
  [ "$sdneu" ]&&exit;
  # kopieretc "openvpn" # auskommentiert 29.7.19
  scp $PROT $ANDERER:/var/log/
  if mountpoint -q /$Dt && ssh $ANDERER mountpoint -q /$Dt 2>/dev/null; then
   scp $PROT $ANDERER:/$Dt/
  fi;
  if [ $HOSTK/ != $LINEINS/ ]; then
    NES=~/neuserver;
    echo Rufe los.sh auf;
    LOS=los.sh;
    if test -d $NES -a -f $NES/$LOS; then
      echo Rufe mysqlneu auf;
      cd $NES;
      sh $LOS mysqlneu -v;
      cd -;
      echo Fertig mit mysqlneu;
    fi;
    echo Fertig mit los.sh;
  fi;
fi;
echo `date +%Y:%m:%d\ %T` "nach Kopieren" >> $PROT

# exit
# echo `date +%Y:%m:%d\ %T` "vor /etc/hosts" >> $PROT
# rsync $Q:/etc/samba $Q:/etc/hosts $Q:/etc/vsftpd*.conf $Q:/etc/my.cnf $Q:/etc/fstab $Z/etc/ -avuz # keine Anführungszeichen um den Stern!
