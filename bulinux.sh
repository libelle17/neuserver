#!/bin/bash
# dash geht nicht: --exclude={,abc/,def/} wirkt nicht
# soll alle relevanten Datenen kopieren, fuer z.B. 2 x täglichen Gebrauch
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1ur, buhost festlegen # ./bul1.sh
[ "$buhost"/ = "$LINEINS"/ ]&&ZL=||QL=$LINEINS;
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen # ./bugem.sh
# Falls -q gesetzt: Quellrechner explizit, Zielrechner = lokal
# Überschreibt die Logik aus bul1.sh:
[ "$QL" -a "$QL" != "$LINEINS" -a -z "$ZL" ]&&{
  printf "Explizite Quelle: ${blau}$QL${reset} → Ziel: ${blau}lokal${reset}\n";
  # qssh/zssh werden in bugem.sh nach commandline() gesetzt – hier nochmal überschreiben:
  qssh="ssh $QL";
  zssh="sh -c";
  QmD="$QL:";
  ZmD=;
};
[ "$buhost"/ != "$LINEINS"/ -a "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;ZmD=;}
[ "$buhost"/ = "$LINEINS"/ -a -z "$ZL" ]&&{ printf "${rot}Kein Ziel angegeben. Breche ab$reset.\n";exit;}
# kopiermt "opt/turbomed" ... "" "$OBDEL" PraxisDB/objects.dat 1800
mkos=true;
kopweit=true;
if $mkos; then
# auf Rechner mit kleinen Platten weniger kopieren
case "$ZL" in *3|*7|*8)oburz=1;; *)obkurz=;;esac;
# Faxprotokolle und alte Faxe, Linux-Mails
kopiermt "var/spool" ... "" "" "" "" 1
# Editoreinstellungen
kopieros ".vim"
# Berechtigungen zum Mounten der Fritz-Box als cifs-Laufwerk
kopieros ".fbcredentials"
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
kopieros ".sturm"
# Konfigurationsdateien für postfix-Mailprogramm
kopiermt "etc/sysconfig/postfix" ... "" "" "" "" 1
for D in main.cf master.cf sasl_passwd; do
  kopiermt "etc/postfix/$D" ... "" "" "" "" 1
done;
# selbst erstellte Scripte
V=/root/bin/;
altverb=$verb;
verb=1;
if [ "$obecht" ]; then
  ausf "$kopbef -avu $ergae --prune-empty-dirs --include='*/' --include='*.sh' --exclude='*' '$QmD$V' '$ZmD$V'" $dblau;
else
  printf "Befehl wäre: $dblau$kopbef -avu $ergae --prune-empty-dirs --include='*/' --include='*.sh' --exclude='*' '$QmD$V' '$ZmD$V'$reset\n";
fi;
fi; # $mkos
verb=$altverb;
# fi;
# kopieros "root/bin" # auskommentiert 29.7.19
# kopieros "root/" # auskommentiert 29.7.19
# DATA-Platte auf Quelle und Ziel mounten
Dt=DATA; 
# $DATAZIEL aus bul1.sh – Zielverzeichnis für /DATA-Kopien:
[ "$DATAZIEL" ] || DATAZIEL=DATA; # Fallback falls bul1.sh alt
DtZ=$DATAZIEL; # Ziel-Äquivalent von $Dt
machssh;
ausf "$qssh 'mountpoint -q /$Dt||mount /$Dt'" $blau;
ausf "$zssh 'mountpoint -q /$DtZ||{ mountpoint -q /$Dt||mount /$Dt;}'" $blau;
# falls die gemountet sind ...
if $qssh "mountpoint -q /$Dt 2>/dev/null" && \
 { $zssh "mountpoint -q /$DtZ 2>/dev/null" || $zssh "test -d /$DtZ 2>/dev/null"; }; then
	if $kopweit; then
  mountpoint -q /mnt/wser/mosich||mount /mnt/wser/mosich
  mountpoint -q /mnt/wser/mosich&&{
    mouvz=$(find /mnt/wser/mosich -maxdepth 1 -name "2*" -type d | sort -r | head -1);
    mouvz=${mouvz#/};  # führendes / entfernen
		if [ "$obecht" ]; then
			$zssh "mkdir -p /$DtZ/MO/Sich";
			$zssh "mkdir -p /$DtZ/MO/INDAMED";
		else
			printf "Simulation: mkdir -p /$DtZ/MO/Sich\n";
			printf "Simulation: mkdir -p /$DtZ/MO/INDAMED\n";
		fi;
		kopiermt "$mouvz"/ /$DtZ/MO/Sich/ "" "" "" 0 1 1
		kopiermt mnt/wser/mosich/my.ini /$DtZ/MO/Sich/ "" "" "" 0 1 1
		kopiermt mnt/wser/indamed/ /$DtZ/MO/INDAMED/ ",dat/,redomed/,Backup/" "" "" 0 1
		mostat=$(ssh linux1 ls -t /mnt/wser/indamed/dat/MOSTAT*.gdb|head -n1);
		if test -n "$mostat"; then
			kopiermt ${mostat:1} /$DtZ/MO/INDAMED/dat/ "" "" "" 0 1
		fi
		kopiermt mnt/wser/indamed/dat/medoffDB /$DtZ/MO/INDAMED/dat/ "" "" "" 0 1
		kopiermt mnt/wser/indamed/dat/files /$DtZ/MO/INDAMED/dat/ "" "" "" 0 1
	}
	if ssh linux1 mountpoint -q /mnt/anmmw; then
		kopiermt mnt/anmmw/users/sturm/Documents/Outlook-Dateien /$DtZ/Mail/out "" "" diabetologie@dachau-mail.de.pst 43200 1
	fi;
# kopiermt() { # mit test
  # $1 = Verzeichnis auf Quelle
  # $2 = Verzeichnis auf Ziel
  # $3 = excludes
  # $4 = Optionen 
	# $5 = Pfad zur Datei, die als Alterskriterium geprüft werden soll
	# $6 = Zahl der Sekunden Altersunterschied, ab der kopiert werden soll
  # $7 = ob ohne Platzprüfung
  # $8 = ob ohne Schutzdateivergleich
  # vorher müssen ggf. Quellrechner in $QL (z.Zt. nur: leer oder linux1ur) und Zielrechner in $ZL hinterlegt sein

#  ... dann Mail-Verzeichisse kopieren,
# for uverz in $(find /$Dt/Mail/Thunderbird/Profiles -mindepth 1 -maxdepth 1 -type d); do
 for uverz in Praxis Schade Kothny Hammerschmidt Beraterinnen; do
  if test $uverz = Praxis -o ! "$obkurz"; then # wegen Speicherplatz auf linux7
   qverz=$Dt/Mail/Thunderbird/Profiles/$uverz;
	 $qssh "find /$qverz -iname INBOX" |while IFS= read -r inbox; do
     [ "$sdneu" ]||echo inbox: "$inbox";
     # eine Woche
     [ "$obforce" ]&&testdat=||testdat=${inbox##/$qverz/};
		 kopiermt $qverz ... "" -d "$testdat" 604800;
		 break;
   done;
  fi;
 done;
 fi; # kopweit
#  ... sodann die folgenden Verzeichisse: 
# for A in sql; do
 for A in eigene\\\ Dateien Patientendokumente turbomed shome TMBack rett down DBBack ifap vontosh Oberanger att sql; do
  auslass=;
  [ "$obkurz" ]&&case $A in sql|TMBack|DBBack|vontosh|Oberanger|att) auslass=1;; esac;
	[ -z $auslass ]&&kopiermt "$Dt/$A" "$DtZ/$A/" "" "$OBDEL";
#  EXCL=${EXCL}",$A/"; # jetzt in kopiermt schon enthalten
	if [ "$A"/ = sql/ ]; then
		if [ "$obecht" ]; then
			$zssh "if systemctl list-units --full -all|grep -q 'mariadb.service.*running';then los.sh mysqli;fi;";
		else
			printf "Simulation: los.sh mysqli auf $ZL falls mariadb läuft\n";
		fi;
	fi;
 done;
 EXCL=${EXCL}",TMBackloe/,DBBackloe/,sqlloe/,TMExportloe/,Thunderbird/Profiles/,TMBack0/,TMBacka/,VirtualBox/,VMs/,Documents/,mp4/";
 [ "$obkurz" ]&&EXCL=$EXCL",ausgelagert/,Oberanger/,Mail/Sylpheed,Mail/Exp/,Mail/Mail/,lost+found/,szn4vonAlterPlatte/,DBBack/,TMBack/";
 kopiermt "$Dt" "$DtZ/" "$EXCL" "-W $OBDEL";
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
gutenacht;
[ "$verb" ]&&printf "\n${rot} ziemlich am Schluss von $MUPR$reset\n";
