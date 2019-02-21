#!/usr/bin/awk -f
function ltrim(s) { sub(/^[[:space:]]+/,"",s);return s}
function rtrim(s) { sub(/[ \t\r\n]+$/,"",s);return s}
function trim(s) { return rtrim(ltrim(s));}
@include "smbvars.sh";
@include "smbab.sh";
BEGIN {
# for(i in N) fertig[i]=0;
IGNORECASE=1;
FS="=";
}
# am Beginn eines neuen Abschnitts ...
/^[[]/ {
  tri=trim($1);
  if (tri=="[global]") inglobal=1;
	else if (inglobal==1) {
#   , und zwar des nächsten Abschnitts nach [global]		
		kommentiert=0;
		for(i in N) {
			if (fertig[i]==0) {
				if (!kommentiert) {
					print "# hinzugefügt (los.sh):";
					kommentiert=1;
				}
				print "   " N[i] " = " I[i]  
			}
		}
		inglobal=0;
	}
# , eines Abschnitts nach einem fstab-Laufwerk
	if (infstab==1) {
		kommentiert=0;
		for(i in Na) {
			if (fertig[i]==0) {
				if (!kommentiert) {
					print "# hinzugefügt (los.sh):";
					kommentiert=1;
				}
				if (i==0) print "   " Na[i] " = los.sh " Name;
				else if (i==1) print "   " Na[i] " = " Pfad;
				else print "   " Na[i] " = " Ia[i];
			}
		}
	}
	infstab=0;
  for(i in A) {
		if (tri==A[i]) {
			afertig[i]=1;
			infstab=1;
			Name=A[i];
      Pfad=P[i];
			delete fertig;
			break;
		}
	}
}
# innerhalb eines Abchnitts, in Nicht-Kommentarzeile => pruefen
/^[^[#;]/ && NF>1 {
	if (inglobal==1) {
		trn=trim($1);
		tri=trim($2);
		for(i in N) {
			if (trn==N[i]) {
				if (tri==I[i]) {
#					print "# belassen:"
					print $0;
				} else {
				print "# geändert (los.sh):";
					print $1 " = " I[i];
				}
				fertig[i]=1;
				next;
			}
		}
	} else if (infstab==1) {
		trn=trim($1);
		tri=trim($2);
		for(i in Na) {
			if (trn==Na[i]) {
				if (tri==Ia[i]||(i==0&&tri=="los.sh " Name)||(i==1&&tri=Pfad)) {
#					print "# belassen:"
					print $0;
				} else {
					print "# geändert (los.sh):";
					if (i==0) print "   " Na[i] " = los.sh " Name;
					else if (i==1) print "   " Na[i] " = " Pfad;
					else print "   " Na[i] " = " Ia[i];
				}
				fertig[i]=1;
				next;
			}
		}
	}
}
# alle anderen Zeilen abschreiben
/^[^#;]/ {
	print $0;
}
END {
for (i in A) {
	if (Afertig[i]==0) {
		print "# ergänzt (los.sh):";
		print A[i];
		for (j in Na)  {
			if (j==0) print "   " Na[j] " = los.sh " P[i];
			else if (j==1) print "   " Na[j] " = " P[i];
			else print "   " Na[j] " = " Ia[j];
		}
	}
}
}
