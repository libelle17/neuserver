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
namnr=0; # 0=DATA, 1=DAT1, 2=DAT2 usw
mtpnr=0;
runde2=0;
while read -r zeile; do
#	echo "Hier: " $zeile;
	dev=$(echo $zeile|cut -d' ' -f1|cut -d= -f2|cut -d\" -f2);
	typ=$(echo $zeile|cut -d' ' -f3|cut -d= -f2|cut -d\" -f2);
	nam=$(echo $zeile|cut -d' ' -f4|cut -d= -f2|cut -d\" -f2);
	if test -z "$nam"; then
		case "$typ" in ext*|bt*)
		[ $namnr -eq 0 ]&&nam="DATA"||nam="DAT"$namnr;
		echo e2label /dev/$dev "$nam";
		e2label /dev/$dev "$nam";
		namnr=$(expr $namnr + 1 );;
    esac;
	else
		case "$nam" in 
			"DATA")[ "$namnr" -eq 0 ]&&namnr=1;;
			"DAT*")nr=$(echo $nam|cut -dT -f2);case nr in ''|*[!0-9]*);;*)namnr=$(expr $nr + 1);;esac;;
		esac;
	fi;
	mtp=$(echo $zeile|cut -d' ' -f6|cut -d= -f2|cut -d\" -f2);
	if test $runde2 -eq 1; then
		if test -z "$mtp"; then 
			mtp="/DAT1"; 
			mtpnr=2;
		fi;
		runde2=0;
	fi;
	if test -z "$byt"; then
		if test -z "$mtp"; then 
			mtp="/DATA"; 
			mtpnr=1;
	  fi;
		runde2=1;
	fi;
	if test -z "$mtp"; then 
		mtp="/DAT$mtpnr"; 
		mtpnr=$(expr $mtpnr + 1);
	fi;
	byt=$(echo $zeile|cut -d' ' -f2|cut -d= -f2|cut -d\" -f2);
	uid=$(echo $zeile|cut -d' ' -f5|cut -d= -f2|cut -d\" -f2);
	[ -n "$mtp" -a ! -d "$mtp" ]&&mkdir "$mtp";
	obinfstab $mtp;
	if test $istinfstab -eq 0; then
		# echo $mtp $istinfstab;
		eintr="\t $mtp\t $typ\t user,acl,user_xattr,exec,nofail,x-systemd.device-timeout=15\t 1\t 2"
		if test "$typ" = "ntfs"; then
			eintr="\t $mtp\t ntfs-3g	 user,users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail,x-systemd.device-timeout=15	 1	 2";
		fi;
		if test -z "$nam"; then
			eintr="UUID="$uid$eintr;
		else 
			eintr="LABEL="$nam$eintr;
		fi;
		echo -e $eintr >>/etc/fstab;
		echo -e \"$blau$eintr$reset\" in $blau/etc/fstab$reset eingetragen.
	fi;
	#   altbyt=$byt; byt=$(echo $z|cut -d' ' -f2); [ "$byt" -lt "$altbyt" ]&&gr=ja||gr=nein; echo "      byt: "$byt "$gr";
done << EOF
$(lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -b -i -x SIZE -s -n -P -f|grep -v ':\|swap\|efi\|fat\|iso\|FSTYPE=""'|tac) 
EOF
