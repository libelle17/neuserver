#!/bin/zsh
Z=/amnt/verbatim
umount $Z
mount `fdisk -l 2>/dev/null | grep '  63' | grep NTFS | cut -f1 -d' '` $Z -t ntfs-3g -O users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail
mountpoint -q "$Z" && rm -rf $Z/PraxisDB
mountpoint -q "$Z" && dorsync.sh --delete /opt/turbomed/PraxisDB/ $Z/PraxisDB # >>/var/log/dorsync-Aufruf-flash.log 2>&1
mountpoint -q "$Z" && rm -rf $Z/StammDB
mountpoint -q "$Z" && dorsync.sh --delete /opt/turbomed/StammDB/ $Z/StammDB # >>/var/log/dorsync-Aufruf-flash.log 2>&1
mountpoint -q "$Z" && rm -rf $Z/Dictionary
mountpoint -q "$Z" && dorsync.sh --delete /opt/turbomed/Dictionary/ $Z/Dictionary # >>/var/log/dorsync-Aufruf-flash.log 2>&1
mountpoint -q "$Z" && rm -rf $Z/DruckDB
mountpoint -q "$Z" && dorsync.sh --delete /opt/turbomed/DruckDB/ $Z/DruckDB # >>/var/log/dorsync-Aufruf-flash.log 2>&1
