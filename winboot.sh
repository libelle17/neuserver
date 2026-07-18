#/bin/bash
# winboot.sh - bootet den Rechner einmalig in den nativ installierten
# Windows Boot Manager (statt Linux), per "grub2-reboot" (wirkt nur für den
# nächsten Neustart, danach greift wieder der normale Grub-Standardeintrag)
# und stößt den Neustart direkt an ("reboot"). Der Grub-Menüeintragsname
# ("Windows Boot Manager (on <Partition>)") hängt vom jeweiligen Rechner ab
# (linux8/wexp: nvme0n1p1, linux3: sdd1) und wird über den Hostnamen
# ermittelt. Aufruf ohne Parameter.
# bootet einmalig Windows
HOST=$(hostname); case ${HOST%%.*}/ in linux8/) LW=/dev/nvme0n1p1;; linux3/) LW=/dev/sdd1;; wexp/) LW=/dev/nvme0n1p1;; esac;
echo LW: $LW;
echo "Windows Boot Manager (on $LW)"
grub2-reboot "Windows Boot Manager (on $LW)"
reboot
