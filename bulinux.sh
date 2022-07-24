#!/bin/bash
# dash geht nicht: --exclude={,abc/,def/} wirkt nicht
# soll alle relevanten Datenen kopieren, fuer z.B. 2 x täglichen Gebrauch
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux7, buhost festlegen
[ "$buhost"/ = "$LINEINS"/ ]&&ZL=||QL=$LINEINS;
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
[ "$buhost"/ != "$LINEINS"/ -a "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;}
[ "$buhost"/ = "$LINEINS"/ -a -z "$ZL" ]&&{ printf "${rot}Kein Ziel angegeben. Breche ab$reset.\n";exit;}

# kopiermt "opt/turbomed" ... "" "$OBDEL" PraxisDB/objects.dat 1800
[ "$ZL/" = linux7/ ]&&obkurz=1||obkurz=;
# Faxprotokolle und alte Faxe, Linux-Mails
kopiermt "var/spool" ... "" "" "" "" 1
# Editoreinstellungen
kopieros ".vim"
# Berechtigungen zum Mounten der Fritz-Box als cifs-Laufwerk
kopieros ".smbcredentials"
# aktuelle Kopie dieser Datei
kopieros "crontabakt"
# Verzeichnis für den Mailaufruf in /root
kopieros ".getmail"
# Passwort für Verschlüsselung
kopieros ".7zpassw"
# Passwort für Mysql/Mariadb
kopieros ".mysqlpwd"
# Passwort für Mysql/Mariadb-Superuser
kopieros ".mysqlrpwd"
# Passwort für cifs-Mounts
kopiermt home/schade/.wincredentials ... "" "" "" "" 1
# Konfigurationsdateien für postfix-Mailprogramm
kopiermt "etc/sysconfig/postfix" ... "" "" "" "" 1
for D in main.cf master.cf sasl_passwd; do
  kopiermt "etc/postfix/$D" ... "" "" "" "" 1
done;
# selbst erstellte Scripte
V=/root/bin/;ionice -c3 nice -n19 rsync -avu --prune-empty-dirs --include="*/" --include="*.sh" --exclude="*" "$Q$V" "$ZL$V"
# kopieros "root/bin" # auskommentiert 29.7.19
# kopieros "root/" # auskommentiert 29.7.19
# DATA-Platte auf Quelle und Ziel mounten
Dt=DATA; 
ausf "$qssh 'mountpoint -q /$Dt||mount /$Da'" $blau;
ausf "$zssh 'mountpoint -q /$Dt||mount /$Da'" $blau;
# falls die gemountet sind ...
if $qssh "mountpoint -q /$Dt 2>/dev/null" && $zssh "mountpoint -q /$Dt 2>/dev/null"; then
#  ... dann Mail-Verzeichisse kopieren,
# for uverz in $(find /$Dt/Mail/Thunderbird/Profiles -mindepth 1 -maxdepth 1 -type d); do
 for uverz in Praxis Schade Wagner Kothny Hammerschmidt Beraterinnen; do
  if test $uverz = Praxis -o ! "$obkurz"; then # wegen Speicherplatz auf linux7
   qverz=$Dt/Mail/Thunderbird/Profiles/$uverz;
   find /$qverz -iname INBOX|while IFS= read -r inbox; do
     [ "$sdneu" ]||echo inbox: "$inbox";
     # eine Woche
     [ "$obforce" ]&&testdat=||testdat=${inbox##/$qverz/};
		 kopiermt $qverz ... "" -d "$testdat" 604800;
		 break;
   done;
  fi;
 done;
#  ... sodann die folgenden Verzeichisse: 
 for A in eigene\\\ Dateien Patientendokumente turbomed shome sql TMBack rett down DBBack ifap vontosh Oberanger att; do
  auslass=;
  [ "$obkurz" ]&&case $A in sql|TMBack|DBBack|vontosh|Oberanger|att) auslass=1;; esac;
  [ -z $auslass ]&&kopiermt "$Dt/$A" ... "" "$OBDEL";
#  EXCL=${EXCL}",$A/"; # jetzt in kopiermt schon enthalten
 done;
 EXCL=${EXCL}",TMBackloe/,DBBackloe/,sqlloe/,TMExportloe/,Thunderbird/Profiles/,TMBack0/,TMBacka/,VirtualBox/,VMs/,Documents/";
 [ "$obkurz" ]&&EXCL=$EXCL",ausgelagert/,Oberanger/,Mail/Sylpheed,Mail/Exp/,Mail/Mail/,lost+found/,szn4vonAlterPlatte/,DBBack/,TMBack/";
 kopiermt "$Dt" ... "$EXCL" "-W $OBDEL";
fi;
#  ... aus /etc/my.cnf das mariadb-Datenverzeichnis auslesen
VLM=$(sed -n 's/^[[:space:]]*datadir[[:space:]]*=[[:space:]]*\(.*\)/\1/p' /etc/my.cnf)
[ "$obforce" ]&&testdat=||testdat=ibdata1;
#  ... und kopieren:
exit; # Ende

$zssh systemctl stop mysql; 
$zssh systemctl disable mysql; 
kopiermt "$VLM/" "${VLM}_1" "" "$OBDEL" $testdat 86400;
$zssh systemctl start mysql; 
$zssh systemctl enable mysql; 


# kopieretc "samba" # auskommentiert 29.7.19
# kopieretc "hosts" # hier muesste noch eine Zeile geaendert werden!
# kopieretc "vsftpd.conf" # auskommentiert 29.7.19
# kopieretc "my.cnf" # auskommentiert 29.7.19
# kopieretc "fstab.cnf" # auskommentiert 29.7.19
kopiermt "gerade" "/" "" "$OBDEL"
kopiermt "ungera" "/" "" "$OBDEL"
# VLM="var/lib/mysql";
VLM=$(sed -n 's/^[[:space:]]*datadir[[:space:]]*=[[:space:]]*\(.*\)/\1/p' /etc/my.cnf)
[ "$obforce" ]&&testdat=||testdat=ibdata1;
kopiermt "$VLM/" "${VLM}_1" "" "$OBDEL" $testdat 86400;
# kopieretc "openvpn" # auskommentiert 29.7.19
scp $PROT $ANDERER:/var/log/
if mountpoint -q /$Dt && ssh $ANDERER mountpoint -q /$Dt 2>/dev/null; then
 scp $PROT $ANDERER:/$Dt/
fi;
if [ "$buhost"/ != "$LINEINS"/ ]; then
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
