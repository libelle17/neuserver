#!/bin/zsh
# soll alle relevanten Datenen kopieren, fuer z.B. 2 x täglichen Gebrauch
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bugem.sh
wirt=$ZoD;
. ${MUPR%/*}/virtnamen.sh
# vorher noch den SmartUpdateStandAlone-Dienst auf Zielsystem ausschalten
Dt=DATA; 
USB=1;
altZL=$ZL; ZL=;
altEXFEST=$EXFEST;EXFEST=;
iniKop=1;
[ "$iniKop" ]&&ur=opt||ur=mnt/virtwin;
for V in PraxisDB StammDB DruckDB Dictionary Vorlagen Formulare KVDT Dokumente Daten labor LaborStaber; do
  case $V in PraxisDB|StammDB|DruckDB)testdt="objects.dat";;Dictionary)testdt="_objects.dat";;*)testdt=;;esac;
  case $V in Vorlagen|Formulare|KVDT|Dokumente|Daten|labor|LaborStaber)obOBDEL=;;*)obOBDEL=$OBDEL;;esac;
  kopiermt "$ur/turbomed/$V" "mnt/$gpc/turbomed/" "" "$obOBDEL" "$testdt" "1800" 1; # ohne --iconv
done;
ZL=$altZL;
EXFEST=$altEXFEST;
USB=;
[ "$ZoD"/ = "$HOSTK"/ ]&&exit 0;
# kopiermt "opt/turbomed" ... "" "$OBDEL" PraxisDB/objects.dat 1800
[ "$ZoD/" = linux7/ ]&&obkurz=1||obkurz=;
kopiermt "var/spool" ... "" "" "" "" 1
kopieros ".vim"
kopieros ".smbcredentials"
kopieros "crontabakt"
kopieros ".getmail"
kopieros ".7zpassw"
kopieros ".mysqlpwd"
kopieros ".mysqlrpwd"
kopiermt home/schade/.wincredentials ... "" "" "" "" 1
kopiermt "etc/sysconfig/postfix" ... "" "" "" "" 1
for D in main.cf master.cf sasl_passwd; do
  kopiermt "etc/postfix/$D" ... "" "" "" "" 1
done;
V=/root/bin/;ionice -c3 nice -n19 rsync -avu --prune-empty-dirs --include="*/" --include="*.sh" --exclude="*" "$Q$V" "$ZL$V"
# kopieros "root/bin" # auskommentiert 29.7.19
# kopieros "root/" # auskommentiert 29.7.19
mountpoint -q /$Dt || mount /$Dt;
ssh $ANDERER mountpoint -q /$Dt 2>/dev/null || ssh $ANDERER mount /$Dt;
if mountpoint -q /$Dt && ssh $ANDERER mountpoint -q /$Dt 2>/dev/null; then
# for uverz in $(find /$Dt/Mail/Thunderbird/Profiles -mindepth 1 -maxdepth 1 -type d); do
 for uverz in Praxis Schade Wagner Kothny Beraterinnen; do
  if test $uverz = Praxis || test $ZoD != linux7; then # wegen Speicherplatz auf linux7
   qverz=$Dt/Mail/Thunderbird/Profiles/$uverz;
   find /$qverz -iname INBOX|while IFS= read -r inbox; do
     [ "$sdneu" ]||echo inbox: "$inbox";
     # eine Woche
		 kopiermt $qverz ... "" -d "${inbox##/$qverz/}" 604800;
		 break;
   done;
  fi;
 done;
 for A in eigene\\\ Dateien Patientendokumente turbomed shome sql TMBack rett down DBBack ifap vontosh Oberanger att; do
  auslass=;
  [ $ZoD = linux7 ]&&case $A in sql|TMBack|DBBack|vontosh|Oberanger|att) auslass=1;; esac;
  [ -z $auslass ]&&kopiermt "$Dt/$A" ... "" "$OBDEL";
#  EXCL=${EXCL}",$A/"; # jetzt in kopiermt schon enthalten
 done;
 EXCL=${EXCL}",TMBackloe/,DBBackloe/,sqlloe/,TMExportloe/,Thunderbird/Profiles/,TMBack0/,TMBacka/,VirtualBox/";
 [ "$obkurz" ]&&EXCL=$EXCL",ausgelagert/,Oberanger/,Mail/Sylpheed,Mail/Exp/,Mail/Mail/,lost+found/,szn4vonAlterPlatte/";
 kopiermt "$Dt" "" "$EXCL" "-W $OBDEL";
fi;
exit; # Ende


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
# rsync $QL:/etc/samba $QL:/etc/hosts $QL:/etc/vsftpd*.conf $QL:/etc/my.cnf $QL:/etc/fstab $ZL/etc/ -avuz # keine Anführungszeichen um den Stern!
