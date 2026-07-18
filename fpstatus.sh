#!/bin/zsh
# fpstatus.sh - kurze RAID-/Mount-Statusübersicht: zeigt vor jedem Befehl den
# Befehl selbst an (echo) und dann dessen Ausgabe - /proc/mdstat (Software-
# RAID-Status), "mdadm --detail" für alle gefundenen /dev/md*-Geräte und die
# aktuellen Mounts. "blkid" ist auskommentiert (nicht Teil der Standard-
# ausgabe). Ausführlichere Variante mit mehr Befehlen: fpstatusmb.sh.
# Aufruf ohne Parameter.
echo "cat /proc/mdstat | sed 's/$/\\\\r/g'"":"
#cat /proc/mdstat | sed 's/$/\r/g'
cat /proc/mdstat
echo "\n""mdadm --detail \`ls /dev/md? -d\`"":"
mdadm --detail `ls /dev/md? -d`
#echo "\n""blkid"":"
#blkid
echo "\n""mount"":"
mount
