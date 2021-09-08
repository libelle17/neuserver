#!/bin/zsh
USB=Seagate\ Expansion\ Drive
logf=/var/log/$USB.log
#ZoD=/mnt/seag
ZoD=/mnt/SeagateBackupPlusDrive
MUPR="$0"; # Mutterprogramm
. ./bugem.sh
if false; then
mountpoint -q "$ZoD" || mount "$ZoD"
echo `date +"%d.%m.%Y %X"` "Fange an" >"$logf"
kopiermt "DATA/Patientendokumente/Schade zu benennen" ... "" --delete
kopiermt "DATA/shome/gerald/Schade/sz" ... "" --delete
kopiermt "DATA/turbomed" ... "" --delete
kopiermt "DATA/rett/ungera" ... "" --delete
kopiermt "DATA/Patientendokumente" ... "plz/" "--delete --iconv=latin1,utf8"
kopiermt "DATA/eigene Dateien/DM" ... "" --delete
kopiermt "DATA/eigene Dateien/TMExport" ... "" --delete
kopiermt "shome/gerald/Schade" ... "" --delete
kopiermt "DATA/Patientendokumente/Schade zu benennen" ... "" --delete
kopiermt "DATA/eigene Dateien/Angiologie" ... "" --delete
kopiermt "opt/turbomed" ... "netsetupalt/" "--delete --iconv=latin1,utf8"
kopiermt "DATA/down" ... "" --delete
kopiermt "DATA/eigene Dateien" ... "DM/,TMExport/,Angiologie/" "--delete --iconv=latin1,utf8"
fi;
kopiermt "var/spool/hylafax" ... "" --delete
kopiermt "root/.vim" ... "" --delete
kopiermt "root/.smbcredentials" ... "" --delete
echo Schluss erstmal
exit

tukopier() {
  printf "${blau}tukopier()${reset} 1: ${blau}$1${reset} 2: ${blau}$2${reset}\n"
  mountpoint -q "$ZoD"||{ echo "$ZoD" nicht gemountet; exit;}&& ionice -c3 nice -n19 rsync -avu --delete "$1/" "$2" --exclude "$3" --exclude "$4" --exclude "$5" --exclude "$6" --exclude "$7" --exclude "$8" --exclude "$9" --exclude "$10" --exclude "$11" --exclude "$12" --exclude "$13"
  echo `date +"%d.%m.%Y %X"` "Fertig mit: " "$1" >>"$logf"
}

tukopierol() {
  printf "${blau}tukopierol()${reset} 1: ${blau}$1${reset} 2: ${blau}$2${reset}\n"
  mountpoint -q "$ZoD"||{ echo "$ZoD" nicht gemountet; exit;}&& ionice -c3 nice -n19 rsync -avu --iconv=utf8,latin1 "$1/" "$2" --exclude "$3" --exclude "$4" --exclude "$5" --exclude "$6" --exclude "$7" --exclude "$8" --exclude "$9" --exclude "$10" --exclude "$11" --exclude "$12" --exclude "$13"
  echo `date +"%d.%m.%Y %X"` "Fertig mit: " "$1" >>"$logf"
}

datakopier() {
  printf "${blau}datakopier()${reset} 1: ${blau}$1${reset} 2: ${blau}$2${reset}\n"
  tukopier "/DATA/$1" "$ZoD/DATA/$1" "Papierkorb" "ausgelagert" "DBBackloe" "TMBackloe" "sqlloe" "$2" "$3" "$4" "$5" "$6"
}

# mountpoint -q "$ZoD" && umount $ZoD
# mountpoint -q "$ZoD" || mount `fdisk -l 2>/dev/null | grep '  2048' | grep NTFS | cut -f1 -d' '` $ZoD -t ntfs-3g -O users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail
# mountpoint -q "$ZoD" || mount $ZoD
if false; then
mountpoint -q "$ZoD" || mount "$ZoD"
echo `date +"%d.%m.%Y %X"` "Fange an" >"$logf"
datakopier "shome/gerald/Schade/sz"
datakopier "turbomed"
datakopier "rett/ungera"
fi;
datakopier "Patientendokumente" "plz"
exit
datakopier "eigene Dateien/QZ"
datakopier "eigene Dateien/TMExport"
datakopier "shome/gerald/Schade"
datakopier "Patientendokumente/plz"
datakopier "Patientendokumente/Schade zu benennen"
datakopier "eigene Dateien/Angiologie"
datakopier "eigene Dateien/DM"
tukopier "/opt/turbomed" "$ZoD/turbomed" "netsetupalt" "Papierkorb"
datakopier "down/cpp"
tukopier "/var/spool/fax" "$ZoD/varspoolfax" 
tukopier "/root/bin" "$ZoD/root/bin" "*.swp" "Papierkorb"
mkdir -p $ZoD/root
mountpoint -q "$ZoD" && ionice -c3 nice -n19 rsync $QL/root/.vimrc $QL/root/.smbcredentials $QL/root/crontabakt $QL/root/.getmail $QL/root/.mysqlpwd $QL/root/.7zpassw $QL/root/bin $ZoD/root/ -avu --exclude ".*.swp"
mkdir -p $ZoD/etc
mountpoint -q "$ZoD" && ionice -c3 nice -n19 rsync $QL/etc/samba $QL/etc/hosts $QL/etc/vsftpd*.conf $QL/etc/my.cnf $QL/etc/fstab $ZoD/etc/ -avu # keine Anführungszeichen um den Stern!
mountpoint -q "$ZoD" && ionice -c3 nice -n19 rsync -avu $QL/obsl* $QL/gerade $QL/ungera $ZoD/ # 
mountpoint -q "$ZoD" && ionice -c3 nice -n19 rsync $QL/etc/openvpn $ZoD/etc -avu 
mountpoint -q "$ZoD" && ionice -c3 nice -n19 mkdir -p $ZoD/etc/profile.d
mountpoint -q "$ZoD" && ionice -c3 nice -n19 rsync -avu --include gs_openssl101g.sh --exclude "*" /etc/profile.d/ $ZoD/etc/profile.d
mkdir -p $ZoD/var
mkdir -p $ZoD/var/lib
mountpoint -q "$ZoD" && ionice -c3 nice -n19 rsync $QL/var/lib/mysql $ZoD/var/lib/ -avu --delete
datakopier "shome/gerald"
datakopier "eigene Dateien/QZ"
datakopier "eigene Dateien/Angiologie"
# tukopierol "$ZoD/RUECK/bin" "/root/bin" "*.swp" "Papierkorb" # auskommentiert 1.5.19
chmod 770 -R /root/bin/*
chown root:praxis -R /root/bin/*
# tukopierol "$ZoD/RUECK/cpp" "/DATA/down/cpp" "*.swp" "Papierkorb" # auskommentiert 1.5.19
datakopier "eigene Dateien/Programmierung"
tukopier "/root" "$ZoD/root" "*.swp" "Papierkorb"
datakopier "eigene Dateien/Programmierung/VS08"
datakopier "down/neu"
datakopier "down"
datakopier "eigene Dateien"  "DM" "TMExport" "Angiologie" "Programmierung"
datakopier "sql"
datakopier "ungera"
datakopier "gerade"
datakopier "Mail"
datakopier ""
# tukopier "/DATA/Papierkorb" "$ZoD/DATA/Papierkorb"
# mountpoint -q "$ZoD" && ionice -c3 nice -n19 rsync -avu --delete /opt/turbomed/ $ZoD/turbomed --excbude Papierkorb # ist schon in /DATA/rett/turbomed
