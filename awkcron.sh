# awkcron.sh - kein eigenständiges Skript (kein Shebang), sondern ein
# awk-Programm zum Aufruf per "awk -f awkcron.sh" im Verzeichnis mit den
# beiden Dateien "cronhier" (Crontab-Zeilen dieses Rechners) und
# "cronslinux1" (Crontab-Zeilen von linux1): gibt zunächst alle Zeilen aus
# "cronhier" aus, die NICHT (Groß-/Kleinschreibung ignorierend, IGNORECASE=1)
# in "cronslinux1" vorkommen, danach alle Zeilen aus "cronslinux1" - dient
# also dem Abgleich/Diff zweier Cron-Konfigurationen. Aufruf ohne Parameter,
# im Verzeichnis mit den Dateien "cronhier"/"cronslinux1".
function liesein(var,datei) {
	i=0;
	while ((getline var[++i] < datei)>0) {
	}
	delete var[i];
	close(datei);
}

BEGIN {
	IGNORECASE=1;
	liesein(ch,"cronhier");
	liesein(cl,"cronslinux1");

	for(i in ch) {
		obschreib=1;
		for(j in cl) {
			if (ch[i]==cl[j]) {
				obschreib=0;
			  break;
			}
		}
		if (obschreib) {
			print i,ch[i];
		}
	}
	for(j in cl) {
		print j,cl[j];
	}
}
