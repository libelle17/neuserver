#!/usr/bin/awk -f
# awktv.sh - korrigiert oder ergänzt eine "Name = Wert"-Konfigurationsdatei
# (Eingabe über normale awk-Datei-Argumente) anhand einer Liste von
# Soll-Werten, die aus der (gawk-spezifischen) @include-Datei "awktv.inc"
# (Arrays N[]=Namen, W[]=Werte, muss im selben Verzeichnis liegen) geladen
# wird: für jede Eingabezeile "Name = Wert" wird geprüft, ob der Name in
# N[] vorkommt - stimmt der Wert überein, wird die Zeile unverändert
# ausgegeben, sonst der korrigierte Soll-Wert; unbekannte Namen werden
# unverändert durchgereicht. Am Ende werden alle Namen aus N[], die in der
# Eingabedatei gar nicht vorkamen, zusätzlich angehängt. Aufruf:
# gawk -f awktv.sh <datei> (erfordert gawk wegen @include; die Ausgabe muss
# vom Aufrufer in die Zieldatei umgeleitet werden, awktv.sh schreibt nicht
# selbst in die Datei zurück).
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
# Eintraege, muss im gleichen Verzeichnis stehen
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
