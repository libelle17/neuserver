#!/bin/bash
if test [[ $HOST == "linux4" ]]; then
 mount /hDATA
 mount /DATA
fi
if $(mountpoint -q /DATA); then 
  mkdir /DATA/rett 2>/dev/null
  mkdir /DATA/rett/etc 2>/dev/null
  rsync -avu /etc/samba /etc/hosts /etc/vsftpd*.conf /etc/my.cnf /etc/fstab /etc/capisuite /DATA/rett/etc/ # keine Anführungszeichen um den Stern!
  rsync -avu /etc/sysconfig/isdn /DATA/rett/etc/sysconfig
  mkdir /DATA/rett/usr 2>/dev/null
  rsync -avu /usr/lib64/capisuite /DATA/rett/usr/lib64
  rsync -avu /etc/openvpn /DATA/rett/etc 
  rsync -avu --delete --exclude "Papierkorb" /opt/turbomed/ /DATA/rett/turbomed/
  rsync -avu /root/.vimrc /root/.smbcredentials /root/.getmail /root/bin /root/crontabakt /DATA/rett/root/
  rsync -avu -x /mnt/ /DATA/rett/mnt
  rsync -avu /obsl* /DATA/rett/
  #rsync -avu /gerade /DATA/rett/
  rsync -avu /ungera /DATA/rett/
  if [ 0 -eq 1 ]; then
   mountpoint -q /DAT3 && rsync -avu --delete /DATA/ /DAT3
  fi
  chown schade:praxis -R /DATA/rett
  chmod 774 -R /DATA/rett
fi
