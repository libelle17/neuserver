#!/bin/zsh
# soll vor Verwendung des aktuellen Linux-PC als Server aufgerufen werden
systemctl stop mysql
systemctl stop mysql
systemctl enable poetd
[ "$HOST" ]||HOST=$(hostname);
if [ "$HOST" != "linux1" ]; then
  if test -d /var/lib/mysql_1; then
   if test -d /var/lib/mysql; then
     mv /var/lib/mysql /var/lib/mysql_3
   fi
   mv /var/lib/mysql_1 /var/lib/mysql
  fi
fi

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
# reboot

