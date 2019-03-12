#!/bin/sh
blau="\e[1;34m";
dblau="\e[0;34;1;47m";
rot="\e[1;31m";
reset="\e[0m";
prog="";
obnmr=1;
ftb=/etc/fstab;

setzhost() {
printf "${dblau}setzhost$reset()\n";
# wenn Hostname z.B. linux-8zyu o.ä., dann korrigieren;
case $(hostname) in
*-*) {
		hostnamectl;
		printf "${blau}gewünschter Servername, dann Enter:$reset"; read SERVER;
		hostnamectl set-hostname "$SERVER";
		export HOST="$SERVER";
		hostnamectl; 
};
esac;
}

setzbenutzer() {
printf "${dblau}setzbenutzer$reset()\n";
grep -q "^praxis:" /etc/group||groupadd praxis
$SPR samba 2>/dev/null||$IPR samba
systemctl start smb 2>/dev/null||systemctl start smbd 2>/dev/null;
systemctl enable smb 2>/dev/null||systemctl enable smbd 2>/dev/null;
systemctl start nmb 2>/dev/null||systemctl start nmbd 2>/dev/null;
systemctl enable nmb 2>/dev/null||systemctl enable nmbd 2>/dev/null;
while read -r zeile <&3; do
	user=${zeile%% \"*};
	comm=\"${zeile#* \"};
	pruefuser $user "$comm";
done 3< benutzer;
}

mountlaufwerke() {
printf "${dblau}Hänge Laufwerke ein$reset()\n";
# Laufwerke einhängen
# in allen nicht auskommentierten Zeilen Leerzeichen durch einen Tab ersetzen
fstb=$(sed -n '/^#/!{s/[[:space:]]\+/\t/g;p}' $ftb); # "^/$Dvz\>" ginge auch
blkvar=$(lsblk -bisnPfo NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -x SIZE|grep -v 'raid_member\|FSTYPE="" LABEL=""\|FSTYPE="swap"');
# bisherige Labels DATA, DAT1 usw. und bisherige Mounpoints /DATA, /DAT1 usw. ausschließen 
# z.B. "2|1|3|A"
bishDAT=$(echo "$blkvar"|awk '/=\"DAT/{printf substr($4,11,length($4)-11)"|";}/=\"\/DAT/{printf substr($6,16,length($4)-16)"|";}'|awk '{print substr($0,0,length($0)-1);}');
bishwin=$(echo "$blkvar"|awk '/=\"win/{printf substr($4,11,length($4)-11)"|";}/=\"\/win/{printf substr($4,16,length($4)-16)"|";}'|awk '{print substr($0,0,length($0)-1);}');
istinfstab=0;
Dnamnr="A"; # 0=DATA, 1=DAT1, 2=DAT2 usw # linux name nr
wnamnr=1;
# Laufwerke mit bestimmten Typen und nicht-leerer UUID absteigend nach Größe
while read -r zeile; do
#	echo "Hier: " $zeile;
	dev=$(echo $zeile|cut -d\" -f2);
	typ=$(echo $zeile|cut -d\" -f6);
	nam=$(echo $zeile|cut -d\" -f8);
	if test -z "$nam"; then
		case "$typ" in ext*|btrfs|reiserfs|ntfs*|exfat*|vfat)
			case "$typ" in 
				ext*|btrfs|reiserfs)
					while :;do	
						abbruch=0;
						# wenn der geplante Buchstabe noch nicht vergeben: Abbruch von while planen
						[ -z "$bishDAT" ]&&abbruch=1|| eval "case "$Dnamnr" in "$bishDAT"):;;*)false;;esac;"||abbruch=1;
						[ "$Dnamnr" = "A" ]&&Dnamnr=1||Dnamnr=$(expr $Dnamnr + 1 );
						[ $abbruch -eq 1 ]&&break;
					done;
					nam="DAT"$Dnamnr;;
				ntfs*|exfat*|vfat)
					while :;do	
						abbruch=0;
						[ -z "$bishwin" ]&&abbruch=1|| eval "case "$wnamnr" in "$bishwin"):;;*)false;;esac;"||abbruch=1;
						wnamnr=$(expr $wnamnr + 1 );
						[ $abbruch -eq 1 ]&&break;
					done;
					nam="win"$wnamnr;;
			esac;
			case typ in 
				ext*)
					echo e2label /dev/$dev "$nam";
					e2label /dev/$dev "$nam";;
				btrfs)
					echo btrfs filesystem label /dev/$dev "$nam";
					btrfs filesystem label /dev/$dev "$nam";;
				reiserfs)
					echo reiserfstune -l "$nam" /dev/$dev;
					reiserfstune -l "$nam" /dev/$dev;;
				ntfs*)
					echo ntfslabel /dev/$dev "$nam";
					ntfslabel /dev/$dev "$nam";;
				exfat*)
					echo exfatlabel /dev/$dev "$nam";
					exfatlabel /dev/$dev "$nam";;
				vfat)
					echo mache vfat Label;
					eingehaengt=0;
					mountpoint -q /dev/$dev&&{ eingehaengt=1; umount /dev/$dev;};
					env MTOOLS_SKIP_CHECK=1 mlabel -i /dev/$dev ::x;
					dosfslabel /dev/$dev "$nam";
					test $eingehaengt -eq 1&&mount /dev/$dev;;
			esac;
    esac;
	fi;
	mtp=$(echo $zeile|cut -d\" -f12|sed 's/[[:space:]]//g');
	# echo "mtp: \"$mtp\"";
	[ -z "$mtp" ]&&mtp="/"$nam;
	byt=$(echo $zeile|cut -d\" -f4);
	uid=$(echo $zeile|cut -d\" -f10);
	[ "$mtp" -a ! -d "$mtp" ]&&mkdir "$mtp";
	if test -z "$nam"; then
		ident="UUID="$uid;
	else 
		ident="LABEL="$nam;
	fi;
	idohnelz=$(printf "$ident"|sed 's/[[:space:]]/\\\\040/g');
	obinfstab "$idohnelz" "$uid" "$dev";
	printf "Mountpoint: $blau$mtp$reset istinfstab: $blau$istinfstab$reset\n";
	if test $istinfstab -eq 0; then
		eintr="\t $mtp\t $typ\t user,acl,user_xattr,exec,nofail,x-systemd.device-timeout=15\t 1\t 2"
		if test "$typ" = "ntfs"; then
			eintr="\t $mtp\t ntfs-3g	 user,users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail,x-systemd.device-timeout=15	 1	 2";
		fi;
		eintr=$idohnelz$eintr;
		printf "$eintr\n" >>$ftb;
		printf "\"$blau$eintr$reset\" in $blau$ftb$reset eingetragen.\n";
	fi;
	#   altbyt=$byt; byt=$(echo $z|cut -d' ' -f2); [ "$byt" -lt "$altbyt" ]&&gr=ja||gr=nein; echo "      byt: "$byt "$gr";
done << EOF
$(lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -b -i -x SIZE -s -n -P -f|grep -v ':\|swap\|efi\|fat\|iso\|FSTYPE=""\|UUID=""'|tac) 
EOF
  mount -a;
  awk '/^[^#;]/ && !/ swap /{printf "%s ",$1;system("mountpoint "$2);}' $ftb;
}

pruefuser() {
	printf "${dblau}pruefuser$reset($1)\n";
		id -u "$1" >/dev/null 2>&1 &&obu=0||obu=1;
		pdbedit -L|grep "^$1:" &&obs=0||obs=1;
		passw="";
		if test $obu -eq 1 -o $obs -eq 1; then {
			while test -z "$passw"; do
				printf "Bitte gewünschtes Passwort für Linux-Benutzer $blau$1$reset eingeben: "; read passw;
			done;
		} fi;
		if test $obu -eq 1; then {
			printf "erstelle Linux-Benutzer $blau$1$reset\n";
			useradd -p $(openssl passwd -1 $passw) -c"$2" -g praxis "$1"; # zuweisen:  passwd "$1"; # loeschen: userdel $1;
		} fi;
		if test $obs -eq 1; then {
				printf "erstelle Samba-Benutzer $blau$1$reset\n"; # loeschen: pdbedit -x -u $1;
				printf "$passw\n$passw"|smbpasswd -as $1; # pruefen: smbclient -L //localhost/ -U $1
		} fi;
}

obinfstab() {
	printf "${dblau}obinfstab$reset($blau$1$reset, $blau$2$reset, $blau$3$reset)\n";
	istinfstab=0;
	while read -r zeile; do
		# echo "dort: $zeile;"
		vgl=$(printf "$zeile"|cut -f1|sed 's/ /\\\\040/g')
		# z.B.  LABEL=Seagate\040Expansion\040Drive
		if test "$vgl" = "$(echo $(echo $1)|sed 's/ //g')"; then istinfstab=1; break; fi;
#		printf "vgl: $rot$vgl$reset\n";
		if test "$vgl" = "UUID=$2";then istinfstab=1; break; fi;
		if test "$vgl" = "/dev/$3";then istinfstab=1; break; fi;
		for dbid in $(find /dev/disk/by-id -lname "*$3"); do
			if test "$vgl" = "$dbid";then istinfstab=1; break; fi;
		done;
		if test $istinfstab -eq 1; then break; fi;
	done << EOF
$fstb
EOF
#[ $istinfstab -eq 0 ]&&printf "(echo (echo 1..: $rot$(echo $(echo $1)|sed 's/ //g')$reset\n";
}

obprogda() {
	printf "${dblau}obprogda$reset(${blau}$1$reset)\n";
 prog="";
 for verz in /usr/local/bin /usr/bin /usr/local/sbin /usr/sbin /sbin /bin /usr/libexec /run; do
	 prog="$verz/$1";
	 if test -f "$prog"; then return 0; fi;
 done;
 prog=$(which "$1" 2>/dev/null);
 if test -f "$prog"; then return 0; fi;
 return 1;
}

setzinstprog() {
	printf "${dblau}setzinstprog$reset()\n"
case $OSNR in
	1|2|3)
		S=/etc/apt/sources.list;F='^[^#]*cdrom:';grep -qm1 $F $S && test 0$(sed -n '/^[^#]*ftp.*debian/{=;q}' $S) -gt 0$(sed -n '/'$F'/{=;q}' $S) && 
					ping -qc 1 www.debian.org >/dev/null 2>&1 && sed -i.bak '/'$F'/{H;d};${p;x}' $S;:;
		psuch="dpkg -s "; # dpkg -l wuerde zwar genauer anzeigen, aber errorlevel nicht abhängig vom Installtationszustand
		instp="apt-get install";
		instyp="apt-get -y --force-yes --reinstall install ";
		upr="apt-get -f install;apt-get --auto-remove purge ";
		udpr="apt-get -f install;dpkg -r --force-depends ";
		uypr="apt-get -f install;apt-get -y --auto-remove purge ";
		upd="apt update;apt upgrade;";
		compil="install build-essential linux-headers-`uname -r`";
		dev="dev";;
	4|5|6|7)
		psuch="rpm -q ";
		dev="devel";
		udpr="rpm -e --nodeps ";
		case $OSNR in
			4)
				instp="zypper -n --gpg-auto-import-keys in ";	
				instyp=$instp" -y -f ";
				upr="zypper -n rm -u ";
				uypr=$upr" -y ";
				upd="zypper patch";
				repos="zypper lr | grep 'g++\\|devel_gcc'>/dev/null 2>&1 ||zypper ar http://download.opensuse.org/repositories/devel:";
				repos="${repos}/gcc/`cat /etc/*-release |grep ^NAME= | cut -d'\"' -f2 | sed 's/ /_/'`";
				repos="${repos}_`cat /etc/*-release | grep ^VERSION_ID= | cut -d'\"' -f2`/devel:gcc.repo;";
				compil="gcc gcc-c++ gcc6-c++";;
			5)
				instp="dnf install ";
				instyp="dnf -y install ";
				upr="dnf remove ";
				uypr="dnf -y remove ";
				upd="dnf update";;
			6)
				instp="yum install ";
				instyp="yum -y install ";
				upr="yum remove ";
				uypr="yum -y remove ";
				upd="yum update";;
			7)
				instp="urpmi --auto ";
				instyp=$instp"--force ";
				upr="urpme ";
				uypr=$upr"--auto --force ";
				upd="urpmi.update -a";;
		esac;
		compil="make automake gcc-c++ kernel-devel";;
	8)
		psuch="pacman -Qi";
		instp="pacman -S ";
		instyp=$instp"--noconfirm ";
		upr="pacman -R -s ";
		uypr=$upr"--noconfirm "; 
		udpr="pacman -R -d -d ";
		upd="pacman -Syu";
		compil="gcc linux-headers-`uname -r`";;
esac;
}

ersetzeprog() {
	printf "${blau}ersetzeprog($reset$1): -> "
	sprog="";
	eprog=$1;
	while true; do
	case $OSNR in
	1|2|3) # mint, ubuntu, debian
		if [ "$1" = mariadb ]; then eprog="mariadb-server"; break; fi;
		if [ "$1" = hylafax ]; then eprog="hylafax-server"; break; fi;
		if [ "$1" = "hylafax+" ]; then eprog="hylafax+-server"; break; fi;
		if [ "$1" = "hylafax hylafax-client" ]; then eprog="hylafax-server hylafax-client"; break; fi;
		if [ "$1" = "hylafax+ hylafax+-client" ]; then eprog="hylafax+-server hylafax+-client"; break; fi;
		if [ "$1" = "kernel-source" ]; then eprog="linux-source-$(uname -r|cut -d. -f1,2)"; break; fi;
		if [ "$1" = tiff ]; then eprog="libtiff-tools"; break; fi;
		if [ "$1" = "libxslt-tools" ]; then eprog="xsltproc"; break; fi;
		if [ "$1" = imagemagick ]; then eprog="imagemagick imagemagick-doc"; break; fi;
		if [ "$1" = "libreoffice-base" ]; then eprog="libreoffice-common libreoffice-base"; break; fi;
		if [ "$1" = "libcapi20-2" ]; then eprog="libcapi20-dev"; break; fi;
		if [ "$1" = "tesseract-ocr-traineddata-english" ]; then eprog="tesseract-ocr-eng"; break; fi;
		if [ "$1" = "tesseract-ocr-traineddata-german" ]; then eprog="tesseract-ocr-deu"; break; fi;
		if [ "$1" = "tesseract-ocr-traineddata-orientation_and_script_detection" ]; then eprog="tesseract-ocr-osd"; break; fi;
		if [ "$1" = "poppler-tools" ]; then eprog="poppler-utils"; break; fi;
		if [ "$1" = "boost-devel" ]; then eprog="libboost-dev libboost-system-dev libboost-filesystem-dev"; break; fi;
		if [ "$1" = "openssh" ]; then eprog="openssh-server openssh-client"; break; fi;
		eprog=$(echo "$eprog"|sed 's/-devel/-dev/g');
		;;
	5|6) # fedora, fedoraalt
		if [ "$1" = mariadb ]; then eprog="mariadb-server"; break; fi;
		if [ "$1" = "kernel-source" ]; then eprog="kernel-devel-$(uname -r)"; break; fi;
		if [ "$1" = "libwbclient0" ]; then eprog="libwbclient"; break; fi;
		if [ "$1" = tiff ]; then eprog="libtiff-tools"; break; fi;
		if [ "$1" = libtiff5 ]; then eprog="libtiff"; break; fi;
		if [ "$1" = "libcapi20-2" ]; then eprog="isdn4k-utils"; break; fi;
		if [ "$1" = "libcapi20-3" ]; then eprog=""; break; fi;
		if [ "$1" = "capiutils" ]; then eprog=""; break; fi;
		if [ "$1" = imagemagick ]; then eprog="ImageMagick ImageMagick-doc"; break; fi;
		if [ "$1" = "libxslt-tools" ]; then eprog="libxslt"; break; fi;
		if [ "$1" = "libreoffice-base" ]; then eprog="libreoffice-filters libreoffice-langpack-de"; break; fi;
		if [ "$1" = "tesseract-ocr" ]; then eprog="tesseract"; break; fi;
		if [ "$1" = "tesseract-ocr-traineddata-english" ]; then eprog=""; break; fi;
		if [ "$1" = "tesseract-ocr-traineddata-german" ]; then eprog="tesseract-langpack-deu tesseract-langpack-deu_frak"; break; fi;
		if [ "$1" = "tesseract-ocr-traineddata-orientation_and_script_detection" ]; then eprog=""; break; fi;
		if [ "$1" = "poppler-tools" ]; then eprog="poppler-utils"; break; fi;
		if [ "$1" = "openssh" ]; then eprog="openssh openssh-server openssh-clients"; break; fi;
		;;
	4) # suse
		if [ "$1" = "redhat-rpm-config" ]; then eprog=""; break; fi;
		if [ "$1" = "kernel-source" ]; then eprog="kernel-devel"; break; fi;
		if [ "$1" = "libffi-devel" ]; then eprog="libffi$(gcc --version|head -n1|sed "s/.*) \(.\).\(.\).*/\1\2/")-devel"; break; fi;
		;;
	8) # manjaro
		if [ "$1" = "libwbclient0" ]; then eprog="libwbclient"; break; fi;
		;;
 esac;
 break;
 done;
 [ -z "$eprog" ]&&eprog="$1";
 [ -z "$sprog" ]&&sprog="$eprog";
 printf " $sprog\n";
}

doinst() {
	printf "${blau}doinst()$reset: $1\n"
	ersetzeprog "$1";
	[ "$2" ]&&obprogda "$2"&&return 0;
#	printf "eprog: $blau$eprog$reset sprog: $blau$sprog$reset\n";
	for prog in "$1"; do
		$psuch "$prog" >/dev/null 2>&1&&return 0;
		printf "installiere $blau$prog$reset\n";
		if [ $OSNR -eq 4 -a $obnmr -eq 1 ]; then
			obnmr=0;
			zypper mr -k --all;
		fi;
		$instp "$prog";
	done;
}

instmaria() {
	printf "${blau}instmaria()$reset\n"
	case $OSNR in
		1|2|3)
			apt-get -y install apt-transport-https;
			apt-get update && DEBIAN_FRONTEND=noninteractive apt-get --reinstall install -y mariadb-server;;
		*)
			doinst mariadb;
			if [ $OSNR -eq 8 ]; then
				mysql_install_db --user="$mysqlben" --basedir=/usr/ --ldata=/var/lib/mysql;
			fi;;
	esac;
}

mariadb() {
	printf "${blau}mariadb()$reset\n"
	# Mariadb
	case $OSNR in
		1|2|3)
			db_systemctl_name="mysql";;
		4|5|6|7)
			db_systemctl_name="mariadb";;
	esac;
	for iru in 1 2; do
		systemctl is-enabled $db_systemctl_name >/dev/null 2>&1 ||systemctl enable $db_systemctl_name;
		systemctl start $db_systemctl_name >/dev/null 2>&1;
		installiert=1;
		mysqld="mysqld";
		mysqlben="mysql";
		mysqlbef="mysql";
		! find /usr/sbin /usr/bin /usr/libexec -executable -size +1M -name "$mysqld" 2>/dev/null|grep -q .&&installiert=0;
		[ $installiert -eq 1 ]&& obprogda $mysqlbef || installiert=0;
		[ $installiert -eq 1 ]&& grep -q "^$mysqlben" /etc/passwd || installiert=0;
		[ $installiert -eq 1 ]&& $mysqlbef -V >/dev/null|| installiert=0;
		[ $installiert -eq 1 ]&&break;
		instmaria;
	done;
	if [ $installiert -eq 1 ]; then
		datadir=$(sed 's/#.*$//g' $($mysqlbef --help|sed -n '/Default options/{n;p}') 2>/dev/null|grep datadir|cut -d= -f2|sed 's/^[[:space:]]*//'|tail -n1);
		if [ -z "$datadir" ]; then
			mycnfpfad=$(find /etc /etc/mysql $MYSQL_HOME -name my.cnf -printf '%p\n' -quit 2>/dev/null);
			[ -z "$mycnfpfad" ]&&mycnfpfad=$(find $HOME -name .my.cnf -printf '%p\\n' -quit);
			if [ "$mycnfpfad" ]; then
				for aktdir in $(sed 's/#.*$//g' "$mycnfpfad"| grep '!includedir' | sed 's/^[ \t]//g' | cut -d' ' -f2-);do
					mycnfpfad="$myconfpfad $(find $aktdir -not -type d)";
				done;
			fi;
			for aktzz in $mycnfpfad; do
				datadir=$(sed 's/#.*$//g' "$aktzz"|grep datadir|cut -d= -f2|sed 's/^[[:space:]]*//'|tail -n1);
				[ "$datadir" ]&&break;
			done;
		fi;
		[ -z "$datadir" ]&&datadir="/var/lib/mysql";
		[ -e "$datadir" -a ! -d "$datadir" ]&&rm -f "$datadir";
		if ! [ -d $datadir ]; then
			echo rufe mysql_install_db auf
			$(find /usr/local /usr/bin /usr/sbin -name mysql_install_db 2>/dev/null);
			systemctl start mysql;
		fi;
		while mysql -e'\q' 2>/dev/null; do
			mroot="";
			while [ -z $mroot ]; do
				printf "Admin für mysql: ";[ $obbash -eq 1 ]&&read -rei root mroot||read mroot;
			done;
			mrpwd="";
			while [ -z $mrpwd ]; do
				printf "Passwort für '$mroot': ";read mrpwd;
				# hier könnten noch Einträge wie "plugin-load-add=cracklib_password_check.so" in "/etc/my.cnf.d/cracklib_password_check.cnf" 
				# auskommentiert werden und der Service neu gestartet werden
			done;
			echo "mysql -u"$mroot" -hlocalhost -e 'GRANT ALL ON *.* TO '$mroot'@'localhost' IDENTIFIED BY '$mrpwd' WITH GRANT OPTION'";
			mysql -u"$mroot" -hlocalhost -e "GRANT ALL ON *.* TO '$mroot'@'localhost' IDENTIFIED BY '$mrpwd' WITH GRANT OPTION";
			echo "mysql -u"$mroot" -hlocalhost -p"$mrpwd" -e 'GRANT ALL ON *.* TO '$mroot'@'%' IDENTIFIED BY '$mrpwd' WITH GRANT OPTION'";
			mysql -u"$mroot" -hlocalhost -p"$mrpwd" -e "GRANT ALL ON *.* TO '$mroot'@'%' IDENTIFIED BY '$mrpwd' WITH GRANT OPTION";
			mysql -u"$mroot" -hlocalhost -p"$mrpwd" -e "SET NAMES 'utf8' COLLATE 'utf8_unicode_ci'";
		done;
		user="";
		while [ -z "$user" ];do
			#			echo $0 $SHELL $(ps -p $$ | awk '$1 != "PID" {print $(NF)}') $(ps -p $$) $(ls -l $(which sh));
			printf "Mariadb Standardbenutzer: ";[ $obbash -eq 1 ]&&read -rei praxis user||read user;
		done;
		pwd="";
		while [ -z "$pwd" ];do
			read -p "Mariadb: Passwort für '$user': " pwd;
		done;
		if mysql -u"$user" -p"$pwd" -e'\q' 2>/dev/null; then
			echo Benutzer "$user"  war schon eingerichtet;
		else
			echo "mysql -u"$mroot" -hlocalhost -p"$mrpwd" -e 'GRANT ALL on *.* TO '$user'@'localhost' IDENTIFIED BY '$pwd' WITH GRANT OPTION'";
			mysql -u"$mroot" -hlocalhost -p"$mrpwd" -e "GRANT ALL on *.* TO '$user'@'localhost' IDENTIFIED BY '$pwd' WITH GRANT OPTION";
			echo "mysql -u"$mroot" -hlocalhost -p"$mrpwd" -e 'GRANT ALL on *.* TO '$user'@'%' IDENTIFIED BY '$pwd' WITH GRANT OPTION'";
			mysql -u"$mroot" -hlocalhost -p"$mrpwd" -e "GRANT ALL on *.* TO '$user'@'%' IDENTIFIED BY '$pwd' WITH GRANT OPTION";
		fi;
		echo datadir: $datadir;
		echo user: $user;
		echo Jetzt konfigurieren;
	fi;
	echo installiert: $installiert;
}

proginst() {
	printf "${dblau}proginst$reset()\n"
	setzinstprog;
	# fehlende Programme installieren
	doinst htop;
	doinst vsftpd;
	doinst openssh;
# putty auch fuer root erlauben:
	D=/etc/ssh/sshd_config;
	W=PermitRootLogin;
	if ! grep "^$W[[:space:]]*Yes$" $D; then
		if grep "^$W" $D; then
			sed -i "/^$W/c$W Yes" $D;
		elif grep "^#$W" $D; then
			sed -i "/^#$W/a$W Yes" $D;
		fi;
	fi;

	case $OSNR in
	1|2|3) # mint, ubuntu, debian
		sshd=ssh;;
	4|5|6|7) # opensuse, fedora, mageia
		sshd=sshd;;
	esac;
	systemctl enable $sshd;
	systemctl restart $sshd;
	mariadb;
	doinst git;
}

nichtroot() {
	printf "${dblau}nichtroot$reset()\n"
	if test "$(id -u)" -ne 0; then
		if test "$DESKTOP_SESSION" = "gnome" -o "$DESKTOP_SESSION" = "gnome-classic"; then
			gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 40;
			gsettings set org.gnome.desktop.peripherals.keyboard delay 200;
		fi;
		if [ "$DESKTOP_SESSION" = cinnamon ]; then
			gsettings set org.cinnamon.settings-daemon.peripherals.keyboard repeat-interval 40;
			gsettings set org.cinnamon.settings-daemon.peripherals.keyboard delay 200;
		fi;
	fi;
	if [ "$WINDOWMANAGER" = /usr/bin/startkde ]; then
		DNam=kcminputrc;
		D=~/.config/$DNam;
		[ -f $D ]||D=/etc/xdg/$DNam;
		RD="RepeatDelay=";
		rd=210;
		RR="RepeatRate=";
		rr=27;
		if ! grep -q "$RD$rd" "$D" || ! grep -q "$RR$rr" "$D"; then
			echo editiere $D;
			sed -i "s/^\($RD\).*/\1$rd/;s/^\($RR\).*/\1$rr/" "$D";
			#  { export DISPLAY=:0;xauth add $DISPLAY . hexkey;};
			if test "$DISPLAY"; then 
				echo DISPLAY: $DISPLAY
				echo xset r rate $rd $rr;
				xset r rate $rd $rr;
			fi;
		fi;
	fi;
}

sambaconf() {
	printf "${dblau}sambaconf$reset()\n"
	dire="/etc/samba";[ -d "$dire" ]||mkdir -p /etc/samba;
	smbdt="/etc/samba/smb.conf";
	muster="/usr/share/samba/smb.conf";
	workgr=$(sed -n '/WORKGROUP/{s/[^"]*"[^"]*"[^"]*"\([^"]*\)".*/\1/p}' smbvars.sh);
	printf "Arbeitsgruppe des Sambaservers: ";[ $obbash -eq 1 ]&&read -rei "$workgr" arbgr||read arbgr;
	[ "$arbgr"z = "$workgr"z ]||sed -i '/WORKGROUP/{s/\([^"]*"[^"]*"[^"]*"\)[^"]*\(.*\)/\1'$arbgr'\2/}' smbvars.sh;
	[ ! -f "$smbdt" -a -f "$muster" ]&&{ echo cp -ai "$muster" "$smbdt";cp -ai "$muster" "$smbdt";};
	S2=smbab.sh; # Samba-Abschnitte, wird dann ein Include für smbd.sh (s.u)
	echo "BEGIN {" >$S2;
	nr=0;
	while read -r zeile; do
		printf "fstab--> Samba-Eintrag: $blau$zeile$reset\n"
		avar=$(printf $zeile|cut -f1);
		pfad=$(echo $zeile|sed 's/^\([^[:space:]]*\)[[:space:]]*\(.*\)/\2/');
		if [ "$pfad" = "/DATA" ];then avar="daten";fi;
#		echo -e " A["$nr"]=\"["$avar"]\";\tP["$nr"]=\""$zeile"\";" >>$S2;
		printf " A[$nr]=\"[$avar]\";\tP[$nr]=\"$pfad\";\n" >>$S2;
		nr=$(expr $nr + 1);
	# Einhängepunkte der interessanten Dateisysteme verwenden, von diesen die Pfadenden, jedes nur einmal
	done << EOF
	$(awk '$3~"^ext|^ntfs|^btrfs$|^reiserfs$|^vfat$|^exfat|^cifs$" &&$2!="/" &&/^[^#]/{n=$2;sub(".*/","",n);if (f[n]==0){printf "%s\t%s\n",n,$2,f[n]=1}}' $ftb)
EOF
	printf "};\n" >>$S2;
	awk -f smbd.sh $smbdt >smb.conf;
	firewall samba;

	if ! diff -q smb.conf /etc/samba/smb.conf ||[ $zustarten = 1 ]; then  
		mv /etc/samba/smb2.conf /etc/samba/smb3.conf 2>/dev/null;
		mv /etc/samba/smb1.conf /etc/samba/smb2.conf 2>/dev/null;
		mv /etc/samba/smb0.conf /etc/samba/smb1.conf 2>/dev/null;
		mv /etc/samba/smb.conf /etc/samba/smb0.conf 2>/dev/null;
		cp -a smb.conf /etc/samba/smb.conf;
	  systemctl restart smbd 2>/dev/null;	
	  systemctl restart smb 2>/dev/null;	
	  systemctl restart nmbd 2>/dev/null;	
	  systemctl restart nmb 2>/dev/null;	
	fi;
}

firewall() {
	tufirewall 
	while [ $# -gt 0 ]; do
		para="$1";
		case $para in
			samba) p1=Samba; p2=samba_export_all_ro; p3=samba_export_all_rw; p4=samba; p5="samba-server"; p6="samba-client"; p7=samba;
		esac
		tufirewall $p1 $p2 $p3 $p4 $p5 $p6 $p7;
		shift;
	done;
}

tufirewall() {
	zustarten=0;
	if which ufw >/dev/null 2>&1; then
		ufwstatus=$(systemctl list-units --full -all 2>/dev/null|grep ufw.service);
		echo $ufwstatus;
		ret=$?;
		if [ $ret -eq 0 ]; then
			if ! ufw status|grep "^$1[[:space:]]*ALLOW" >/dev/null; then
				ufw allow $1;
				if $(echo $ufwstatus|grep -q " active "); then
					systemctl restart ufw;
					zustarten=1;
				fi;
			else
				printf "$1 in ufw schon erlaubt\n";
			fi;
		fi;
	fi;
	if which setsebool >/dev/null 2>&1; then
		for ro in $2 $3; do
			rostatus=$(getsebool -a|grep $ro|sed 's/^[^>]*>[[:space:]]*\([^[:space:]]*\).*/\1/');
			[ -z "$rostatus" -o "$rostatus" = "off" ]&&{ setsebool -P $ro=1; zustarten=1;}
		done;
	fi;
	# fehlt evtl: noch: semanage fcontext –at samba_share_t "/finance(/.*)?"
	# und: restorecon /finance
	if which firewall-cmd >/dev/null 2>&1; then
		fwstatus=$(systemctl list-units --full -all 2>/dev/null|grep firewalld.service);
  #		echo $fwstatus;
		ret=$?;
		if [ $ret -eq 0 ]; then
			if firewall-cmd --list-services >/dev/null 2>&1; then
				if ! firewall-cmd --list-services|grep -q "$4[^-]"; then
					printf "${blau}firewall-cmd --permanent --add-service=$4$reset\n";
					firewall-cmd --permanent --add-service=$4;
					firewall-cmd --reload;
					zustarten=1;
				fi;
			fi;
		fi;
	fi;
	susestatus=$(systemctl list-units --full -all|grep SuSEfirewall2.service);
	#	echo $susestatus;
	ret=$?;
	if [ $ret -eq 0 ]; then
		# das folgende aus kons.cpp
   susefw="/etc/sysconfig/SuSEfirewall2";
	 if [ -f "$susefw" ]; then
		 for endg in EXT INT DMZ; do
			 for prart in "$5" "$6" "$7"; do
				 if [ "$prart" ]; then
					 echo grep "^FW_CONFIGURATIONS_$endg=\".*$prart" $susefw;
					 nichtfrei=$(grep "^FW_CONFIGURATIONS_$endg=\".*$prart[ "\""]" $susefw);
					 echo $nichtfrei $endg $prart;
					 if [ -z "$nichtfrei" ]; then
						 echo bearbeite $nichtfrei $endg $prart;
						 sed -i.bak$i "s/\(^FW_CONFIGURATIONS_$endg=\".*\)\(\".*$\)/\1 $prart\2/g" $susefw;
					 fi;
				 fi;
			 done;
		 done;
		 if $(echo $susestatus|grep -q " active "); then
			systemctl restart SuSEfirewall2;
			zustarten=1;
		 fi;
	 fi
	fi
}

fritzbox() {
	printf "${dblau}fritzbox$reset()\n";
	ip4=$(ping -4c1 fritz.box 2>&1);
  erg4=$?;
  ip6=$(ping -6c1 fritz.box 2>&1);
  erg6=$?;
	if [ $erg4 -eq 0 -o $erg6 -eq 0 ]; then
	 [ $erg6 -eq 0 ]&&{ ipv6=$(echo $ip6|sed 's/^[^(]*([^(]*(\([^)]*\).*$/\1/'); ipv=$ipv6;} # z.B. fd00::a96:d7ff:fe49:19ca, umgeben von zwei Klammern
	 [ $erg4 -eq 0 ]&&{ ipv4=$(echo $ip4|sed 's/^[^(]*(\([^)]*\)).*/\1/'); ipv=$ipv4;} # z.B. 192.168.178.1
	 desc=$(curl $ipv:49000/tr64desc.xml 2>/dev/null);
	 fbname=$(echo "$desc"|sed -n '/friendlyName/{s/^[^>]*>\([^<]*\).*/\1/;p;q}');
#	 fbuuid=$(echo "$desc"|sed -n '/UDN/{s/^[^>]*>\([^<]*\).*/\1/;s/:/=/;p;q}'|tr '[:lower:]' '[:upper:]'); # geht scheinbar nicht
	 fbnameklein=$(echo $fbname|tr '[:upper:]' '[:lower:]');
	 mkdir -p /mnt/$fbnameklein;
	 credfile="$HOME/.smbcredentials"; # ~  # $HOME
	 grep -q "^//$ipv4\|^//$ipv6" $ftb||echo "//$ipv/$fbname /mnt/$fbnameklein cifs nofail,vers=1.0,credentials=$credfile 0 2" >>$ftb;
   if [ ! -f "$credfile" ]; then
		 printf "Bitte Fritzboxbenutzer eingeben: ";read fbuser;
		 printf "Bitte Passwort für $blau$fbuser$reset eingeben: ";read fbpwd;
		 printf "username=$fbuser\npassword=$fbpwd" >$credfile;
	 fi;
#	 echo "$desc";
   printf "Fritzbox gefunden, Name: $blau$fbname$reset, ipv4: $blau$ipv4$reset, ipv6: $blau$ipv6$reset\n";
#	 printf "Bitte Fritzboxbenutzer eingeben: ";read fbuser;
#	 printf "Bitte Passwort für $blau$fbuser$reset eingeben: ";read fbpwd;
	fi;
}

musterserver() {
 printf "Bitte ggf. Server angeben, von dem kopiert werden soll: ";read srv0;
 if [ "$srv0" ]; then
	 idpub="$HOME/.ssh/id_rsa.pub";
	 while [ ! -f "$idpub" ]; do
	  printf "Es fehlt noch: $blau$idpub$reset\n";
	  ssh-keygen -t rsa; # return, return, return
	 done;
	 <"$idpub" xargs -i ssh $(whoami)@$srv0 'umask 077;F=.ssh/authorized_keys;grep -q "{}" $F||echo "{}" >>$F'; # unter der Annahme des gleichnamigen Benutzers
	 KS=$HOME/.ssh/authorized_keys;
	 test -f "$KS"||touch "$KS";
	 ssh $(whoami)@$srv0 "HOME=\"$(getent passwd $(whoami)|cut -d: -f6)\";idpub=\"$HOME/.ssh/id_rsa.pub\"; cat \"$idpub\";"|xargs -i sh -c "umask 077;F=$KS;grep -q \"{}\" \$F||echo \"{}\" >>\$F";
	 rsync -avuz $srv0:$HOME/.vim $HOME/
 fi;
}

teamviewer10() {
	cd >/dev/null;
	while true; do
	 tversion=$(teamviewer --version 2>/dev/null|awk '/^.*Team/{print substr($4,1,index($4,".")-1)}');
	 [ "$tversion" ]||tversion=0;
	 printf "Installierte Teamviewer-Version: $blau$tversion$reset\n";
	 case $tversion in
		 0)
				case $OSNR in
				1|2|3) # mint, ubuntu, debian
					;;
				4|5|6|7) # opensuse, fedora, mageia
					trpm=teamviewer_10.0.95021.i686.rpm;
					;;
				esac;
			 if ! [ -f "$trpm" ]; then
				 q1=/DATA/down;
				 if [ -f "$q1/$trpm" ]; then
					 printf "${blau}cp -ai "$q1/$trpm" .$reset\n";
					 cp -ai "$q1/$trpm" .;
				 elif [ "$srv0" ]; then
					 printf "${blau}ssh "$srv0" "ls \"$q1/$trpm\" >/dev/null 2>&1"&& scp -p $srv0:$q1/$trpm .$reset\n";
					 ssh "$srv0" "ls \"$q1/$trpm\" >/dev/null 2>&1"&& scp -p $srv0:$q1/$trpm .;
				 else
					 hname=teamviewer.i686.rpm;
					 printf "${blau}wget "https://download.teamviewer.com/download/version_10x/$hname"$reset\n";
					 wget "https://download.teamviewer.com/download/version_10x/$hname";
					 mv -i "$hname" "$trpm";
				 fi;
			 fi;
			 if [ -f "$trpm" ]; then
				case $OSNR in
				1|2|3) # mint, ubuntu, debian
					printf "${blau}apt install /$trpm$reset\n";
					apt install /$trpm;
					;;
				4) # opensuse
					 printf "${blau}zypper --gpg-auto-import-keys in -l ./$trpm$reset\n";
					 zypper --gpg-auto-import-keys in -l ./$trpm;
					;;
				5) # fedora,
					 printf "${blau}dnf --nogpgcheck install ./$trpm$reset\n";
					 dnf --nogpgcheck install ./$trpm;
					 ;;
				6) # fedoraalt
					 printf "${blau}yum --nogpgcheck install ./$trpm$reset\n";
					 yum --nogpgcheck install ./$trpm;
					 ;;
			  7) # mageia
					;;
				esac;
			 fi;
			 ;;
		 10) break;;
		 *) 
				case $OSNR in
				1|2|3) # mint, ubuntu, debian
					;;
				4)
					 printf "${blau}zypper rm teamviewer$reset\n";
					 zypper rm teamviewer; 
					;;
				5|6|7) # opensuse, fedora, mageia
					;;
				esac;
			 continue;;
	 esac;
	done;
	zvz=/opt/teamviewer/tv_bin/wine/lib;
	zd=$zvz/libfreetype.so.6;
	while true; do
		[ -f "$zd" ]&&break;
		qd=$HOME/usr/lib/libfreetype.so.6.12.3;
		while ! [ -f "$qd" ]; do
			qqd=libfreetype6-32bit-2.6.3-5.3.1.x86_64.rpm;
			if ! [ -f "$HOME/$qqd" ]; then
				wget "https://download.opensuse.org/update/leap/42.3/oss/x86_64/$qqd";# geht auch für Fedora
			fi;
			rpm2cpio "$HOME/$qqd"|cpio -idmv
		done;
		cp -ai "$qd" "$zd";
	done;
				case $OSNR in
				1|2|3) # mint, ubuntu, debian
					;;
				4) # opensuse
					lxcb=libxcb1-32bit-1.11.1-9.1.x86_64.rpm;
					if rpm -q "$lxcb" >/dev/null; then
					 echo $? bei rpm -q "$lxcb";
					 if ! [ -f "$lxcb" ]; then
						 q1=/DATA/down;
						 if [ -f "$q1/$lxcb" ]; then
							 cp -ai "$q1/$lxcb" .;
						 elif [ "$srv0" ]; then
							 ssh "$srv0" "ls \"$q1/$lxcb\" >/dev/null 2>&1"&& scp -p $srv0:$q1/$lxcb .;
						 else
							wget http://download.opensuse.org/repositories/openSUSE:/Leap:/42.3:/Update/standard/x86_64/$lxcb;
						 fi;
					 fi;
					 rpm -i --force "./$lxcb";
					 zypper addlock "$lxcb";
					fi;
					;;
				5|6|7) # fedora, mageia
					;;
				esac;
	cd - >/dev/null;
}

variablen() {
 sed 's/:://;/\$/d;s/=/="/;s/$/"/;s/""/"/g;s/="$/=""/' vars >shvars
. ./shvars
 HOME="$(getent passwd $(whoami)|cut -d: -f6)"; # logname
}

# Start
# hier geht's los
printf "${dblau}$0$reset()${blau} Copyright Gerald Schade$reset\n"
nichtroot;
case f in [^f]) obbash=0;;*) obbash=1;esac;# 0=dash,1=bash
test "$(id -u)" -eq "0"||{ printf "Wechsle zu ${blau}root$reset, bitte ggf. ${blau}dessen$reset Passwort eingeben: ";su -c ./"$0";exit;};
echo Starte mit los.sh...
variablen;
#setzhost;
#setzbenutzer;
#mountlaufwerke;
#proginst;
#fritzbox;
#sambaconf;
musterserver;
teamviewer10;
echo Ende von $0!

if false; then
	eintr="@reboot mount /$Dvz";
	tmp=vorcrontab;
	if ! crontab -l|sed '^[^#]' >/dev/null 2>&1; then {
		echo "$eintr" >$tmp; crontab <$tmp;
		printf "\"$blau$eintr$reset\" in crontab eingetragen.\n";
	} else {
	crontab -l|grep -q "^$eintr" ||{ crontab -l|sed "/^[^#]/i$eintr" >$tmp;crontab <$tmp;printf "\"$blau$eintr$reset\" in crontab ergänzt.\n";};
} fi;
fi;
