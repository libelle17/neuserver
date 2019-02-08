#!/bin/bash
# VAR=$(lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -b -i |grep '-'|grep -v ':\|swap\|efi\|fat\|iso'|sort -nrk2);
# lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -b -i -x SIZE -r > tmp;
#while read -r z; do
	#echo "Hier: " $z;
#done < <(lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -b -i -x SIZE -r);
obinfstab() {
	istinfstab=0;
	while read -r zeile; do
#		echo dort: $zeile;
		if test "$(echo $zeile|cut -d' ' -f2)" = "$1"; then istinfstab=1; break; fi;
	done << EOF
$fstb
EOF
}


fstb=$(sed -n 's/ \+/ /gp' /etc/fstab|grep -v '^#'); # "^/$Dvz\>" ginge auch
istinfstab=0;

while read -r zeile; do
	echo "Hier: " $zeile;
	nam=$(echo $zeile|cut -d' ' -f4);
	mtp=$(echo $zeile|cut -d' ' -f6);
	if test -z "$byt" -a -z "$mtp"; then mtp="/DATA"; fi;
		if test -z "$mtp"; then mtp="/$nam"; fi;
			dev=$(echo $zeile|cut -d' ' -f1|cut -d- -f2); # md0;
			byt=$(echo $zeile|cut -d' ' -f2);
			typ=$(echo $zeile|cut -d' ' -f3);
			uid=$(echo $zeile|cut -d' ' -f5);
			obinfstab $mtp;
						echo $mtp $istinfstab;
 #   altbyt=$byt; byt=$(echo $z|cut -d' ' -f2); [ "$byt" -lt "$altbyt" ]&&gr=ja||gr=nein; echo "      byt: "$byt "$gr";
done << EOF
$(lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -b -i -x SIZE -r|grep -v ':\|swap\|efi\|fat\|iso'|grep '[^ ]\+ [^]\+ [^ ]\+ [^ ]\+ '|sort -nrk2) EOF
