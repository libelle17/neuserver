#!/bin/zsh
# kopiert von mobilen Platten auf z.B. /DATAW
PROTD=/var/log/prot_`basename $0`.txt
test -f "$PROTD"||{ sudo touch "$PROTD"&&sudo chmod 777 "$PROTD";};
MP=/mnt/extern
sudo mkdir -p $MP
AUSG=$(sudo fdisk -l 2>/dev/null);
LW=$(echo "$AUSG" | grep '  2048' | grep '3907'  | grep NTFS | head -n1 |cut -f1 -d' ')
test -z "$LW" && LW=$(echo "$AUSG" | grep '1\,8T' | grep NTFS | head -n1 |cut -f1 -d' ')
test -z "$LW" && LW=$(echo "$AUSG" | grep '1\.8T' | grep NTFS | head -n1 |cut -f1 -d' ')
test -z "$LW" && LW=$(sudo blkid | grep "Seagate Expansion Drive" |cut -f1 -d:)
test -z "$LW" && LW=$(sudo blkid | grep "My Passport" |cut -f1 -d:)
test -z "$LW" && LW=$(sudo blkid | grep "verbatim" |cut -f1 -d:)
echo LW: "$LW"
printf "Laufwerke mit 'NTFS', '2048' und '3970' oder 'Seagate Expansion Drive' order 'verbatim': "
test -z "$LW" &&{ printf "keine, breche ab\n";exit; }
printf "'"$LW"'\n";
ZIEL=/DATA
while :; do
	echo mountpoint -q "$ZIEL";
	mountpoint -q "$ZIEL" && break;
	echo "mount" "$ZIEL"
	sudo mount "$ZIEL"
done;
while :; do
 awk -v lw="$LW" -v mp="$MP" '$1==lw&&$2==mp {exit 1}' /proc/mounts &&{
	if true; then
		MP=$(lsblk "$LW" -noMOUNTPOINT 2>/dev/null);
		echo Mountpoint: $MP
	else
		while :; do
			awk -v lw="$LW" 'BEGIN {OFS=""} $1==lw {print "unmounte \"",$1,"\" von \"",$2,"\"";exit 1}' /proc/mounts &&break;
			sudo umount -l "$LW";
		done;
		echo mounte \"$LW\" auf \"$MP\";
		echo sudo mount "$LW" "$MP" -t ntfs -O users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail;
		sudo mount "$LW" "$MP" -t ntfs -O users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail;
	fi; # true
 }||{
	mountpoint -q "$ZIEL" &&{
		echo Beginne  `date +'%d.%m.%Y %X'`|tee $PROTD
		 for S in "down/cpp" "down" "Patientendokumente" "turbomed" "eigene\ Dateien" "shome/gerald" "Mail/EML" "sql"; do
			echo Jetzt kommt "$S"
			echo sudo rsync -avuz --info=all6 "$MP/DATA/$S/" "$ZIEL/$S" --exclude Papierkorb
			sudo rsync -avuz --info=all6 "$MP/DATA/$S/" "$ZIEL/$S" --exclude Papierkorb
			echo Fertig mit "$MP/DATA/$S/" `date +'%d.%m.%Y %X'`|tee -a $PROTD
		 done;
		echo sudo rsync -avuz --info=all6 $MP/bin/ /root/bin --exclude Papierkorb
		sudo rsync -avuz --info=all6 $MP/bin/ /root/bin --exclude Papierkorb
		echo Fertig mit $MP/bin/ `date +'%d.%m.%Y %X'`|tee -a $PROTD;:
	}||{
		echo "$ZIEL" nicht gemountet;
	}
	break;
 }
done;
# mount `fdisk -l 2>/dev/null | grep '  2048' | grep '3907' |  grep NTFS | cut -f1 -d' '` $MP -t ntfs-3g -O users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail
# -t fuseblk -O users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail
