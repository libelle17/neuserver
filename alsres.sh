#!/bin/zsh
systemctl stop mysql
systemctl disable poetd
if false; then
  if [[ $HOST == "linux1" ]]; then


      if test -d /var/lib/mysql_3; then
       if test -d /var/lib/mysql; then
         mv /var/lib/mysql /var/lib/mysql_1
       fi
       mv /var/lib/mysql_3 /var/lib/mysql
      fi
  else
    if [[ $HOST == "linux3" ]]; then
    fi
  fi
fi
echo linux3.site > /etc/HOSTNAME
echo linux3.site > /etc/hostname
sed -i.bak 's/^192.168.178.46[[:space:]]\+linux1.site linux1/192.168.178.46  linux3.site linux3/g;s/^127.0.0.1[[:space:]]\+linux1.site linux1/127.0.0.1  linux3.site linux3/g' /etc/hosts 
hostname linux3.site
export hostname=linux3
reboot
