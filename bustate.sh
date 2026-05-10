#!/bin/bash
# bustate.sh – Zeitstempel-basierte Änderungserkennung für inkrementelles Backup
# Wird von bulinux.sh und ähnlichen Skripten NACH bugem.sh gesourct.
# Nutzt: $qssh (aus machssh()), $verb, $blau, $reset, $obecht, $QL, $ZL
#
# Funktionen:
#   bustate_tsfile <zielhost>           – Pfad zur Zeitstempeldatei auf Quellrechner
#   bustate_init   <zielhost>           – Zeitstempeldatei anlegen falls fehlend
#   bustate_update <zielhost>           – Zeitstempel nach Backup aktualisieren
#   bustate_changed <qverz> <zh> <out>  – geänderte Dateien seit letztem Backup finden
#
# Zeitstempeldateien liegen auf dem QUELLRECHNER (linux1) in /var/run/bustate/
# und bekommen den Zielrechner als Suffix: bu_linux0.ts, bu_linux7.ts …
# Bei Erstanlage wird der Timestamp auf 1970-01-01 gesetzt → Erstlauf-Marker.

BUSTATE_DIR="/var/run/bustate"

# -----------------------------------------------------------------------
bustate_tsfile() {
  # Gibt Pfad zur Zeitstempeldatei auf dem Quellrechner zurück.
  # $1 = Zielrechner (z.B. linux0, linux7), leer = lokal
  printf "%s/bu_%s.ts" "$BUSTATE_DIR" "${1:-lokal}"
} # bustate_tsfile

# -----------------------------------------------------------------------
bustate_init() {
  # Legt Verzeichnis und Zeitstempeldatei auf dem Quellrechner an,
  # falls noch nicht vorhanden. Timestamp = 1970-01-01 = Erstlauf-Marker.
  # $1 = Zielrechner, leer = $ZL
  local tsf
  tsf=$(bustate_tsfile "${1:-${ZL:-lokal}}")
  eval "$qssh 'mkdir -p \"$BUSTATE_DIR\" && { [ -f \"$tsf\" ] || touch -t 197001010000 \"$tsf\"; }'" 2>/dev/null
} # bustate_init

# -----------------------------------------------------------------------
bustate_update() {
  # Setzt Zeitstempel auf aktuelle Zeit (nach erfolgreichem Backup).
  # Sollte NUR aufgerufen werden wenn das gesamte Backup fehlerfrei war.
  # $1 = Zielrechner, leer = $ZL
  local zielhost tsf
  zielhost="${1:-${ZL:-lokal}}"
  tsf=$(bustate_tsfile "$zielhost")
  if [ "$obecht" ]; then
    eval "$qssh 'touch \"$tsf\"'"
    printf "${blau}bustate_update${reset}: Zeitstempel ${blau}%s${reset} gesetzt" "$tsf"
    printf " (Quelle: ${blau}%s${reset} → Ziel: ${blau}%s${reset})\n" "${QL:-lokal}" "$zielhost"
  else
    printf "Simulation: ${blau}touch %s${reset} auf ${blau}%s${reset}\n" "$tsf" "${QL:-lokal}"
  fi
} # bustate_update

# -----------------------------------------------------------------------
bustate_changed() {
  # Findet alle Dateien/Symlinks unter $1, die seit dem letzten Backup
  # für Ziel $2 geändert wurden. Schreibt relative Pfade nach $3.
  #
  # $1 = Quellverzeichnis ABSOLUT (z.B. /DATA oder /mnt/wser/indamed)
  # $2 = Zielrechner (leer = $ZL)
  # $3 = lokale Ausgabedatei (wird überschrieben)
  #
  # Setzt danach:
  #   $bustate_count    – Anzahl gefundener Dateien (int)
  #   $bustate_erstlauf – "1" wenn Erstlauf (Timestamp = Epoche 0), sonst leer
  local quellverz="${1%/}"    # trailing Slash entfernen
  local zielhost="${2:-${ZL:-lokal}}"
  local outfile="$3"
  bustate_erstlauf=
  bustate_count=0
  > "$outfile"

  # Zeitstempeldatei anlegen falls noch nicht vorhanden
  bustate_init "$zielhost"

  # Erstlauf erkennen: Timestamp ≤ 86400 s nach Epoche (= 1. Jan 1970)
  local tsf tsage
  tsf=$(bustate_tsfile "$zielhost")
  tsage=$(eval "$qssh 'stat -c %Y \"$tsf\" 2>/dev/null'")
  if [ "${tsage:-0}" -le 86400 ] 2>/dev/null; then
    bustate_erstlauf=1
    [ "$verb" ] && printf \
      "${blau}bustate${reset}: Erstlauf für ${blau}%s${reset} → ${blau}%s${reset}\n" \
      "$quellverz" "$zielhost"
    return 0
  fi

  # Geänderte Dateien/Symlinks finden; Pfade relativ zu $quellverz ausgeben
  eval "$qssh 'find \"$quellverz\" -newer \"$tsf\" \( -type f -o -type l \) -print 2>/dev/null'" \
    | sed "s|^${quellverz}/||" \
    | grep -v '^$' \
    | LC_ALL=C sort > "$outfile"

  bustate_count=$(wc -l < "$outfile" | tr -d ' ')

  if [ "$verb" ]; then
    local tsdate
    tsdate=$(eval "$qssh 'date -r \"$tsf\" +\"%d.%m.%Y %T\" 2>/dev/null'")
    printf "${blau}bustate_changed${reset}: ${blau}%s${reset} Dateien unter ${blau}%s${reset}" \
      "$bustate_count" "$quellverz"
    printf " (seit ${blau}%s${reset}, Ziel: ${blau}%s${reset})\n" \
      "${tsdate:-?}" "$zielhost"
  fi
} # bustate_changed
