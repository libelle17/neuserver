#/bin/bash
# bootet einmalig Windows
HOST=$(hostname); case $HOST/ in linux8/) LW=/dev/nvme0n1p1;; linux3/) LW=/dev/sdc1;; esac;
echo LW: $LW;
echo "Windows Boot Manager (on $LW)"
grub2-reboot "Windows Boot Manager (on $LW)"
reboot
