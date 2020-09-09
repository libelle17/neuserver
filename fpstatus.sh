#!/bin/zsh
echo "cat /proc/mdstat | sed 's/$/\\\\r/g'"":"
#cat /proc/mdstat | sed 's/$/\r/g'
cat /proc/mdstat 
echo "\n""mdadm --detail \`ls /dev/md? -d\`"":"
mdadm --detail `ls /dev/md? -d`
#echo "\n""blkid"":"
#blkid
echo "\n""mount"":"
mount
