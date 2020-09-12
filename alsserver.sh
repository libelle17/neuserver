#!/bin/zsh
systemctl stop mysql
systemctl stop mysql
systemctl enable poetd
if false; then
  if [[ $HOST == "linux1" ]]; then
  else
    if [[ $HOST == "linux3" ]]; then
      if test -d /var/lib/mysql_1; then
       if test -d /var/lib/mysql; then
         mv /var/lib/mysql /var/lib/mysql_3
       fi
       mv /var/lib/mysql_1 /var/lib/mysql
      fi
    fi
  fi
fi

echo linux1.site > /etc/HOSTNAME
echo linux1.site > /etc/hostname
sed -i.bak 's/^192.168.178.46[[:space:]]\+linux3.site linux3/192.168.178.46  linux1.site linux1/g;s/^127.0.0.1[[:space:]]\+linux3.site linux3/127.0.0.1  linux1.site linux1/g' /etc/hosts 
hostname linux1.site
export hostname=linux1
# reboot
