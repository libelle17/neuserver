#!/bin/bash
blau="\033[1;34m"
reset="\033[0m"

testuser() {
	id -u "$1" >/dev/null 2>&1||{
		echo -e "Benutzer $blau$1$reset:";
	useradd -c"$2" -g praxis "$1";
	passwd "$1";
}
pdbedit -L|grep "^$1:"||{
	echo -e "Benutzer in Samba $blau$1$reset:";
smbpasswd -a $1
 }
}

test "$(id -u)" -eq "0"||{ echo "Wechsle zu root, bitte ggf. dessen Passwort eingeben:";su -c ./"$0";exit;};
hostnamectl
echo -e $blau"gewünschter Servername, dann Enter:"$reset
read SERVER
hostnamectl set-hostname "$SERVER" 
hostnamectl
grep -q "^praxis:" /etc/group||groupadd praxis
rpm -q samba 2>/dev/null||zypper install samba
systemctl start smb
systemctl enable smb
systemctl start nmb
systemctl enable nmb
testuser schade "Gerald Schade"
testuser sturm "T.Sturm"
testuser simon "U.Simon"
testuser vsftp "Benutzer zum Scannen von Brother MFC 8510DN über vsftp"

