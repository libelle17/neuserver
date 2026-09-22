#!/bin/bash
# bupull_wrapper_streng.sh - ENTWURF einer Erlaubnisliste fuer die Pull-Schluessel der Reserver
# (linux0/linux7) auf linux1, nach dem Vorbild von backup_ssh_wrapper.sh (Push-Richtung).
#
# STAND 22.9.2026: NOCH NICHT SCHARF GESCHALTET. Weder in authorized_keys eingetragen noch nach
# /root/bin kopiert. Abgeleitet NUR aus den Befehlen im Lernlog (/var/log/backup_pull_wrapper.log,
# 21.9. 14:15 bis 22.9. 09:xx), die (a) in den Sicherungsfenstern liegen UND (b) zu den vorab als
# bekannt genannten Sicherungsmustern gehoeren: test/stat/find/mkdir unter /DATA und
# /var/lib/bustate, rsync --server --sender nur lesend (Ziel unter /DATA, per readlink -m
# erzwungen - NICHT nur textuell), der Heartbeat-Befehl (Pseudo-Skriptnamen
# bumo.sh|bulinux.sh|bunacht.sh|platz), sdauffuellen.sh -e, dopweg.sh -e, sowie der
# Erreichbarkeits-Ping "ssh <Ziel> echo ''" (kommt als "echo " mit Leerzeichen an, s. bugem.sh
# Zeile 824/830).
#
# ABSICHTLICH NICHT ENTHALTEN (im Lernlog vorhanden, aber nicht in den obigen 5 Kategorien und
# nicht ohne Rueckfrage aufgenommen - s. Bericht an Gerald):
#   - rsync --server --sender auf Pfade AUSSERHALB /DATA (u.a. /root/.mysqlrpwd, /root/.7zpassw,
#     /root/.modbpwd, /root/.mysqlpwd, /root/.fbcredentials, /root/.sturm, /root/.wser,
#     /root/dbverbfreigabe, /root/.vim, /root/bin/, /root/crontabakt, /root/.getmail/,
#     /etc/postfix/*, /etc/sysconfig/postfix, /mnt/wser/*, /srv/www/htdocs/*,
#     /home/schade/.wincredentials): das sind aktuell echte, notwendige Bestandteile der
#     Sicherung (kopieros() in bugem.sh) - ohne sie wuerde diese strenge Fassung die Sicherung
#     BRECHEN, wenn sie so aktiviert wuerde. /root/.getmail/ zusaetzlich heikel: die
#     Einschraenkung auf *rc/oldmail-* passiert erst durch clientseitige rsync-Filter, die im
#     Protokoll uebertragen werden und in $SSH_ORIGINAL_COMMAND NICHT sichtbar sind - ein Wrapper
#     kann sie also nicht erzwingen, nur den Pfad selbst.
#   - mariadb/mariadb-dump-Aufrufe (bulinux.sh: Versionspruefung, SHOW DATABASES, mariadb-dump-Weg)
#   - mountpoint/findmnt auf Windows-Freigaben ausserhalb /DATA (/mnt/wser/indamed, /mnt/wser/mosich,
#     /mnt/anmmw)
#   - /usr/libexec/ssh/sftp-server (Sonderfall, s. Bericht)
#   - alles Interaktive/Administrative der Schwesterinstanz (crontab -l/-, cd, sed -i, cp -a,
#     bash -s, cat >.../neuserver/*, git, ls -la, chmod, restorecon, snapper, journalctl, ...)
#
# Testschema: teste_bupull_wrapper_streng.sh (Attrappen wie bei backup_ssh_wrapper.sh).

LOG=/var/log/backup_pull_wrapper_streng.log
CMD="$SSH_ORIGINAL_COMMAND"
QUELLE="${SSH_CONNECTION%% *}"
case "$QUELLE" in
  192.168.178.20) HOST=linux0;;
  192.168.178.27) HOST=linux7;;
  *) HOST="";;
esac

log() { printf '%s [%s/%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${QUELLE:-?}" "${HOST:-?}" "${1:-ABGELEHNT}" >>"$LOG" 2>/dev/null; }

if [ -z "$CMD" ]; then log "ABGELEHNT-LEER: <interaktive Sitzung>"; exit 1; fi
if [ -z "$HOST" ]; then log "ABGELEHNT-UNBEKANNTE-QUELLE: $CMD"; exit 1; fi

# Pfad darf keine Shell-Metazeichen enthalten (Verteidigung gegen Injection ueber einen
# manipulierten Pfad, auch wenn wir unten ohnehin nicht per Shell re-evaluieren)
sicherer_pfad() {
  case "$1" in
    *';'*|*'|'*|*'&'*|*'$('*|*'`'*|*'>'*|*'<'*|*$'\n'*|*$'\r'*|*$'\t'*) return 1;;
    *) return 0;;
  esac
}

# nur unter /DATA bzw. /var/lib/bustate, nach Aufloesung (readlink -m: keine "..", keine Symlinks
# aus dem erlaubten Baum heraus)
unter_data_oder_bustate() {
  sicherer_pfad "$1" || return 1
  local aufgeloest; aufgeloest=$(readlink -m -- "$1" 2>/dev/null)
  case "$aufgeloest" in
    /DATA|/DATA/*|/var/lib/bustate|/var/lib/bustate/*) return 0;;
    *) return 1;;
  esac
}

# --- 1) rsync-Protokoll (Server-Modus, --sender: linux1 LIEST und sendet) ---------------------
rsync_rest=""; rsync_pre=""
case "$CMD" in
  "rsync --server --sender "*)                       rsync_rest="${CMD#rsync --server --sender }";;
  "ionice -c2 nice -n10 rsync --server --sender "*)  rsync_rest="${CMD#ionice -c2 nice -n10 rsync --server --sender }"
                                                      rsync_pre="ionice -c2 nice -n10";;
  "ionice -c3 nice -n19 rsync --server --sender "*)  rsync_rest="${CMD#ionice -c3 nice -n19 rsync --server --sender }"
                                                      rsync_pre="ionice -c3 nice -n19";;
esac
if [ -n "$rsync_rest" ]; then
  bereinigt="${CMD//\\?/_}"
  case "$bereinigt" in
    *[\;\|\&\$\`\<\>\(\)\{\}\*\?\!\"\'\#\~\\\[\]]*|*$'\t'*|*$'\n'*|*$'\r'*)
      log "ABGELEHNT-RSYNC-METAZEICHEN: $CMD"; exit 1;;
  esac
  IFS=' ' read -a rs_tok <<<"$rsync_rest"
  rs_phase=opt; rs_npfad=0
  for rs_t in "${rs_tok[@]}"; do
    if [ "$rs_phase" = opt ]; then
      if [ "$rs_t" = "." ]; then rs_phase=pfad; continue; fi
      case "$rs_t" in
        --files-from=-|--from0|--delete|--delete-before|--delete-during|--delete-after|--delete-delay|--delete-excluded|--numeric-ids|--inplace|--partial|--ignore-errors|--no-i-r|--no-inc-recursive|--size-only|--ignore-existing|--existing|--preallocate) ;;
        -*)
          if [[ "$rs_t" =~ ^-[vlogDtprzcCiLsxXHAaunNRSPWhkKmdOJyUEq]*(e[.A-Za-z0-9]*)?$ ]] && [ "$rs_t" != "-" ]; then :; else
            log "ABGELEHNT-RSYNC-OPTION: $CMD"; exit 1
          fi;;
        *) log "ABGELEHNT-RSYNC-OPTION: $CMD"; exit 1;;
      esac
    else
      case "$rs_t" in -*) log "ABGELEHNT-RSYNC-OPTION: $CMD"; exit 1;; esac
      if ! unter_data_oder_bustate "$rs_t"; then
        # /var/lib/bustate ist beim eigentlichen Datentransfer nicht vorgesehen, nur /DATA;
        # unter_data_oder_bustate() wird trotzdem verwendet, damit ein spaeterer Fund keine
        # Ueberraschung ist - tatsaechlich beobachtete Ziele sind ausschliesslich unter /DATA.
        log "ABGELEHNT-RSYNC-AUSSERHALB-DATA: $CMD"; exit 1
      fi
      rs_npfad=$((rs_npfad+1))
    fi
  done
  if [ "$rs_phase" != pfad ] || [ "$rs_npfad" -lt 1 ]; then
    log "ABGELEHNT-RSYNC-FORM: $CMD"; exit 1
  fi
  log "OK-RSYNC: $CMD"
  # shellcheck disable=SC2086
  exec $rsync_pre rsync --server --sender "${rs_tok[@]}"
fi

# --- 2) exakte, feste Befehle (kein variabler Teil) --------------------------------------------
case "$CMD" in
  "/root/bin/sdauffuellen.sh -e"|"/root/bin/dopweg.sh -e"|"echo "|"mountpoint -q /DATA 2>/dev/null"|"mountpoint -q /DATA||mount /DATA")
    log "OK-FEST: $CMD"
    exec bash -c "$CMD"
    ;;
esac

# --- 3) Befehlsmuster mit eingebettetem Pfad (nur /DATA bzw. /var/lib/bustate) ------------------
if [[ "$CMD" =~ ^test\ -([edf])\ \"(.+)\"$ ]]; then
  flag="${BASH_REMATCH[1]}"; pfad="${BASH_REMATCH[2]}"
  unter_data_oder_bustate "$pfad" && { log "OK-TEST-$flag: $CMD"; test "-$flag" "$pfad"; exit $?; }

elif [[ "$CMD" =~ ^\[\ -([edf])\ \"(.+)\"\ \]$ ]]; then
  # gleichwertig zu "test -X", nur Klammersyntax (kopieros()-Einzeldatei-Vorpruefung in bugem.sh)
  flag="${BASH_REMATCH[1]}"; pfad="${BASH_REMATCH[2]}"
  unter_data_oder_bustate "$pfad" && { log "OK-BRACKET-$flag: $CMD"; test "-$flag" "$pfad"; exit $?; }

elif [[ "$CMD" =~ ^stat\ -c\ %Y\ \"(.+)\"\ 2\>/dev/null$ ]]; then
  pfad="${BASH_REMATCH[1]}"
  unter_data_oder_bustate "$pfad" && { log "OK-STAT-Y: $CMD"; exec stat -c %Y -- "$pfad" 2>/dev/null; }

elif [[ "$CMD" =~ ^mkdir\ -p\ \"(.+)\"$ ]]; then
  pfad="${BASH_REMATCH[1]}"
  unter_data_oder_bustate "$pfad" && { log "OK-MKDIR: $CMD"; exec mkdir -p -- "$pfad"; }

elif [[ "$CMD" =~ ^mkdir\ -p\ \"(.+)\"\ \&\&\ \{\ \[\ -f\ \"(.+)\"\ \]\ \|\|\ touch\ -t\ ([0-9]+)\ \"(.+)\"\;\ \}$ ]]; then
  pfad1="${BASH_REMATCH[1]}"; pfad2="${BASH_REMATCH[2]}"; zeit="${BASH_REMATCH[3]}"; pfad3="${BASH_REMATCH[4]}"
  if unter_data_oder_bustate "$pfad1" && unter_data_oder_bustate "$pfad2" && unter_data_oder_bustate "$pfad3" && [ "$pfad2" = "$pfad3" ]; then
    log "OK-MKDIR-TOUCH: $CMD"
    mkdir -p -- "$pfad1" && { [ -f "$pfad2" ] || touch -t "$zeit" -- "$pfad3"; }
    exit 0
  fi

elif [[ "$CMD" =~ ^find\ \"(.+)\"\ -newer\ \"(.+)\"\ \\\(\ -type\ f\ -o\ -type\ l\ \\\)\ -print\ 2\>/dev/null$ ]]; then
  pfad1="${BASH_REMATCH[1]}"; pfad2="${BASH_REMATCH[2]}"
  if unter_data_oder_bustate "$pfad1" && unter_data_oder_bustate "$pfad2"; then
    log "OK-FIND-NEWER: $CMD"
    exec find "$pfad1" -newer "$pfad2" \( -type f -o -type l \) -print 2>/dev/null
  fi

elif [[ "$CMD" =~ ^test\ -f\ \"(.+)\"\&\&\{\ stat\ (.+)\ -c\ %s\|\|echo\ 0\;:\;\}\|\|du\ (.+)\ -d0\;$ ]]; then
  pfad1="${BASH_REMATCH[1]}"; pfad2="${BASH_REMATCH[2]}"; pfad3="${BASH_REMATCH[3]}"
  if unter_data_oder_bustate "$pfad1" && unter_data_oder_bustate "$pfad2" && unter_data_oder_bustate "$pfad3"; then
    log "OK-STAT-ODER-DU: $CMD"
    if [ -f "$pfad1" ]; then stat "$pfad2" -c %s || echo 0; else du "$pfad3" -d0; fi
    exit 0
  fi

elif [[ "$CMD" =~ ^test\ -d\ \"(.+)\"\ \&\&\ du\ (.+)\ -d0$ ]]; then
  pfad1="${BASH_REMATCH[1]}"; pfad2="${BASH_REMATCH[2]}"
  if unter_data_oder_bustate "$pfad1" && unter_data_oder_bustate "$pfad2"; then
    log "OK-TESTD-DU: $CMD"
    [ -d "$pfad1" ] && du "$pfad2" -d0
    exit 0
  fi

elif [[ "$CMD" =~ ^mkdir\ -p\ /DATA\ 2\>/dev/null\;\ touch\ \"(.+)\"\ 2\>/dev/null\;\ \{\ grep\ -v\ \"\^([a-zA-Z._-]+)\ \"\ \"(.+)\"\ 2\>/dev/null\;\ echo\ \"([a-zA-Z._-]+)\ +([0-9-]+\ [0-9:]+)\ \ ([-A-Za-z0-9%/:.,_= ]+)\"\;\ \}\ \|\ sort\ -o\ \"(.+)\"\ -\;\ mv\ \"(.+)\"\ \"(.+)\"$ ]]; then
  # Heartbeat, gebaut von backupstatus()/platzstatus() in bugem.sh: NUR /DATA/Backup-Status_<eigener Rechner>.txt,
  # NUR die vier Pseudo-Skriptnamen, Skriptname in beiden Vorkommen (grep/echo) identisch.
  datei1="${BASH_REMATCH[1]}"; skript_grep="${BASH_REMATCH[2]}"; datei2="${BASH_REMATCH[3]}"
  skript_echo="${BASH_REMATCH[4]}"; zeit="${BASH_REMATCH[5]}"; status="${BASH_REMATCH[6]}"
  neu="${BASH_REMATCH[7]}"; mv1="${BASH_REMATCH[8]}"; mv2="${BASH_REMATCH[9]}"
  erwartet="/DATA/Backup-Status_${HOST}.txt"
  if [ "$datei1" = "$erwartet" ] && [ "$datei2" = "$erwartet" ] && [ "$mv1" = "${erwartet}.neu" ] && [ "$mv2" = "$erwartet" ] \
     && [ "$neu" = "${erwartet}.neu" ] && [ "$skript_grep" = "$skript_echo" ] \
     && [[ "$skript_grep" =~ ^(bumo\.sh|bulinux\.sh|bunacht\.sh|platz)$ ]]; then
    log "OK-HEARTBEAT: $CMD"
    mkdir -p /DATA 2>/dev/null; touch "$erwartet" 2>/dev/null
    { grep -v "^$skript_grep " "$erwartet" 2>/dev/null; printf '%-12s %s  %s\n' "$skript_grep" "$zeit" "$status"; } | sort -o "${erwartet}.neu" -
    mv "${erwartet}.neu" "$erwartet"
    exit 0
  fi
fi

log "ABGELEHNT-UNBEKANNT: $CMD"
exit 1
