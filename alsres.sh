#!/bin/zsh
# alsres.sh - "als Reserve": konfiguriert den aktuellen Rechner von der
# Server-Rolle (linux1) auf eine gewöhnliche Reserve-PC-Identität um.
# Gegenstück zu alsserver.sh. Setzt neuen Hostnamen ($1) und passt den
# zugehörigen Eintrag in /etc/hosts auf die angegebene IP ($2) an, deaktiviert
# den Dienst "poetd" sowie Samba (smb/nmb, damit die Reserve-Rolle keine
# Server-Freigaben mehr anbietet), löscht die Marker-Datei /obslaeuft und
# ruft "autofax -st" auf. Der auskommentierte mysql-Datenverzeichnis-Umzug
# (mysql_1/mysql_3-Vertauschung) ist seit 26.7.22 deaktiviert und damit
# inaktiver Alt-Code. Aufruf: alsres.sh <hostname> <ip>, z.B.
# "alsres.sh linux0 192.168.178.178".
if [ $# -ne 2 ]; then
  echo "Syntax: $0 <hostname> <ip>",
  echo "z.B.    $0 linux0 192.168.178.178"
  exit;
fi;
NNAM=$1;
IP=$2;
ANAM=linux1
# mysql-Aktion am 26.7.22 auskommentiert
# systemctl stop mysql
# systemctl disable mysql
systemctl stop poetd
systemctl disable poetd
[ "$HOST" ]||HOST=$(hostname);
echo HOST: $HOST, ANAM: $ANAM
# if [ $HOST = "$ANAM" -o \( -d /var/lib/mysql_3 -a -d /var/lib/mysql -a ! -d /var/lib/mysql_1 \) ]; then
#     if test -d /var/lib/mysql_3; then
#      if test -d /var/lib/mysql; then
#        mv /var/lib/mysql /var/lib/mysql_1
#      fi
#      mv /var/lib/mysql_3 /var/lib/mysql
#     fi
# fi
echo $NNAM.site > /etc/HOSTNAME
echo $NNAM.site > /etc/hostname
sed -i.bak 's/^'$IP'[[:space:]]\+$ANAM.site $ANAM/'$IP' $NNAM.site $NNAM/g;s/^127.0.0.1[[:space:]]\+$ANAM.site $ANAM/127.0.0.1  $NNAM.site $NNAM/g' /etc/hosts 
hostname $NNAM.site
export hostname=$NNAM
rm -rf /obslaeuft
autofax -st
systemctl disable smb;
systemctl stop smb;
systemctl disable nmb;
systemctl stop nmb;
# reboot
