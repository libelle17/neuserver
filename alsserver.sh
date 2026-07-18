#!/bin/zsh
# alsserver.sh - soll vor Verwendung des aktuellen Linux-PC als Server
# aufgerufen werden: benennt ihn zu "linux1" um (Hostname, /etc/hostname,
# passender /etc/hosts-Eintrag anhand der aktuell ermittelten IP), aktiviert
# den Dienst "poetd" sowie Samba (smb/nmb, damit dieser Rechner wieder
# Freigaben als Server anbietet), legt die Marker-Datei /obslaeuft/laeuft an
# und ruft "autofax -cm 2" auf. Gegenstück: alsres.sh (Rückumwandlung zur
# Reserve-Identität). Der auskommentierte mysql-Datenverzeichnis-Umzug
# (mysql_1/mysql_3-Vertauschung) ist seit 26.7.22 deaktiviert und damit
# inaktiver Alt-Code; Hinweis: "apparmor muss dazu richtig eingerichtet oder
# ausgeschaltet sein" (Kommentar im Original). Aufruf ohne Parameter.

# mysql-Aktion am 26.7.22 auskommentiert
# systemctl stop mysql
# systemctl stop mysql
systemctl enable poetd
[ "$HOST" ]||HOST=$(hostname);
# if [ "$HOST" != "linux1" ]; then
#   if test -d /var/lib/mysql_1; then
#    if test -d /var/lib/mysql; then
#      mv /var/lib/mysql /var/lib/mysql_3
#    fi
#    mv /var/lib/mysql_1 /var/lib/mysql
#   fi
# fi

echo linux1.site > /etc/HOSTNAME
echo linux1.site > /etc/hostname
IP=$(ip route get 1 | awk '{print $(NF-2);exit;}');
sed -i.bak 's/^'$IP'[[:space:]]\+'$HOST'.site '$HOST'/'$IP' linux1.site linux1/g;s/^127.0.0.1[[:space:]]\+'$HOST'.site '$HOST'/127.0.0.1  linux1.site linux1/g' /etc/hosts
hostname linux1.site
export hostname=linux1
# apparmor muss dazur richtig eingerichtet oder ausgeschaltet sein
D=obslaeuft; mkdir -p /$D; touch /$D/laeuft; 
systemctl enable smb;
systemctl start smb;
systemctl enable nmb;
systemctl start nmb;
autofax -cm 2;
# reboot

