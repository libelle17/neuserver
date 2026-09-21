#!/bin/bash
# crontab_waechter_nur_linux1.sh - beschraenkt die Cron-Zeilen von massenaenderung_waechter.sh und
# aenderungsrate_erhebung.sh in der crontab DIESES Rechners auf linux1 (Rechner-Bedingung wie bei den
# uebrigen Zeilen: HOST=$(hostname);[ ${HOST\%\%.*}/ = linux1/ ]&&...).
#
# Anlass (21.9.2026): Beide Zeilen liefen auf allen Rechnern. Auf den Reservern (linux0/linux7) aendert das
# Backup selbst hunderttausende Dateien pro Fenster; der Waechter meldete deshalb "Massenaenderung, moeglicher
# Ransomware-Verdacht" (Fehlalarm), und aenderungsrate_erhebung.sh lief auf linux0 durch alle Snapshots so
# langsam, dass es das 5-Minuten-Intervall nicht schaffte. Jeder Rechner hat seine EIGENE crontab.
#
# Aufruf:  crontab_waechter_nur_linux1.sh            zeigt nur, was geaendert wuerde (nichts wird geschrieben)
#          crontab_waechter_nur_linux1.sh --anwenden sichert die crontab und schreibt die neue Fassung
#          crontab_waechter_nur_linux1.sh -f <Datei> [--anwenden]   arbeitet auf einer Datei statt der crontab (Test)
# Idempotent: Zeilen, die schon eine HOST=$(hostname)-Bedingung tragen, bleiben unveraendert; Kommentarzeilen
# und alle anderen Zeilen ebenfalls. Sicherung: <BAK_DIR>/crontab_<Rechner>_vor_waechterguard_<Zeit>.txt
# (BAK_DIR = /root/neuserver/private_backups, sonst /root).
ANWENDEN=; DATEI=
while [ $# -gt 0 ]; do case "$1" in --anwenden) ANWENDEN=1;; -f) DATEI=$2; shift;; *) sed -n '2,19p' "$0"; exit 1;; esac; shift; done
host=$(hostname); host=${host%%.*}
if [ -n "$DATEI" ]; then QUELLE=$(cat "$DATEI"); else QUELLE=$(crontab -l 2>/dev/null); fi
[ -n "$QUELLE" ] || { echo "keine crontab gefunden"; exit 1; }
NEU=$(printf '%s\n' "$QUELLE" | python3 -c '
import sys,re
guard="HOST=$(hostname);[ ${HOST\\%\\%.*}/ = linux1/ ]&&"
n=0; out=[]
for l in sys.stdin.read().split("\n"):
    if l.lstrip().startswith("#") or not l.strip(): out.append(l); continue
    if ("massenaenderung_waechter.sh" in l or "aenderungsrate_erhebung.sh" in l) and "HOST=$(hostname)" not in l:
        m=re.match(r"^(-?)(\S+\s+\S+\s+\S+\s+\S+\s+\S+)\s+(.*)$",l)
        if m: l=m.group(1)+m.group(2)+" "+guard+m.group(3); n+=1
    out.append(l)
print("\n".join(out).rstrip("\n"))
sys.stderr.write(str(n))
' 2>/tmp/.cwn1_n.$$); ANZAHL=$(cat /tmp/.cwn1_n.$$ 2>/dev/null); rm -f /tmp/.cwn1_n.$$
echo "Rechner: $host   zu aendernde Zeilen: ${ANZAHL:-0}"
diff <(printf '%s\n' "$QUELLE") <(printf '%s\n' "$NEU") | grep -E '^[<>]' | cut -c1-230
if [ "${ANZAHL:-0}" = 0 ]; then echo "Nichts zu tun (schon beschraenkt oder Zeilen nicht vorhanden)."; exit 0; fi
[ -n "$ANWENDEN" ] || { echo "(Anzeigemodus: nichts geschrieben. Zum Anwenden: --anwenden)"; exit 0; }
BD=/root/neuserver/private_backups; [ -d /root/neuserver ] && mkdir -p "$BD" || BD=/root
B="$BD/crontab_${host}_vor_waechterguard_$(date +%Y%m%d_%H%M%S).txt"; printf '%s\n' "$QUELLE" > "$B" && echo "Sicherung: $B"
if [ -n "$DATEI" ]; then printf '%s\n' "$NEU" > "$DATEI"; echo "Datei $DATEI geschrieben."
else printf '%s\n' "$NEU" | crontab - && echo "crontab installiert."; fi
