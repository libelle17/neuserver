#!/bin/zsh
PNAME=tosh
logf=/var/log/$PNAME.log
Z=/amnt/$PNAME
Q=""

tukopier() {
  mountpoint -q "$Z" && ionice -c 3 rsync -avuz --delete "$1/" "$2" --exclude "$3" --exclude "$4" --exclude "$5" --exclude "$6" --exclude "$7" --exclude "$8" --exclude "$9"
  echo `date +"%d.%m.%Y %X"` "Fertig mit: " "$1" >>"$logf"
}

tukopierol() {
  mountpoint -q "$Z" && ionice -c 3 rsync -avuz --iconv=utf8,latin1 "$1/" "$2" --exclude "$3" --exclude "$4" --exclude "$5" --exclude "$6" --exclude "$7" --exclude "$8" --exclude "$9"
  echo `date +"%d.%m.%Y %X"` "Fertig mit: " "$1" >>"$logf"
}

datakopier() {
  tukopier "/DATA/$1" "$Z/DATA/$1" "Papierkorb" "ausgelagert"
}

# mountpoint -q "$Z" && umount $Z
# mountpoint -q "$Z" || mount `fdisk -l 2>/dev/null | grep '  2048' | grep NTFS | cut -f1 -d' '` $Z -t ntfs-3g -O users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail
# mountpoint -q "$Z" || mount $Z
mountpoint -q "$Z" || mount "$Z"
echo `date +"%d.%m.%Y %X"` "Fange an" >"$logf"
tukopier "/opt/turbomed" "$Z/turbomed" "netsetupalt" "Papierkorb"
datakopier "eigene Dateien/DM"
datakopier "Patientendokumente" "plz"
datakopier "eigene Dateien/QZ"
datakopier "eigene Dateien/TMExport"
datakopier "down/cpp"
datakopier "shome/gerald/Schade/sz"
datakopier "shome/gerald/Schade"
datakopier "Patientendokumente/plz"
datakopier "Patientendokumente/Schade zu benennen"
tukopier "/root/bin" "$Z/root/bin" "*.swp" "Papierkorb"
datakopier "Mail"
mkdir $Z/root
mountpoint -q "$Z" && ionice -c 3 rsync $Q/root/.vimrc $Q/root/.fbcredentials $Q/root/crontabakt $Q/root/.getmail $Q/root/bin $Z/root/ -avuz --exclude ".*.swp"
mkdir $Z/etc
mountpoint -q "$Z" && ionice -c 3 rsync $Q/etc/samba $Q/etc/hosts $Q/etc/vsftpd*.conf $Q/etc/my.cnf $Q/etc/fstab $Z/etc/ -avuz # keine Anführungszeichen um den Stern!
mountpoint -q "$Z" && ionice -c 3 rsync -avuz $Q/obsl* $Q/gerade $Q/ungera $Z/ # 
mountpoint -q "$Z" && ionice -c 3 rsync $Q/etc/openvpn $Z/etc -avuz 
mountpoint -q "$Z" && ionice -c 3 mkdir -p $Z/etc/profile.d
mountpoint -q "$Z" && ionice -c 3 rsync -avuz --include gs_openssl101g.sh --exclude "*" /etc/profile.d/ $Z/etc/profile.d
mkdir $Z/var
mkdir $Z/var/lib
mountpoint -q "$Z" && ionice -c 3 rsync $Q/var/lib/mysql $Z/var/lib/ -avuz --delete
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
datakopier ""
# tukopier "/DATA/Papierkorb" "$Z/DATA/Papierkorb"
# mountpoint -q "$Z" && ionice -c 3 rsync -avuz --delete /opt/turbomed/ $Z/turbomed --excbude Papierkorb # ist schon in /DATA/rett/turbomed

