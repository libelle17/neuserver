#!/bin/bash
blau="\033[1;34m"
reset="\033[0m"

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

test "$(id -u)" -eq "0"||{ echo "Wechsle zu root, bitte ggf. dessen Passwort eingeben:";su -c ./"$0";exit;};
sed 's/:://;/\$/d;s/=/="/;s/$/"/;' vars>vars.sh
. ./vars.sh
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
grep -q "^praxis:" /etc/group||groupadd praxis
$SPR samba 2>/dev/null||$IPR samba
systemctl start smb 2>/dev/null||systemctl start smbd
systemctl enable smb 2>/dev/null||systemctl enable smbd
systemctl start nmb 2>/dev/null||systemctl start nmbd
systemctl enable nmb 2>/dev/null||systemctl enable nmbd
testuser schade "Gerald Schade"
testuser sturm "T.Sturm"
testuser simon "U.Simon"
testuser vsftp "Benutzer zum Scannen von Brother MFC 8510DN über vsftp"
testuser bittner "S.Bittner"

Dvz=DATA
test -d /$Dvz || mkdir /$Dvz
if ! mountpoint -q /$Dvz; then {
#		wenn $Dvz noch nicht /etc/fstab vorkommt
		if ! sed -n 's/ \+/ /gp' /etc/fstab|grep -v '^#'|cut -d' ' -f2|grep "^/$Dvz$(printf '\xa')" >/dev/null; then { # "^/$Dvz\>" ginge auch
#				groesstes Laufwerk
				grlw=$(lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -b -i |grep '-'|grep -v ':\|swap\|efi\|fat\|iso'|sort -nrk2|head -n1);
				if test -n "${grlw}"; then {
						dev=$(echo $grlw|cut -d' ' -f1|cut -d- -f2); # md0;
						byt=$(echo $grlw|cut -d' ' -f2);
						typ=$(echo $grlw|cut -d' ' -f3);
						nam=$(echo $grlw|cut -d' ' -f4);
						uid=$(echo $grlw|cut -d' ' -f5);

						eintr="\\t /$Dvz\\t $typ\\t user,noauto,acl,user_xattr,exec\\t 1\\t 2"
						if test -z "$nam"; then {
								eintr="UUID="$uuid$eintr;
						} else {
								eintr="LABEL="$nam$eintr;
						} fi;
						echo -e $eintr >>/etc/fstab
						echo -e \"$blau$eintr$reset\" in $blau/etc/fstab$reset eingetragen.
				} fi;
		} fi;
} fi;
eintr="@reboot mount /$Dvz";
tmp=vorcrontab;
if ! crontab -l|sed '^[^#]' >/dev/null 2>&1; then {
		echo "$eintr" >$tmp; crontab <$tmp;
		echo -e \"$blau$eintr$reset\" in crontab eingetragen.
} else {
		crontab -l|grep -q "^$eintr" ||{ crontab -l|sed "/^[^#]/i$eintr" >$tmp;crontab <$tmp;echo -e \"$blau$eintr$reset\" in crontab ergänzt.;};
} fi;
