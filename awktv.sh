#!/usr/bin/awk -f
# korrigiert oder ergänzt die aufgerufene Datei um Einträge in awktv.inc
function ltrim(s) { sub(/^[[:space:]]+/,"",s);return s}
function rtrim(s) { sub(/[ \t\r\n]+$/,"",s);return s}
function oA(s) {if (s~"\".*\""||s~"'.*'") return substr(s,2,length(s)-2);else return s}
function trim(s) { return oA(rtrim(ltrim(s)));}
function pruefzeile(zeile) {
#	printf zeile"\n";
	split(zeile,teil,"=");
	tN=trim(teil[1]);
	tW=trim(teil[2]);
#	printf tN"="tW"\n";
  gefu=0;
	for(i in N) {
		if (tN==N[i]) {
#			printf tN" ==? "N[i]"\n";
			if (tW==W[i]) {
				print $0;
			} else {
				printf tN" = "W[i]"\n";
			}
			gefu=1;
			gef[i]=1;
			break;
		}
	}
	if (gefu==0) {
		print $0;
	}
}

# Eintraege
@include "awktv.inc";

{
	pruefzeile($0);
}
# noch nicht geschriebene Namen schreiben
END {
 for(i in N) {
	 if (!gef[i]) {
		print N[i]" = "W[i];
	 }
 }
}
