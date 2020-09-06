#!/bin/zsh
function kopier {
 echo ""
 echo `date +%Y:%m:%d\ %T` "vor /$1" >> $PROT
 tue="rsync \"$Q/$1\" \"$Z/$2\" $4 -avu --exclude=Papierkorb --exclude=mnt ""$3"
 echo $tue
 eval $tue
}
function kopieros {
  kopier $1 "" "--exclude='.*.swp'"
}
function kopieretc {
  kopier etc/$1 "etc/"
}

if [ ${HOST%%.*}/ = linux1/ ]; then
  Q=""
  Z=linux0:
  AND=linux0:
else
  if [ ${HOST%%.*} != linux1 ]; then
    Q=linux1:;
    Z="";
    AND=linux1:;
  fi
fi
PROT=/var/log/bulinux0prot.txt
echo Prot: $PROT
echo `date +%Y:%m:%d\ %T` "vor chown" > $PROT
chown root:root -R /root/.ssh
chmod 600 -R /root/.ssh
kopier "opt/turbomed" "opt/"
kopieros "root/.vim"
kopieros "root/.smbcredentials"
kopieros "root/crontabakt"
kopieros "root/.getmail"
V=/root/bin/;rsync -avu --prune-empty-dirs --include="*/" --include="*.sh" --exclude="*" "$Q$V" "$Z$V"
# kopieros "root/bin" # auskommentiert 29.7.19
# kopieros "root/" # auskommentiert 29.7.19
EXCL=--exclude={
mount /DATA;
if mountpoint -q /DATA; then
 for A in Patientendokumente turbomed shome eigene\\\ Dateien sql Mail TMBack rett down DBBack ifap vontosh Oberanger att; do
  kopier "DATA/$A" "DATA/"
  EXCL=${EXCL}"$A/,"
 done;
 EXCL=${EXCL}"}"
 kopier "DATA" "" "$EXCL" "-W"
fi;
# kopieretc "samba" # auskommentiert 29.7.19
# kopieretc "hosts" # hier muesste noch eine Zeile geaendert werden!
# kopieretc "vsftpd.conf" # auskommentiert 29.7.19
# kopieretc "my.cnf" # auskommentiert 29.7.19
# kopieretc "fstab.cnf" # auskommentiert 29.7.19
kopier "gerade" "/"
kopier "ungera" "/"
kopier "var/lib/mysql/" "var/lib/mysql_l"
# kopieretc "openvpn" # auskommentiert 29.7.19
echo `date +%Y:%m:%d\ %T` "vor ende.sh" >> $PROT
scp $PROT $AND/var/log/
if mountpoint -q /DATA; then
 scp $PROT $AND/DATA/
fi;
if [ ${HOST%%.*}/ = linux0/ ]; then
  cd ~/neuserver
  sh los.sh mysqlneu -v
  cd -
fi

# exit
# echo `date +%Y:%m:%d\ %T` "vor /etc/hosts" >> $PROT
# rsync $Q/etc/samba $Q/etc/hosts $Q/etc/vsftpd*.conf $Q/etc/my.cnf $Q/etc/fstab $Z/etc/ -avuz # keine Anführungszeichen um den Stern!
