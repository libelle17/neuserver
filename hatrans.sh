#!/bin/bash 
STAMPFILE="$HOME/.medoff_last_zp"

# -v Option auswerten
verbose=0
while getopts "v" opt; do
  case $opt in
    v) verbose=1 ;;
  esac
done

log() {
  [ "$verbose" -eq 1 ] && echo "$@"
}

log "Frage aktuellen Zeitstempel ab ..."
zp=$(mariadb --defaults-extra-file=~/.modbpwd medoff -N -B -e"SELECT 18900101+INTERVAL fdatum DAY+INTERVAL fuhrzeit SECOND zp
FROM dbsprot d
WHERE ftablename IN('epraxis','earzt','patrelation')
ORDER BY d.fsurogat DESC LIMIT 1")
log "Aktueller Zeitstempel: $zp"

last_zp=""
if [ -f "$STAMPFILE" ]; then
  last_zp=$(cat "$STAMPFILE")
fi
log "Letzter Zeitstempel:   $last_zp"

if [[ "$zp" > "$last_zp" ]]; then
  log "Neuer Zeitstempel ist jünger -> Synchronisation wird durchgeführt"

  log "Leere tmpmepraxis und rufe procmepraxis(0) auf ..."
  mariadb --defaults-extra-file=~/.modbpwd medoff -e"truncate tmpmepraxis; call procmepraxis(0);" >/dev/null 2>&1

  for tb in earzt tmpmepraxis epraxis patrelation; do
    log "Übertrage Tabelle $tb ..."
    mariadb-dump --defaults-extra-file=~/.modbpwd medoff "$tb" | mariadb --defaults-extra-file=~/.mariadbpwd quelle >/dev/null 2>&1
  done

  echo "$zp" > "$STAMPFILE"
  log "Zeitstempel $zp gespeichert. Fertig."
else
  log "Kein neuerer Stand vorhanden -> nichts zu tun"
fi
