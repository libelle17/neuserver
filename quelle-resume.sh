#!/bin/bash
# quelle-resume.sh – Wiederaufnahme des quelle-Imports nach Absturz
# Verwendung: bash quelle-resume.sh [/pfad/zur/dump.sql]
set -euo pipefail

SQL="${1:-/var/tmp/quelle-restore.sql}"
MARIADB="mariadb --defaults-extra-file=/root/.mysqlrpwd"
INIT="SET SESSION foreign_key_checks=0; SET SESSION unique_checks=0; SET SESSION sql_log_bin=0;"

# ── Dump-Datei vorbereiten ──────────────────────────────────────────────
if [ ! -f "$SQL" ]; then
  echo "Suche jüngste quelle--*.sql >= 8 GB in /DATA/sql/ ..."
  SRC=$(find /DATA/sql -maxdepth 1 -name "quelle--*.sql" \
    -size +8000000000c -printf "%T@ %p\n" 2>/dev/null \
    | sort -rn | head -1 | cut -d" " -f2-)
  if [ -z "$SRC" ]; then
    echo "Keine passende Datei gefunden (>= 8 GB) in /DATA/sql/"; exit 1
  fi
  echo "Gefunden: $SRC ($(du -sh "$SRC" | cut -f1))"
  echo "Kopiere nach $SQL ..."
  cp "$SRC" "$SQL"
  echo "Kopieren abgeschlossen."
fi

# ── Erstlauf: Datenbank anlegen falls fehlend oder leer ─────────────────
DB_EXISTS=$(${MARIADB} -BN -e \
  "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='quelle';" 2>/dev/null||echo 0)
N_EXIST=$(${MARIADB} -BN -e \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='quelle' AND table_type='BASE TABLE';" \
  2>/dev/null||echo 0)
if [ "${DB_EXISTS:-0}" -eq 0 ]; then
  echo "Datenbank quelle fehlt – lege an..."
  ${MARIADB} -e "CREATE DATABASE IF NOT EXISTS \`quelle\` \
    DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci;" 2>/dev/null
fi
if [ "${N_EXIST:-0}" -eq 0 ]; then
  echo "Erstlauf (0 Tabellen vorhanden) – importiere vollständig."
else
  echo "Wiederaufnahme ($N_EXIST Tabellen bereits vorhanden)."
fi

echo "=== quelle-Import ==="
echo "Dump: $SQL ($(du -sh "$SQL" | cut -f1))"

# ── 1. Tabellen aus Dump-Datei in Reihenfolge ────────────────────────────────
ALL_TABLES=$(grep "^-- Table structure for table" "$SQL" \
  | sed "s/-- Table structure for table \`//;s/\`.*//")
TOTAL=$(echo "$ALL_TABLES" | wc -l)
echo "Tabellen im Dump: $TOTAL"

# ── 2. Bereits existierende Tabellen in quelle ───────────────────────────────
EXISTING=$(${MARIADB} -BN -e "SHOW TABLES FROM quelle;" 2>/dev/null || true)
IMPORTED=$(echo "$ALL_TABLES" | while read tbl; do
  echo "$EXISTING" | grep -qx "$tbl" && echo "$tbl" || break
done)
N_DONE=$(echo "$IMPORTED" | grep -c . 2>/dev/null || echo 0)

if [ "$N_DONE" -eq "$TOTAL" ]; then
  echo "Alle $TOTAL Tabellen bereits importiert – nichts zu tun."
  ${MARIADB} -e "SELECT COUNT(*) AS tabellen FROM information_schema.tables WHERE table_schema='quelle'"
  exit 0
fi

# ── 3. Letzte importierte Tabelle löschen (könnte unvollständig sein) ────────
LAST_OK=$(echo "$IMPORTED" | tail -1)
if [ -n "$LAST_OK" ]; then
  echo "Lösche letzte Tabelle (evtl. unvollständig): ${LAST_OK}"
  ${MARIADB} -e "DROP TABLE IF EXISTS \`quelle\`.\`${LAST_OK}\`;" 2>/dev/null || true
  # N_DONE korrigieren
  N_DONE=$((N_DONE - 1))
fi

RESUME_TABLE=$(echo "$ALL_TABLES" | sed -n "$((N_DONE + 1))p")
echo "Bereits importiert: $N_DONE von $TOTAL"
echo "Starte ab Tabelle : $RESUME_TABLE"

# ── 4. Zeilennummer im Dump finden ───────────────────────────────────────────
STARTLINE=$(grep -n "^-- Table structure for table \`${RESUME_TABLE}\`" "$SQL" \
  | head -1 | cut -d: -f1)
echo "Dump-Zeile        : $STARTLINE"
echo ""

# ── 5. Import: Preamble (SET-Variablen) + Rest ab STARTLINE ─────────────────
echo "Starte Import..."
{ head -30 "$SQL"; sed -n "${STARTLINE},\$p" "$SQL"; } \
  | ionice -c2 nice -n10 \
    ${MARIADB} --force \
    --init-command="${INIT}" \
  2>&1 | tee /var/tmp/quelle-resume.log

echo ""
echo "=== Ergebnis ==="
${MARIADB} -e \
  "SELECT COUNT(*) AS tabellen FROM information_schema.tables WHERE table_schema='quelle' AND table_type='BASE TABLE'"
