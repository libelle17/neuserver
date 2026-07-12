#!/bin/bash
# Forced-Command-Wrapper fuer den eingeschraenkten Backup-Automatik-Key
# (id_ed25519_backup, genutzt von bumo.sh/bunacht.sh/bugem.sh beim Push
# linux1 -> linux0/linux7). Eingetragen als "command=" in authorized_keys,
# damit dieser Key KEINE freie Shell bekommt, sondern nur exakt die hier
# erlaubten, vorab aus bugem.sh ermittelten Befehlsmuster ausfuehren kann.
# Alles andere wird abgelehnt und protokolliert.
#
# Eingerichtet 12.7.2026, s. Anleitung_Ransomware_Vorsorge_und_Notfall.md.
# Sicherheitsziel: ein kompromittiertes linux1 soll ueber diesen Kanal keine
# freie Shell und keinen Zugriff ausserhalb von /DATA bzw. der hier gelisteten
# engen Operationen mehr bekommen.

LOG=/var/log/backup_ssh_wrapper.log
CMD="$SSH_ORIGINAL_COMMAND"

log() { printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$CMD" >>"$LOG"; }

if [ -z "$CMD" ]; then
  log "ABGELEHNT-LEER"
  exit 1
fi

# Pfad darf keine Shell-Metazeichen enthalten (Verteidigung gegen Injection
# ueber einen manipulierten Pfad, auch wenn wir unten ohnehin nicht re-evaluieren)
sicherer_pfad() {
  case "$1" in
    *';'*|*'|'*|*'&'*|*'$('*|*'`'*|*'>'*|*'<'*|*$'\n'*) return 1;;
    *) return 0;;
  esac
}

# --- 1) rsync-Protokoll: nur Ziele innerhalb von /DATA erlauben ---
case "$CMD" in
  "rsync --server"*)
    letztes_wort="${CMD##* }"
    aufgeloest=$(readlink -m -- "$letztes_wort" 2>/dev/null)
    case "$aufgeloest" in
      /DATA|/DATA/*)
        log "OK-RSYNC"
        exec bash -c "$CMD"
        ;;
      *)
        log "ABGELEHNT-RSYNC-AUSSERHALB-DATA"
        exit 1
        ;;
    esac
    ;;
esac

# --- 2) exakte, feste Befehle (kein variabler Teil) ---
case "$CMD" in
  "systemctl stop mysql"|"systemctl start mysql"|"pkill -9 mysqld"|"echo ''"|"echo ")
    log "OK-FEST"
    exec bash -c "$CMD"
    ;;
  "chown root:root /root; chmod 700 /root; setfacl -m mask::x /root 2>/dev/null; [ -d /root/.ssh ] && { chown root:root /root/.ssh; chmod 700 /root/.ssh; chmod 600 /root/.ssh/authorized_keys 2>/dev/null; }")
    log "OK-SSH-REPARATUR"
    exec bash -c "$CMD"
    ;;
esac

# --- 3) Befehlsmuster mit einem eingebetteten Pfad ---
if [[ "$CMD" =~ ^stat\ \"(.+)\"\ \>/dev/null\ 2\>\&1\ ?$ ]]; then
  pfad="${BASH_REMATCH[1]}"
  sicherer_pfad "$pfad" && { log "OK-STAT"; stat -- "$pfad" >/dev/null 2>&1; exit $?; }
elif [[ "$CMD" =~ ^date\ \+%s\ -r\ \"(.+)\"$ ]]; then
  pfad="${BASH_REMATCH[1]}"
  sicherer_pfad "$pfad" && { log "OK-DATE"; exec date +%s -r "$pfad"; }
elif [[ "$CMD" =~ ^\[\ -f\ \"(.+)\"\ \]$ ]]; then
  pfad="${BASH_REMATCH[1]}"
  sicherer_pfad "$pfad" && { log "OK-TESTF"; [ -f "$pfad" ]; exit $?; }
elif [[ "$CMD" =~ ^test\ -([edf])\ \"(.+)\"$ ]]; then
  flag="${BASH_REMATCH[1]}"; pfad="${BASH_REMATCH[2]}"
  sicherer_pfad "$pfad" && { log "OK-TEST-$flag"; test "-$flag" "$pfad"; exit $?; }
elif [[ "$CMD" =~ ^mkdir\ -p\ \"(.+)\"$ ]]; then
  pfad="${BASH_REMATCH[1]}"
  sicherer_pfad "$pfad" && { log "OK-MKDIR"; exec mkdir -p -- "$pfad"; }
elif [[ "$CMD" =~ ^sha256sum\ \"(.+)\"\ 2\>/dev/null$ ]]; then
  pfad="${BASH_REMATCH[1]}"
  sicherer_pfad "$pfad" && { log "OK-SHA256"; exec sha256sum -- "$pfad" 2>/dev/null; }
elif [[ "$CMD" =~ ^sha256sum\ (/root/[^\ ]+)\ 2\>/dev/null$ ]]; then
  pfad="${BASH_REMATCH[1]}"
  sicherer_pfad "$pfad" && { log "OK-SHA256-ROOT"; exec sha256sum -- "$pfad" 2>/dev/null; }
elif [[ "$CMD" =~ ^df\ (/.+)$ ]]; then
  pfad="${BASH_REMATCH[1]}"
  sicherer_pfad "$pfad" && { log "OK-DF"; exec df -- "$pfad"; }
elif [[ "$CMD" =~ ^test\ -d\ \"(.+)\"\&\&\{\ du\ (.+)\ -d0\;:\;\}\|\|\{\ stat\ (.+)\ -c\ %s\ 2\>/dev/null\|\|echo\ 0\;\}$ ]]; then
  pfad1="${BASH_REMATCH[1]}"; pfad2="${BASH_REMATCH[2]}"; pfad3="${BASH_REMATCH[3]}"
  if sicherer_pfad "$pfad1" && sicherer_pfad "$pfad2" && sicherer_pfad "$pfad3"; then
    log "OK-DU-ODER-STAT"
    if [ -d "$pfad1" ]; then du "$pfad2" -d0; else stat "$pfad3" -c %s 2>/dev/null || echo 0; fi
    exit 0
  fi
elif [[ "$CMD" =~ ^test\ -f\ \"(.+)\"\&\&\{\ stat\ (.+)\ -c\ %s\|\|echo\ 0\;:\;\}\|\|du\ (.+)\ -d0\;$ ]]; then
  pfad1="${BASH_REMATCH[1]}"; pfad2="${BASH_REMATCH[2]}"; pfad3="${BASH_REMATCH[3]}"
  if sicherer_pfad "$pfad1" && sicherer_pfad "$pfad2" && sicherer_pfad "$pfad3"; then
    log "OK-STAT-ODER-DU"
    if [ -f "$pfad1" ]; then stat "$pfad2" -c %s || echo 0; else du "$pfad3" -d0; fi
    exit 0
  fi
elif [[ "$CMD" =~ ^test\ -d\ \"(.+)\"\ \&\&\ du\ (.+)\ -d0$ ]]; then
  pfad1="${BASH_REMATCH[1]}"; pfad2="${BASH_REMATCH[2]}"
  if sicherer_pfad "$pfad1" && sicherer_pfad "$pfad2"; then
    log "OK-TESTD-DU"
    [ -d "$pfad1" ] && du "$pfad2" -d0
    exit 0
  fi
fi

log "ABGELEHNT-UNBEKANNT"
exit 1
