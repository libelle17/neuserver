#!/bin/zsh
echo "cat /proc/mdstat | sed 's/$/\\\\r/g'"":"
#cat /proc/mdstat | sed 's/$/\r/g'
cat /proc/mdstat 
echo "\n""mdadm --detail \`ls /dev/md? -d\`"":"
mdadm --detail `ls /dev/md? -d`
echo "\n""blkid"":"
blkid
echo "\n""mount"":"
mount
echo "\n""fdisk -l 2\>\&1"":"
fdisk -l 2>&1
echo "\n""parted -l 2\>\&1"":"
parted -l 2>&1
echo "\n""lsscsi"":"
lsscsi
echo "\n""lsblk"":"
lsblk
echo "\n""hdparm -I /dev/sd? 2\>\&1"":"
hdparm -I /dev/sd? 2>&1
