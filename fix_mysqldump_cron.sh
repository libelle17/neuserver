#!/bin/sh
# fix_mysqldump_cron.sh
# Korrigiert alle mysqldump-Aufrufe in crontab:
# 1. Fügt sed-Filter ein der DEFINER entfernt
# 2. Ersetzt mysqldump durch mariadb-dump falls vorhanden
# Aufruf: sh fix_mysqldump_cron.sh
# Danach: crontab /tmp/crontab_neu.txt

set -e

CRONTAB_ALT=/tmp/crontab_alt.txt
CRONTAB_NEU=/tmp/crontab_neu.txt

# Aktuelle crontab sichern
crontab -l > "$CRONTAB_ALT"
cp "$CRONTAB_ALT" "${CRONTAB_ALT}.bak"
printf "Aktuelle crontab gesichert in $CRONTAB_ALT\n"

# mysqldump-Befehl ermitteln
DUMP=$(which mariadb-dump 2>/dev/null || which mysqldump 2>/dev/null || echo mysqldump)
printf "Verwende Dump-Befehl: $DUMP\n"

# Transformation:
# mysqldump ... DB > /DATA/sql/DB--`date...`.sql
# wird zu:
# mysqldump ... DB | sed 's/DEFINER=`[^`]*`@`[^`]*`//g' > /DATA/sql/DB--`date...`.sql
awk -v dump="$DUMP" '
/mysqldump.*--routines.*> \/DATA\/sql\// {
    # mysqldump durch aktuellen Befehl ersetzen
    gsub(/\/usr\/bin\/mysqldump/, dump);
    gsub(/mysqldump/, dump);
    # "> /DATA/sql/" durch "| sed ... > /DATA/sql/" ersetzen
    gsub(/> \/DATA\/sql\//, "| sed '\''s/DEFINER=`[^`]*`@`[^`]*`//g'\'' > /DATA/sql/");
    print;
    next;
}
{ print }
' "$CRONTAB_ALT" > "$CRONTAB_NEU"

printf "\nKorrigierte crontab in $CRONTAB_NEU\n"
printf "\nUnterschiede:\n"
diff "$CRONTAB_ALT" "$CRONTAB_NEU" || true

printf "\nSoll die neue crontab installiert werden? [j/N] "
read antwort
case "$antwort" in
  j|J|y|Y)
    crontab "$CRONTAB_NEU"
    printf "Neue crontab installiert.\n"
    crontab -l | grep -n "mysqldump\|mariadb-dump" | head -20
    ;;
  *)
    printf "Abgebrochen. Zum manuellen Installieren:\n  crontab $CRONTAB_NEU\n"
    ;;
esac
