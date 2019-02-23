#!/usr/bin/awk -f
#usage: awk -f tumount.sh /etc/fstab
/^[^#;]/ {
# wenns das mount-Verzeichnis gibt
if (!system("test -d "$2)) {
	if(system("mountpoint -q "$2)) {
		print "kein Mountpoint: "$2;
		if(substr($1,1,5)=="LABEL") {
			if(!system("blkid -L "substr($1,7))) {
				system("mount -L "substr($1,7));
				print "gibts: "substr($1,7);
			} else {
			  print "gibts nicht: "substr($1,7);
  		}
  	}
  }
}
}
