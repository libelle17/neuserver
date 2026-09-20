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

# --- 1) rsync-Protokoll (Server-Modus): Zerlegung + Pruefung, Start OHNE Shell ---
# Frueher: ganzer Text per "bash -c" und nur das LETZTE Wort geprueft -> Einschleusen
# von Befehlen (";", "$(...)") und Umgehung der Pfadpruefung ("/etc/x\ /DATA/y") moeglich.
# Jetzt: (a) Metazeichen ausserhalb von Backslash-Maskierungen abgelehnt, (b) Zerlegung
# in Woerter wie die Shell es taete, (c) Optionen nur aus Whitelist, (d) ALLE Pfadwoerter
# nach dem "." muessen (nach readlink -m) unter /DATA liegen, (e) exec direkt, ohne Shell.
# Vorkommende Formen: "rsync --server ..." und "ionice -c2 nice -n10 rsync --server ..."
# (bugem.sh: --rsync-path='$kopbef').
rsync_rest=""; rsync_pre=""
case "$CMD" in
  "rsync --server "*)                       rsync_rest="${CMD#rsync --server }";;
  "ionice -c2 nice -n10 rsync --server "*)  rsync_rest="${CMD#ionice -c2 nice -n10 rsync --server }"
                                            rsync_pre="ionice -c2 nice -n10";;
esac
if [ -n "$rsync_rest" ]; then
  bereinigt="${CMD//\\?/_}"            # maskierte Zeichen (Backslash + 1 Zeichen) neutralisieren
  case "$bereinigt" in
    *[\;\|\&\$\`\<\>\(\)\{\}\*\?\!\"\'\#\~\\\[\]]*|*$'\t'*|*$'\n'*|*$'\r'*)
      log "ABGELEHNT-RSYNC-METAZEICHEN"; exit 1;;
  esac
  IFS=' ' read -a rs_tok <<<"$rsync_rest"      # ohne -r: "\ " bleibt Teil eines Wortes, "\x" -> "x"
  rs_phase=opt; rs_npfad=0
  for rs_t in "${rs_tok[@]}"; do
    if [ "$rs_phase" = opt ]; then
      if [ "$rs_t" = "." ]; then rs_phase=pfad; continue; fi
      case "$rs_t" in
        --sender|--delete|--delete-before|--delete-during|--delete-after|--delete-delay|--delete-excluded|--numeric-ids|--inplace|--partial|--ignore-errors|--no-i-r|--no-inc-recursive|--size-only|--ignore-existing|--existing|--preallocate) ;;
        -*)
          if [[ "$rs_t" =~ ^-[vlogDtprzcCiLsxXHAaunNRSPWhkKmdOJyUEq]*(e[.A-Za-z0-9]*)?$ ]] && [ "$rs_t" != "-" ]; then :; else
            log "ABGELEHNT-RSYNC-OPTION"; exit 1
          fi;;
        *) log "ABGELEHNT-RSYNC-OPTION"; exit 1;;
      esac
    else
      case "$rs_t" in -*) log "ABGELEHNT-RSYNC-OPTION"; exit 1;; esac
      aufgeloest=$(readlink -m -- "$rs_t" 2>/dev/null)
      case "$aufgeloest" in
        /DATA|/DATA/*) rs_npfad=$((rs_npfad+1));;
        *) log "ABGELEHNT-RSYNC-AUSSERHALB-DATA"; exit 1;;
      esac
    fi
  done
  if [ "$rs_phase" != pfad ] || [ "$rs_npfad" -lt 1 ]; then
    log "ABGELEHNT-RSYNC-FORM"; exit 1
  fi
  log "OK-RSYNC"
  # shellcheck disable=SC2086
  exec $rsync_pre rsync --server "${rs_tok[@]}"
fi

# --- 2) exakte, feste Befehle (kein variabler Teil) ---
case "$CMD" in
  "systemctl stop mysql"|"systemctl start mysql"|"pkill -9 mysqld"|"echo ''"|"echo ")
    log "OK-FEST"
    exec bash -c "$CMD"
    ;;
  # 20.9.2026 ergaenzt: von bulinux.sh (Ziel /DATA) gesendete, bis dahin faelschlich
  # abgelehnte FESTE Befehle (kein variabler Teil, exakter Textvergleich):
  "test -d /DATA 2>/dev/null"|"mountpoint -q /DATA 2>/dev/null"|"mountpoint -q /DATA||{ mountpoint -q /DATA||mount /DATA;}")
    log "OK-FEST-DATA"
    exec bash -c "$CMD"
    ;;
  'semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/htdocs/(plz|vorb|behand|fertig)(/.*)?" 2>/dev/null || semanage fcontext -m -t httpd_sys_rw_content_t "/var/www/htdocs/(plz|vorb|behand|fertig)(/.*)?" 2>/dev/null || semanage fcontext -a -t httpd_sys_rw_content_t "/srv/www/htdocs/(plz|vorb|behand|fertig)(/.*)?" 2>/dev/null || semanage fcontext -m -t httpd_sys_rw_content_t "/srv/www/htdocs/(plz|vorb|behand|fertig)(/.*)?" 2>/dev/null || true; restorecon -Rv /srv/www/htdocs/plz /srv/www/htdocs/vorb /srv/www/htdocs/behand /srv/www/htdocs/fertig 2>/dev/null || true')
    log "OK-SEMANAGE"
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
