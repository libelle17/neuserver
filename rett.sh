#!/bin/bash
if test [[ $HOST == "linux4" ]]; then
 mount /hDATA
 mount /DATA
fi
if $(mountpoint -q /DATA); then 
  mkdir /DATA/rett 2>/dev/null
  mkdir /DATA/rett/etc 2>/dev/null
  ionice -c3 nice -n19 rsync -avu /etc/samba /etc/hosts /etc/vsftpd*.conf /etc/my.cnf /etc/fstab /etc/capisuite /DATA/rett/etc/ # keine Anführungszeichen um den Stern!
  ionice -c3 nice -n19 rsync -avu /etc/sysconfig/isdn /DATA/rett/etc/sysconfig
  mkdir /DATA/rett/usr 2>/dev/null
  ionice -c3 nice -n19 rsync -avu /usr/lib64/capisuite /DATA/rett/usr/lib64
  ionice -c3 nice -n19 rsync -avu /etc/openvpn /DATA/rett/etc 
  ionice -c3 nice -n19 rsync -avu --delete --exclude "Papierkorb" /opt/turbomed/ /DATA/rett/turbomed/
  ionice -c3 nice -n19 rsync -avu /root/.vimrc /root/.fbcredentials /root/.getmail /root/.mysqlpwd /root/.7zpassw /root/bin /root/crontabakt /DATA/rett/root/
  ionice -c3 nice -n19 rsync -avu -x /mnt/ /DATA/rett/mnt
  ionice -c3 nice -n19 rsync -avu -x /amnt/ /DATA/rett/amnt
  ionice -c3 nice -n19 rsync -avu /obsl* /DATA/rett/
  #ionice -c3 nice -n19 rsync -avu /gerade /DATA/rett/
  ionice -c3 nice -n19 rsync -avu /ungera /DATA/rett/
  if [ 0 -eq 1 ]; then
   mountpoint -q /DAT3 && ionice -c3 nice -n19 rsync -avu --delete /DATA/ /DAT3
  fi
  chown schade:praxis -R /DATA/rett
  chmod 774 -R /DATA/rett
fi
