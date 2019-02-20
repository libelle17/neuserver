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
# am Beginn eines neuen Abschnitts nach [global]
/^[[]/ {
  if (trim($1)=="[global]") inglobal=1;
	else if (inglobal==1) {
		kommentiert=0;
		for(i in N) {
			if (fertig[i]==0) {
				if (!kommentiert) {
					print "# hinzugefügt:"
					kommentiert=1;
				}
				print "   " N[i] " = " I[i]  
			}
		}
		inglobal=0;
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
				  print "# geändert:";
					print $1 " = " I[i]
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
print " - DONE -"
}
