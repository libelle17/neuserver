#!/usr/bin/awk -f
# awksmb.sh - gleicht eine smb.conf-artige Konfigurationsdatei (Eingabe
# über normale awk-Dateiargumente) gegen Soll-Werte ab, die aus zwei
# (gawk-@include-)Dateien im selben Verzeichnis geladen werden:
#   awksmb.inc    - Soll-Werte für den [global]-Abschnitt (N[]/I[]) sowie
#                   für Freigabe-("fstab"-)Abschnitte allgemein (Na[]/Ia[],
#                   u.a. Kommentar, Pfad, Verzeichnismaske, "available")
#   awksmbap.inc  - Namen (A[]) und Pfade (P[]) der konkret erwarteten
#                   Freigabe-Abschnitte
# Beim [global]-Abschnitt werden fehlende/abweichende Einstellungen aus
# N[]/I[] ergänzt bzw. korrigiert (alte Zeile bleibt als Kommentar
# erhalten); bei jedem erkannten Freigabe-Abschnitt (Name aus A[]) analog
# über Na[]/Ia[]/P[]; fehlt ein ganzer erwarteter Abschnitt komplett, wird
# er am Dateiende neu angelegt. Jede Änderung wird mit einem
# "# ... (los.sh <Datum>)"-Kommentar markiert - wird also über los.sh
# aufgerufen, nicht direkt. Aufruf: gawk -f awksmb.sh <datei> (Ausgabe
# geht nach stdout, muss vom Aufrufer in die Zieldatei umgeleitet werden).
function ltrim(s) { sub(/^[[:space:]]+/,"",s);return s}
function rtrim(s) { sub(/[ \t\r\n]+$/,"",s);return s}
function trim(s) { return rtrim(ltrim(s));}
function druckNaZeile(i,Pfad,j) {
		printf "   %s = ",Na[i];
		if (i==0) printf "%s (los.sh %s)\n", Pfad,datum;
		else if (i==1) print Pfad;
    else if (Na[i]=="available") if (avail[j]) print "Yes"; else print (system("mountpoint -q '"Pfad"'")?"No":"Yes");
		else print Ia[i];
}
# Vorgaben für [global] (N[] und I[]) und fstab-Abschnitte (Na[] und Ia[])
@include "awksmb.inc";
# Namen (A[]) und Pfade (P[]) vorgegebener Abschnitte
@include "awksmbap.inc";
BEGIN {
# for(i in N) fertig[i]=0;
IGNORECASE=1;
FS="=";
"date +%Y-%m-%d\\ %T"|getline datum;
}
# am Beginn eines neuen Abschnitts ...
/^[[]/ {
  tri=trim($1);
  if (tri=="[global]") inglobal=1;
	else if (inglobal==1) {
#   , und zwar des nächsten Abschnitts nach [global]: restliche [global]-Einstellungen nachtragen
		inglobal=0;
#		for(i in N) { printf "#i: %i fertig, N[i]: %s, I[i]: %s\n",i,N[i],I[i]; }
		kommentiert=0;
		for(i in N) {
			if (fertig[i]==0) {
				if (!kommentiert) {
					printf "# hinzugefügt (los.sh %s):\n", datum;
					kommentiert=1;
				}
				print "   "N[i]" = "I[i]  
			}
		}
	}
# , eines Abschnitts nach einem fstab-Laufwerk
	if (infstab==1) {
		infstab=0;
		kommentiert=0;
		for(i in Na) {
			if (fertig[i]==0) {
				if (!kommentiert) {
					printf "# hinzugefügt (los.sh %s):\n", datum;
					kommentiert=1;
				}
				druckNaZeile(i,Pfad);
				print $0;
				next;
			}
		}
	}
  for(i in A) {
		if (tri==A[i]) {
			afertig[i]=1;
			infstab=1;
			Name=A[i];
#			printf "# °°°°°°°°°°°°°°° %s °°°°°°°°°°°°°°\n",Name;
      Pfad=P[i];
			delete fertig;
			break;
		}
	}
#	for (i in A) { printf "# i: %i, A[i]: %s\n",i,A[i]; }
}
# innerhalb eines Abschnitts, in Nicht-Kommentarzeile => pruefen
/^[^[#;]/ && NF>1 {
	if (inglobal==1) {
		trn=trim($1);
		tri=trim($2);
		for(i in N) {
			if (trn==N[i]) {
				if (tri==I[i]) {
#					printf "# belassen (los.sh %s):\n", datum;
					print $0;
				} else {
					printf "# geändert (los.sh %s):\n", datum;
					print $1" = "I[i];
				}
#				printf "#i: %i fertig, N[i]: %s\n",i,N[i];
				fertig[i]=1;
				next;
			}
		}
	} else if (infstab==1) {
		trn=trim($1);
		tri=trim($2);
		for(i in Na) {
			if (trn==Na[i]) {
				# i==0: comment, i==1:path, i==2:directory mask
#				if (tri==Ia[i]||(i==0&&tri!="")||(i==1&&tri=Pfad)||(i==2&&tri!="")) KLA
        if (tri==Ia[i]||(i==0&&tri!="")||(i==1&&tri=Pfad)) {
#					print "# belassen:"
					print $0;
				} else {
				  if (Na[i]!="available") printf "# abgewandelt (los.sh %s):\n", datum;
					druckNaZeile(i,Pfad);
				}
				fertig[i]=1;
				next;
			}
		}
	}
}
# alle anderen Zeilen abschreiben
# /^[^#;]/ {
{
	print $0;
}
END {
for (j in A) {
	if (afertig[j]==0) {
		printf "# Abschnitt ergänzt (los.sh %s):\n", datum;
		print A[j];
		for (i in Na)  {
			druckNaZeile(i,P[j],j);
		}
	}
}
}
