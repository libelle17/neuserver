#!/bin/bash
# bupull_lernen.sh - wertet /var/log/backup_pull_wrapper.log aus: welche Befehle fuehren die Reserver
# auf linux1 aus? Zahlen, Zeitstempel und Pfade werden zusammengefasst, damit die Liste uebersichtlich
# bleibt. Grundlage fuer eine Erlaubnisliste (wie backup_ssh_wrapper.sh).
LOG=/var/log/backup_pull_wrapper.log
[ -s "$LOG" ] || { echo "noch kein Log ($LOG)"; exit 0; }
echo "Eintraege: $(wc -l <"$LOG"), von $(head -1 "$LOG" | cut -c1-19) bis $(tail -1 "$LOG" | cut -c1-19)"
echo "Quellen:"; awk '{print $3}' "$LOG" | sort | uniq -c
echo; echo "Befehlsmuster (Anzahl, Quelle, normalisierter Befehl):"
sed -E 's/^[0-9-]+ [0-9:]+ \[([0-9.]+)\] /\1\t/; s/[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]{8}/DATUM/g; s/bu_delta_[0-9]+/bu_delta_N/g; s/[0-9]{3,}/N/g' "$LOG" | sort | uniq -c | sort -rn | cut -c1-230 | head -${1:-40}
