#!/bin/zsh
PNAME=MyPassport
Z=/amnt/$PNAME
. incopy.sh;
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
mountpoint -q "$Z" && ionice -c3 nice -n19 rsync $Q/root/.vimrc $Q/root/.fbcredentials $Q/root/crontabakt $Q/root/.getmail $Q/root/.mysqlpwd $Q/root/.7zpassw $Q/root/bin $Z/root/ -avu --exclude ".*.swp"
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

