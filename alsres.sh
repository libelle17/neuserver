#!/bin/zsh
NNAM=linux0
ANAM=linux1
# systemctl stop mysql
systemctl disable poetd
if false; then
  if [[ $HOST == "$ANAM" ]]; then


      if test -d /var/lib/mysql_3; then
       if test -d /var/lib/mysql; then
         mv /var/lib/mysql /var/lib/mysql_1
       fi
       mv /var/lib/mysql_3 /var/lib/mysql
      fi
  else
    if [[ $HOST == "$NNAM" ]]; then
    fi
  fi
fi
echo $NNAM.site > /etc/HOSTNAME
echo $NNAM.site > /etc/hostname
sed -i.bak 's/^192.168.178.46[[:space:]]\+$ANAM.site $ANAM/192.168.178.46  $NNAM.site $NNAM/g;s/^127.0.0.1[[:space:]]\+$ANAM.site $ANAM/127.0.0.1  $NNAM.site $NNAM/g' /etc/hosts 
hostname $NNAM.site
export hostname=$NNAM
reboot
