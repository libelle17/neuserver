#!/bin/bash
# repo_sperre.sh "Grund" - sperrt auf linux0/linux7 die naechtliche Uebernahme von github (los.sh -pa/-pasofort,
# s. progaktualisieren in los.sh), bis jemand von Hand die Sperrdatei loescht. Aufgerufen bei Warnzeichen fuer einen
# Angriff: abweichende Schutzdatei (bugem.sh), Platzeinbruch (platzwaechter.sh), umgeschriebener Verlauf auf github.
# So verbreitet sich nichts weiter, auch wenn in dem Moment niemand an die Wartezeit denkt. Pruefung und Sperre
# laufen auf dem Sicherungsrechner selbst, ein befallener linux1 kann sie nicht aufheben.
# Aufheben (erst nach Pruefung): rm /var/lib/wecklauf/repo_sperre
S=${REPO_SPERRE_DATEI:-/var/lib/wecklauf/repo_sperre};
EMPF=${REPO_SPERRE_EMPF:-diabetologie@dachau-mail.de, gerald.schade@gmx.de, geraldschade@gmx.de};
h=$(hostname -s);
case "$h" in linux0|linux7) ;; *) exit 0;; esac;
[ -f /etc/notfallbetrieb ]&&exit 0;
neu=; [ -f "$S" ]||neu=1;
mkdir -p "$(dirname "$S")";
printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$S";
[ "$neu" ]||exit 0;
{ printf 'To: %s\nSubject: WARNUNG %s: Uebernahme von github gesperrt\nContent-Type: text/plain; charset=UTF-8\n\n' "$EMPF" "$h";
  printf 'Auf %s wurde die naechtliche Uebernahme von Skripten und Programmen von github gesperrt.\n\nGrund: %s\n\nDas kann auf einen Angriff ueber linux1 hindeuten. Bitte pruefen, bevor die Sperre aufgehoben wird.\nAufheben auf %s: rm %s\n\nCommits, die vor der Sperre schon in der Wartezeit waren, koennten danach sofort uebernommen werden:\ngegebenenfalls /var/lib/wecklauf/repostand_* ansehen.\n' "$h" "$*" "$h" "$S"; } | /usr/sbin/sendmail -t;
exit 0;
