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

# hier geht's los
LINEINS=linux1;
blau="\033[1;34m";
rot="\e[1;31m";
reset="\033[0m";
[ "$1"/ = -d/ ]&&OBDEL="--delete"||OBDEL="";
[ "$HOST" ]||HOST=$(hostname);
HOSTK=${HOST%%.*};
if [ $HOSTK/ = $LINEINS/ -a $# != 4 ]; then
  printf "$blau$0$reset, Syntax: \n $blau"$(basename $0)" <-d/\"\"> <zielhost>\n-d$reset bewirkt Loeschen auf dem Zielrechner der auf dem Quellrechner nicht vorhandenen Dateien\n";
  exit;
fi;
if [ $HOSTK/ = $LINEINS/ ]; then
  Q=""
  Z=${4%%:*}:; # z.B. linux0:
  ANDERER=${4%%:*}; # z.B. linux0
else
  Q=$LINEINS:; # linux1:
  Z="";
  ANDERER=$LINEINS; # linux1
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
ssh $ANDERER mount /DATA;
if mountpoint -q /DATA && ssh $ANDERER mountpoint -q /DATA 2>/dev/null; then
 for A in Patientendokumente turbomed shome eigene\\\ Dateien sql Mail TMBack rett down DBBack ifap vontosh Oberanger att; do
  kopier "DATA/$A" "DATA/" "$OBDEL"
  EXCL=${EXCL}"$A/,"
 done;
 EXCL=${EXCL}"TMBackloe,DBBackloe,sqlloe}"
 kopier "DATA" "" "$EXCL" "-W $OBDEL"
fi;
# kopieretc "samba" # auskommentiert 29.7.19
# kopieretc "hosts" # hier muesste noch eine Zeile geaendert werden!
# kopieretc "vsftpd.conf" # auskommentiert 29.7.19
# kopieretc "my.cnf" # auskommentiert 29.7.19
# kopieretc "fstab.cnf" # auskommentiert 29.7.19
kopier "gerade" "/" "$OBDEL"
kopier "ungera" "/" "$OBDEL"
systemctl stop mysql
pkill -9 mysqld
kopier "var/lib/mysql/" "var/lib/mysql" "$OBDEL"
systemctl start mysql
# kopieretc "openvpn" # auskommentiert 29.7.19
echo `date +%Y:%m:%d\ %T` "vor ende.sh" >> $PROT
scp $PROT $ANDERER:/var/log/
if mountpoint -q /DATA && ssh $ANDERER mountpoint -q /DATA 2>/dev/null; then
 scp $PROT $ANDERER:/DATA/
fi;
if [ $HOSTK/ != $LINEINS/ ]; then
  NES=~/neuserver;
  LOS=los.sh;
  if test -d $NES -a -f $NES/$LOS; then
    cd $NES;
    sh $LOS mysqlneu -v;
    cd -;
  fi;
fi;

# exit
# echo `date +%Y:%m:%d\ %T` "vor /etc/hosts" >> $PROT
# rsync $Q/etc/samba $Q/etc/hosts $Q/etc/vsftpd*.conf $Q/etc/my.cnf $Q/etc/fstab $Z/etc/ -avuz # keine Anführungszeichen um den Stern!
