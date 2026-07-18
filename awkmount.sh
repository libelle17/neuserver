#!/usr/bin/awk -f
# awkmount.sh - liest zeilenweise ein fstab-artiges Format ($1=Gerätespec,
# $2=Mountpunkt; Zeilen, die mit # oder ; beginnen, werden übersprungen) und
# mountet fehlende Einträge nach: existiert das Mountpunkt-Verzeichnis ($2)
# und ist es noch kein Mountpoint, wird bei "LABEL=..."/"UUID=..." als
# Gerätespec per blkid geprüft, ob dieses Label/diese UUID überhaupt
# existiert, und falls ja per "mount -L"/"mount -U" gemountet. Aufruf:
# awk -f awkmount.sh <datei> (die Eingabedatei wird als normale awk-
# Eingabe übergeben, z.B. eine Kopie/Auszug von /etc/fstab).
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
