#!/usr/bin/awk -f
BEGIN {
blau="\033[1;34m";
reset="\033[0m";
}
/^[^#;]/ {
# wenns das mount-Verzeichnis gibt
	if (!system("test -d "$2)) {
		if(system("mountpoint -q "$2)) {
			print "kein Mountpoint: "$2;
			print blau NR" -"$1"-" reset;
			if(substr($1,1,5)=="LABEL") {
				if(!system("blkid -L "substr($1,7))) {
					system("mount -L "substr($1,7));
					print "gibts: "substr($1,7);
				} else {
					print "gibts nicht: "substr($1,7);
				}
			} else if (substr($1,1,4)=="UUID") {
			  if(!system("blkid -U "substr($1,6))) {
					system("mount -U "substr($1,6));
					print "gibts: "substr($1,6);
				} else {
					print "gibts nicht: "substr($1,6);
				}
			}
		}
	}
}
