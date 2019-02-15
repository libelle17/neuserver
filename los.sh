#!/bin/bash
blau="\033[1;34m";
reset="\033[0m";
prog="";

setzhost() {
echo Setze Host;
# wenn Hostname z.B. linux-8zyu o.ä., dann korrigieren;
case $(hostname) in
*-*) {
		hostnamectl;
		echo -e $blau"gewünschter Servername, dann Enter:"$reset;
		read SERVER;
		hostnamectl set-hostname "$SERVER";
		export HOST="$SERVER";
		hostnamectl; 
};
esac;
}

setzbenutzer() {
grep -q "^praxis:" /etc/group||groupadd praxis
$SPR samba 2>/dev/null||$IPR samba
systemctl start smb 2>/dev/null||systemctl start smbd
systemctl enable smb 2>/dev/null||systemctl enable smbd
systemctl start nmb 2>/dev/null||systemctl start nmbd
systemctl enable nmb 2>/dev/null||systemctl enable nmbd
while read -r zeile; do
	user=${zeile%% \"*};
	comm=\"${zeile#* \"};
	testuser $user "$comm";
done <benutzer;
}

mountlaufwerke() {
# Laufwerke mounten
fstb=$(sed -n 's/ \+/ /gp' /etc/fstab|grep -v '^#'); # "^/$Dvz\>" ginge auch
istinfstab=0;
namnr=0; # 0=DATA, 1=DAT1, 2=DAT2 usw
mtpnr=0;
runde2=0;
while read -r zeile; do
#	echo "Hier: " $zeile;
	dev=$(echo $zeile|cut -d' ' -f1|cut -d= -f2|cut -d\" -f2);
	typ=$(echo $zeile|cut -d' ' -f3|cut -d= -f2|cut -d\" -f2);
	nam=$(echo $zeile|cut -d' ' -f4|cut -d= -f2|cut -d\" -f2);
	if test -z "$nam"; then
		case "$typ" in ext*|bt*)
		[ $namnr -eq 0 ]&&nam="DATA"||nam="DAT"$namnr;
		echo e2label /dev/$dev "$nam";
		e2label /dev/$dev "$nam";
		namnr=$(expr $namnr + 1 );;
    esac;
	else
		case "$nam" in 
			"DATA")[ "$namnr" -eq 0 ]&&namnr=1;;
			"DAT*")nr=$(echo $nam|cut -dT -f2);case nr in ''|*[!0-9]*);;*)namnr=$(expr $nr + 1);;esac;;
		esac;
	fi;
	mtp=$(echo $zeile|cut -d' ' -f6|cut -d= -f2|cut -d\" -f2);
	if test $runde2 -eq 1; then
		if test -z "$mtp"; then 
			mtp="/DAT1"; 
			mtpnr=2;
		fi;
		runde2=0;
	fi;
	if test -z "$byt"; then
		if test -z "$mtp"; then 
			mtp="/DATA"; 
			mtpnr=1;
	  fi;
		runde2=1;
	fi;
	if test -z "$mtp"; then 
		mtp="/DAT$mtpnr"; 
		mtpnr=$(expr $mtpnr + 1);
	fi;
	byt=$(echo $zeile|cut -d' ' -f2|cut -d= -f2|cut -d\" -f2);
	uid=$(echo $zeile|cut -d' ' -f5|cut -d= -f2|cut -d\" -f2);
	[ -n "$mtp" -a ! -d "$mtp" ]&&mkdir "$mtp";
	obinfstab $mtp;
	if test $istinfstab -eq 0; then
		# echo $mtp $istinfstab;
		eintr="\t $mtp\t $typ\t user,acl,user_xattr,exec,nofail,x-systemd.device-timeout=15\t 1\t 2"
		if test "$typ" = "ntfs"; then
			eintr="\t $mtp\t ntfs-3g	 user,users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail,x-systemd.device-timeout=15	 1	 2";
		fi;
		if test -z "$nam"; then
			eintr="UUID="$uid$eintr;
		else 
			eintr="LABEL="$nam$eintr;
		fi;
		echo -e $eintr >>/etc/fstab;
		echo -e \"$blau$eintr$reset\" in $blau/etc/fstab$reset eingetragen.
	fi;
	#   altbyt=$byt; byt=$(echo $z|cut -d' ' -f2); [ "$byt" -lt "$altbyt" ]&&gr=ja||gr=nein; echo "      byt: "$byt "$gr";
done << EOF
$(lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -b -i -x SIZE -s -n -P -f|grep -v ':\|swap\|efi\|fat\|iso\|FSTYPE=""'|tac) 
EOF
}

testuser() {
		id -u "$1" >/dev/null 2>&1 &&obu=0||obu=1;
		pdbedit -L|grep "^$1:" &&obs=0||obs=1;
		passw="";
		if test $obu -eq 1 -o $obs -eq 1; then {
				echo -e "Bitte gewünschtes Passwort für Benutzer $blau$1$reset eingeben:";
				read passw;
		} fi;
		if test $obu -eq 1; then {
				echo -e "erstelle Linux-Benutzer $blau$1$reset";
				useradd -p $(openssl passwd -1 $passw) -c"$2" -g praxis "$1"; # zuweisen:  passwd "$1"; # loeschen: userdel $1;
		} fi;
		if test $obs -eq 1; then {
				echo -e "erstelle Samba-Benutzer $blau$1$reset"; # loeschen: pdbedit -x -u $1;
				echo -ne "$passw\n$passw\n"|smbpasswd -a -s $1 # pruefen: smbclient -L //localhost/ -U $1
		} fi;
}

obinfstab() {
	istinfstab=0;
	while read -r zeile; do
#		echo dort: $zeile;
		if test "$(echo $zeile|cut -d' ' -f2)" = "$1"; then istinfstab=1; break; fi;
	done << EOF
$fstb
EOF
}

obprogda() {
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
	case $OSNR in
	1|2|3)
		if [ "$1" = mariadb ]; then eprog="mariadb-server"; return; fi;
		if [ "$1" = hylafax ]; then eprog="hylafax-server"; return; fi;
		if [ "$1" = "hylafax+" ]; then eprog="hylafax+-server"; return; fi;
		if [ "$1" = "hylafax hylafax-client" ]; then eprog="hylafax-server hylafax-client"; return; fi;
		if [ "$1" = "hylafax+ hylafax+-client" ]; then eprog="hylafax+-server hylafax+-client"; return; fi;
		if [ "$1" = "kernel-source" ]; then eprog="linux-source-$(uname -r|cut -d. -f1,2)"; return; fi;
		if [ "$1" = tiff ]; then eprog="libtiff-tools"; return; fi;
		if [ "$1" = "libxslt-tools" ]; then eprog="xsltproc"; return; fi;
		if [ "$1" = imagemagick ]; then eprog="imagemagick imagemagick-doc"; return; fi;
		if [ "$1" = "libreoffice-base" ]; then eprog="libreoffice-common libreoffice-base"; return; fi;
		if [ "$1" = "libcapi20-2" ]; then eprog="libcapi20-dev"; return; fi;
		if [ "$1" = "tesseract-ocr-traineddata-english" ]; then eprog="tesseract-ocr-eng"; return; fi;
		if [ "$1" = "tesseract-ocr-traineddata-german" ]; then eprog="tesseract-ocr-deu"; return; fi;
		if [ "$1" = "tesseract-ocr-traineddata-orientation_and_script_detection" ]; then eprog="tesseract-ocr-osd"; return; fi;
		if [ "$1" = "poppler-tools" ]; then eprog="poppler-utils"; return; fi;
		if [ "$1" = "boost-devel" ]; then eprog="libboost-dev libboost-system-dev libboost-filesystem-dev"; return; fi;
		eprog=$(sed 's/-devel/-dev/g' <<<"$eprog");;
	5|6)
		if [ "$1" = mariadb ]; then eprog="mariadb-server"; return; fi;
		if [ "$1" = "kernel-source" ]; then eprog="kernel-devel-$(uname -r)"; return; fi;
		if [ "$1" = "poppler-tools" ]; then eprog="poppler-utils"; return; fi;
		if [ "$1" = "poppler-tools" ]; then eprog="poppler-utils"; return; fi;
}

doinst() {
	ersetzeprog "$1";
}

instmaria() {
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

proginst() {
setzinstprog;
# fehlende Programme installieren
P=htop;$psuch "$P" >/dev/null||$instyp "$P";

# Mariadb
case $OSNR in
	1|2|3)
		db_systemctl_name="mysql";;
	4|5|6|7)
		db_systemctl_name="mariadb";;
esac;
systemctl is-enabled $db_systemctl_name >/dev/null 2>&1 ||systemctl enable $db_systemctl_name;
systemctl start $db_systemctl_name >/dev/null 2>&1;
installiert=1;
mysqld="mysqld";
mysqlben="mysql";
mysqlbef="mysql";
if ! find /usr/sbin /usr/bin /usr/libexec -executable -size +1M -name "$mysqld" 2>/dev/null|grep -q .; then installiert=0; fi;
[ $installiert -eq 1 ]&& obprogda $mysqlbef || installiert=0;
[ $installiert -eq 1 ]&& grep -q "^$mysqlben" /etc/passwd || installiert=0;
[ $installiert -eq 1 ]&& $mysqlbef -V >/dev/null|| installiert=0;
if [ $installiert -eq 0]; then

fi;
echo installiert: $installiert;

}

# Start
test "$(id -u)" -eq "0"||{ echo "Wechsle zu root, bitte ggf. dessen Passwort eingeben:";su -c ./"$0";exit;};
sed 's/:://;/\$/d;s/=/="/;s/$/"/;' vars>vars.sh
. ./vars.sh
#setzhost;
#setzbenutzer;
#mountlaufwerke;
proginst;



if false; then
	eintr="@reboot mount /$Dvz";
	tmp=vorcrontab;
	if ! crontab -l|sed '^[^#]' >/dev/null 2>&1; then {
		echo "$eintr" >$tmp; crontab <$tmp;
		echo -e \"$blau$eintr$reset\" in crontab eingetragen.
	} else {
	crontab -l|grep -q "^$eintr" ||{ crontab -l|sed "/^[^#]/i$eintr" >$tmp;crontab <$tmp;echo -e \"$blau$eintr$reset\" in crontab ergänzt.;};
} fi;
fi;
