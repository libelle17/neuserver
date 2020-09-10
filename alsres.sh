#!/bin/zsh
RNAM=linux0
SNAM=linux1
# systemctl stop mysql
systemctl disable poetd
if false; then
  if [[ $HOST == "$SNAM" ]]; then


      if test -d /var/lib/mysql_3; then
       if test -d /var/lib/mysql; then
         mv /var/lib/mysql /var/lib/mysql_1
       fi
       mv /var/lib/mysql_3 /var/lib/mysql
      fi
  else
    if [[ $HOST == "$RNAM" ]]; then
    fi
  fi
fi
echo $RNAM.site > /etc/HOSTNAME
echo $RNAM.site > /etc/hostname
sed -i.bak 's/^192.168.178.46[[:space:]]\+$SNAM.site $SNAM/192.168.178.46  $RNAM.site $RNAM/g;s/^127.0.0.1[[:space:]]\+$SNAM.site $SNAM/127.0.0.1  $RNAM.site $RNAM/g' /etc/hosts 
hostname $RNAM.site
export hostname=$RNAM
reboot
