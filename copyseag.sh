#!/bin/zsh
PNAME=Seagate\ Expansion\ Drive
logf=/var/log/$PNAME.log
#Z=/mnt/seag
Z=/mnt/seag
Q=""
blau="\e[1;34m";
dblau="\e[0;34;1;47m";
rot="\e[1;31m";
reset="\e[0m";

tukopier() {
  printf "${blau}tukopier()${reset} 1: ${blau}$1${reset} 2: ${blau}$2${reset}\n"
  mountpoint -q "$Z"||{ echo "$Z" nicht gemountet; exit;}&& ionice -c 3 rsync -avu --delete "$1/" "$2" --exclude "$3" --exclude "$4" --exclude "$5" --exclude "$6" --exclude "$7" --exclude "$8" --exclude "$9"
  echo `date +"%d.%m.%Y %X"` "Fertig mit: " "$1" >>"$logf"
}

tukopierol() {
  printf "${blau}tukopierol()${reset} 1: ${blau}$1${reset} 2: ${blau}$2${reset}\n"
  mountpoint -q "$Z"||{ echo "$Z" nicht gemountet; exit;}&& ionice -c 3 rsync -avu --iconv=utf8,latin1 "$1/" "$2" --exclude "$3" --exclude "$4" --exclude "$5" --exclude "$6" --exclude "$7" --exclude "$8" --exclude "$9"
  echo `date +"%d.%m.%Y %X"` "Fertig mit: " "$1" >>"$logf"
}

datakopier() {
  printf "${blau}datakopier()${reset} 1: ${blau}$1${reset} 2: ${blau}$2${reset}\n"
  tukopier "/DATA/$1" "$Z/DATA/$1" "Papierkorb" "ausgelagert" "$2"
}

# mountpoint -q "$Z" && umount $Z
# mountpoint -q "$Z" || mount `fdisk -l 2>/dev/null | grep '  2048' | grep NTFS | cut -f1 -d' '` $Z -t ntfs-3g -O users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail
# mountpoint -q "$Z" || mount $Z
mountpoint -q "$Z" || mount "$Z"
echo `date +"%d.%m.%Y %X"` "Fange an" >"$logf"
datakopier "shome/gerald/Schade/sz"
datakopier "turbomed"
datakopier "rett/ungera"
datakopier "Patientendokumente" "plz"
datakopier "eigene Dateien/QZ"
datakopier "eigene Dateien/TMExport"
datakopier "shome/gerald/Schade"
datakopier "Patientendokumente/plz"
datakopier "Patientendokumente/Schade zu benennen"
datakopier "eigene Dateien/Angiologie"
datakopier "eigene Dateien/DM"
tukopier "/opt/turbomed" "$Z/turbomed" "netsetupalt" "Papierkorb"
datakopier "down/cpp"
tukopier "/var/spool/fax" "$Z/varspoolfax" 
tukopier "/root/bin" "$Z/root/bin" "*.swp" "Papierkorb"
mkdir -p $Z/root
mountpoint -q "$Z" && ionice -c 3 rsync $Q/root/.vimrc $Q/root/.smbcredentials $Q/root/crontabakt $Q/root/.getmail $Q/root/bin $Z/root/ -avu --exclude ".*.swp"
mkdir -p $Z/etc
mountpoint -q "$Z" && ionice -c 3 rsync $Q/etc/samba $Q/etc/hosts $Q/etc/vsftpd*.conf $Q/etc/my.cnf $Q/etc/fstab $Z/etc/ -avu # keine Anführungszeichen um den Stern!
mountpoint -q "$Z" && ionice -c 3 rsync -avu $Q/obsl* $Q/gerade $Q/ungera $Z/ # 
mountpoint -q "$Z" && ionice -c 3 rsync $Q/etc/openvpn $Z/etc -avu 
mountpoint -q "$Z" && ionice -c 3 mkdir -p $Z/etc/profile.d
mountpoint -q "$Z" && ionice -c 3 rsync -avu --include gs_openssl101g.sh --exclude "*" /etc/profile.d/ $Z/etc/profile.d
mkdir -p $Z/var
mkdir -p $Z/var/lib
mountpoint -q "$Z" && ionice -c 3 rsync $Q/var/lib/mysql $Z/var/lib/ -avu --delete
datakopier "shome/gerald"
datakopier "eigene Dateien/QZ"
datakopier "eigene Dateien/Angiologie"
# tukopierol "$Z/RUECK/bin" "/root/bin" "*.swp" "Papierkorb" # auskommentiert 1.5.19
chmod 770 -R /root/bin/*
chown root:praxis -R /root/bin/*
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
# mountpoint -q "$Z" && ionice -c 3 rsync -avu --delete /opt/turbomed/ $Z/turbomed --excbude Papierkorb # ist schon in /DATA/rett/turbomed
