#!/bin/zsh
MUPR="$0"; # Mutterprogramm
. /root/bin/bugem.sh
Dt=DATA; 
ot=opt/turbomed
kopiermt "$ot" "opt/" "" "$OBDEL" PraxisDB/objects.dat 1800
kopieros ".vim" "" "" "" "" "" 1
kopieros ".smbcredentials" "" "" "" "" "" 1
kopieros "crontabakt" "" "" "" "" "" 1
kopieros ".getmail" "" "" "" "" "" 1
kopieros ".7zpassw" "" "" "" "" "" 1
kopieros ".mysqlpwd" "" "" "" "" "" 1
kopieros ".mysqlrpwd" "" "" "" "" "" 1
kopiermt "etc/sysconfig/postfix" "etc/sysconfig" "" "" "" "" 1
for D in main.cf master.cf sasl_passwd; do
  kopiermt "etc/postfix/$D" "etc/postfix" "" "" "" "" 1
done;
V=/root/bin/;ionice -c3 nice -n19 rsync -avu --prune-empty-dirs --include="*/" --include="*.sh" --exclude="*" "$Q$V" "$Z$V"
# kopieros "root/bin" # auskommentiert 29.7.19
# kopieros "root/" # auskommentiert 29.7.19
mountpoint -q /$Dt || mount /$Dt;
ssh $ANDERER mountpoint -q /$Dt 2>/dev/null || ssh $ANDERER mount /$Dt;
if mountpoint -q /$Dt && ssh $ANDERER mountpoint -q /$Dt 2>/dev/null; then
# for uverz in $(find /$Dt/Mail/Thunderbird/Profiles -mindepth 1 -maxdepth 1 -type d); do
 for uverz in Praxis Schade Wagner Kothny Beraterinnen; do
  if test $uverz = Praxis || test $ziel != linux7; then # wegen Speicherplatz auf linux7
   qverz=$Dt/Mail/Thunderbird/Profiles/$uverz;
   find /$qverz -iname INBOX -print0|while IFS= read -r -d '' inbox; do
     [ "$sdneu" ]||echo inbox: "$inbox";
     # eine Woche
		 kopiermt $qverz/ $qverz "" -d "${inbox##/$qverz/}" 604800;
		 break;
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
kopiermt "$VLM/" "${VLM}_1" "" "$OBDEL" ibdata1 86400;
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
echo `date +%Y:%m:%d\ %T` "nach Kopieren" >> $PROT
echo Fertig;
# exit
# echo `date +%Y:%m:%d\ %T` "vor /etc/hosts" >> $PROT
# rsync $Q:/etc/samba $Q:/etc/hosts $Q:/etc/vsftpd*.conf $Q:/etc/my.cnf $Q:/etc/fstab $Z/etc/ -avuz # keine Anführungszeichen um den Stern!
