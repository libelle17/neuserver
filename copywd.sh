#!/bin/zsh
PNAME=MyPassport
logf=/var/log/$PNAME.log
Z=/mnt/MyPassport
Q=""

tukopier() {
  mountpoint -q "$Z" && ionice -c3 nice -n19 rsync -avu --delete "$1/" "$2" --exclude "$3" --exclude "$4" --exclude "$5" --exclude "$6" --exclude "$7" --exclude "$8" --exclude "$9" --exclude "$10" --exclude "$11" --exclude "$12" --exclude "$13"
  echo `date +"%d.%m.%Y %X"` "Fertig mit: " "$1" >>"$logf"
}

tukopierol() {
  mountpoint -q "$Z" && ionice -c3 nice -n19 rsync -avu --iconv=utf8,latin1 "$1/" "$2" --exclude "$3" --exclude "$4" --exclude "$5" --exclude "$6" --exclude "$7" --exclude "$8" --exclude "$9" --exclude "$10" --exclude "$11" --exclude "$12" --exclude "$13"
  echo `date +"%d.%m.%Y %X"` "Fertig mit: " "$1" >>"$logf"
}

datakopier() {
  tukopier "/DATA/$1" "$Z/DATA/$1" "Papierkorb" "ausgelagert" "$2" "$3" "$4" "$5" "$6"
}

# mountpoint -q "$Z" && umount $Z
# mountpoint -q "$Z" || mount `fdisk -l 2>/dev/null | grep '  2048' | grep NTFS | cut -f1 -d' '` $Z -t ntfs-3g -O users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail
# mountpoint -q "$Z" || mount $Z
mountpoint -q "$Z" || mount "$Z"
echo `date +"%d.%m.%Y %X"` "Fange an" >"$logf"
datakopier "turbomed"
datakopier "rett/ungera"
datakopier "Patientendokumente" "plz"
datakopier "eigene Dateien/QZ"
datakopier "eigene Dateien/TMExport"
datakopier "shome/gerald/Schade"
datakopier "Patientendokumente/plz"
datakopier "Patientendokumente/Schade zu benennen"
datakopier "shome/gerald/Schade/sz"
datakopier "eigene Dateien/Angiologie"
datakopier "eigene Dateien/DM"
tukopier "/opt/turbomed" "$Z/turbomed" "netsetupalt" "Papierkorb"
datakopier "down/cpp"
tukopier "/var/spool/fax" "$Z/varspoolfax" 
tukopier "/root/bin" "$Z/root/bin" "*.swp" "Papierkorb"
mkdir $Z/root
mountpoint -q "$Z" && ionice -c3 nice -n19 rsync $Q/root/.vimrc $Q/root/.smbcredentials $Q/root/crontabakt $Q/root/.getmail $Q/root/.mysqlpwd $Q/root/.7zpassw $Q/root/bin $Z/root/ -avu --exclude ".*.swp"
mkdir $Z/etc
mountpoint -q "$Z" && ionice -c3 nice -n19 rsync $Q/etc/samba $Q/etc/hosts $Q/etc/vsftpd*.conf $Q/etc/my.cnf $Q/etc/fstab $Z/etc/ -avu # keine Anführungszeichen um den Stern!
mountpoint -q "$Z" && ionice -c3 nice -n19 rsync -avu $Q/obsl* $Q/gerade $Q/ungera $Z/ # 
mountpoint -q "$Z" && ionice -c3 nice -n19 rsync $Q/etc/openvpn $Z/etc -avu 
mountpoint -q "$Z" && ionice -c3 nice -n19 mkdir -p $Z/etc/profile.d
mountpoint -q "$Z" && ionice -c3 nice -n19 rsync -avu --include gs_openssl101g.sh --exclude "*" /etc/profile.d/ $Z/etc/profile.d
mkdir $Z/var
mkdir $Z/var/lib
mountpoint -q "$Z" && ionice -c3 nice -n19 rsync $Q/var/lib/mysql $Z/var/lib/ -avu --delete
datakopier "shome/gerald"
datakopier "eigene Dateien/QZ"
datakopier "eigene Dateien/Angiologie"
# tukopierol "$Z/RUECK/bin" "/root/bin" "*.swp" "Papierkorb" # auskommentiert 1.5.19
chmod 770 -R /root/bin/*
chown root:praxis -R /root/bin&/*
# tukopierol "$Z/RUECK/cpp" "/DATA/down/cpp" "*.swp" "Papierkorb" # auskommentiert 1.5.19
datakopier "eigene Dateien/Programmierung"
tukopier "/root" "$Z/root" "*.swp" "Papierkorb"
datakopier "eigene Dateien/Programmierung/VS08"
datakopier "down/neu"
datakopier "down"
datakopier "eigene Dateien"  "DM" "TMExport" "Angiologie" "Programmierung"
datakopier "sql"
datakopier "ungera"
datakopier "gerade"
datakopier "Mail"
datakopier ""
# tukopier "/DATA/Papierkorb" "$Z/DATA/Papierkorb"
# mountpoint -q "$Z" && ionice -c3 nice -n19 rsync -avu --delete /opt/turbomed/ $Z/turbomed --excbude Papierkorb # ist schon in /DATA/rett/turbomed

