#!/bin/bash
# bupull_wrapper_streng.sh - ENTWURF einer Erlaubnisliste fuer die Pull-Schluessel der Reserver
# (linux0/linux7) auf linux1, nach dem Vorbild von backup_ssh_wrapper.sh (Push-Richtung).
#
# STAND 22.9.2026: NOCH NICHT SCHARF GESCHALTET. Weder in authorized_keys eingetragen noch nach
# /root/bin kopiert. Abgeleitet aus den Befehlen im Lernlog (/var/log/backup_pull_wrapper.log,
# 21.9. 14:15 bis 22.9. 09:xx). Erste Fassung (22.9. morgens) deckte nur die 5 vorab bekannten
# Sicherungsmuster ab (test/stat/find/mkdir unter /DATA und /var/lib/bustate, rsync --server
# --sender mit Ziel unter /DATA, Heartbeat, sdauffuellen.sh -e, dopweg.sh -e); 404 von 1156
# Lernlog-Befehlen waeren damit erlaubt gewesen. Zweite Fassung (22.9. nachmittags, nach
# Durchsicht der offenen Kategorien) ergaenzt:
#   - rsync --server --sender auf eine FESTE, exakte Liste von Konfig-/Zugangsdateien und
#     Windows-Freigaben-Ordnern ausserhalb /DATA (RSYNC_ZIELE_AUSSERHALB_DATA unten) - das sind
#     taeglich benoetigte, echte Bestandteile der Sicherung (kopieros() in bugem.sh). OHNE sie
#     wuerde eine Aktivierung die Sicherung BRECHEN.
#   - mariadb-Abfragen NUR als exakter Volltextvergleich gegen mariadb_erlaubte_abfragen.txt
#     (reine SELECT/SHOW-Lesebefehle aus bulinux.sh + eine SET GLOBAL-Zeitlimit-Zeile). Diese
#     Liste muss von Hand nachgezogen werden, wenn Datenbanken hinzukommen/wegfallen (Log:
#     "ABGELEHNT-MARIADB").
#   - findmnt/mountpoint auf den bekannten Windows-Freigaben-Pfaden ausserhalb /DATA (rein lesend,
#     liefert nur ja/nein).
#   - Existenzpruefungen (test/[ ]) und sha256sum auch ausserhalb /DATA, aber NUR fuer dieselben
#     Pfade, deren Inhalt ohnehin schon per rsync freigegeben ist (pfad_lesbar_erlaubt()): wer
#     lesen darf, darf auch wissen, ob es existiert/welchen Hash es hat. sha256sum zusaetzlich
#     fuer die drei Kanarien-Dateinamen (SDLISTE, Ransomware-Fruehwarnung) an den tatsaechlich
#     beobachteten Ablageorten (KANARIEN_ORTE) - reine Hash-Ausgabe, keine Inhaltspreisgabe.
#   Damit waeren rund 790 von 1189 Lernlog-Befehlen erlaubt gewesen (erste Fassung: 404 von 1156).
#   .getmail bleibt auch hier ausgeschlossen, selbst wenn eine Kanarien-Datei ueber den Symlink-Pfad
#   angesprochen wird (loest sonst per readlink -m auf einen erlaubten Ort auf, s. Test dazu).
#
# WEITERHIN BEWUSST NICHT ENTHALTEN:
#   - /root/.getmail/ (als rsync-Sender-Ziel explizit ausgeschlossen, auch wenn es unter /root/
#     liegt): die Einschraenkung auf *rc/oldmail-* passiert erst durch clientseitige rsync-Filter,
#     die im Protokoll uebertragen werden und in $SSH_ORIGINAL_COMMAND NICHT sichtbar sind - ein
#     Wrapper kann sie nicht erzwingen, nur den Pfad selbst. Empfehlung (noch nicht umgesetzt):
#     /root/.getmail als echtes Verzeichnis mit nur den noetigen Dateien anlegen statt als
#     Symlink auf "." - dann waere auch dieser Pfad ungefaehrlich freigebbar.
#   - /usr/libexec/ssh/sftp-server: das ist SCHREIBENDER Dateizugriff (scp kann jede Datei
#     anlegen/ueberschreiben, die root schreiben darf) - keine Automatik-Funktion, sondern von
#     der Schwesterinstanz fuer Notizen/Dateien genutzt. Empfehlung: nicht in den Automatik-
#     Wrapper aufnehmen, sondern nur ueber einen SEPARATEN, bewusst weniger strengen
#     "Mitarbeit-Schluessel" erlauben (s. Bericht an Gerald, 22.9.).
#   - alles Interaktive/Administrative der Schwesterinstanz (crontab -l/-, cd, sed -i, cp -a,
#     bash -s, cat >.../neuserver/*, git, ls -la, chmod, restorecon, snapper, journalctl, ...):
#     das ist die Grundsatzfrage "darf linux0 schreibend auf linux1 arbeiten" - selbe Empfehlung
#     wie bei sftp-server: separater Schluessel fuer die beaufsichtigte Mitarbeit, NICHT der
#     unbeaufsichtigte Automatik-Schluessel, der bei diesem Wrapper bleibt.
#
# Testschema: teste_wrapper_streng.sh (Attrappen wie bei backup_ssh_wrapper.sh).

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

# feste, ausserhalb /DATA bzw. /var/lib/bustate zusaetzlich erlaubte rsync-Sender-Ziele
# (kopieros() in bugem.sh - einzelne Konfig-/Zugangsdateien und Windows-Freigaben-Ordner, die
# taeglich Bestandteil der Sicherung sind). EXAKTER Pfad (kein Praefix), Reihenfolge egal.
# /root/.getmail/ bleibt bewusst ausgeschlossen (s. Kopfkommentar).
RSYNC_ZIELE_AUSSERHALB_DATA="
/root/.mysqlrpwd
/root/.7zpassw
/root/.modbpwd
/root/.mysqlpwd
/root/.fbcredentials
/root/.sturm
/root/.wser
/root/dbverbfreigabe
/root/.vim
/root/bin/
/root/crontabakt
/etc/postfix/main.cf
/etc/postfix/master.cf
/etc/postfix/sasl_passwd
/etc/sysconfig/postfix
/mnt/wser/indamed/
/mnt/wser/indamed/dat/files/
/mnt/wser/indamed/dat/medoffDB/
/mnt/wser/mosich/my.ini
/srv/www/htdocs/behand/
/srv/www/htdocs/fachliches/
/srv/www/htdocs/fertig/
/srv/www/htdocs/php/
/srv/www/htdocs/plz/
/srv/www/htdocs/vorb/
/home/schade/.wincredentials
"
# pfad_lesbar_erlaubt() - wie unter_data_oder_bustate(), zusaetzlich die Liste oben. Fuer ALLES,
# was nur eine Existenz-/Hash-Aussage ueber einen Pfad liefert (test/[ ]/sha256sum) oder den
# Pfad per rsync --sender liest: wer den Inhalt lesen darf, darf auch wissen, ob er existiert.
# NICHT fuer mkdir/stat-mtime/find (bleibt bewusst auf /DATA und /var/lib/bustate beschraenkt,
# s. unter_data_oder_bustate() - dafuer gibt es ausserhalb keinen bekannten, noetigen Anwendungsfall).
pfad_lesbar_erlaubt() {
  local p="$1" aufgeloest z
  unter_data_oder_bustate "$p" && return 0
  aufgeloest=$(readlink -m -- "$p" 2>/dev/null)
  case "$aufgeloest" in
    /root/.getmail|/root/.getmail/*) return 1;;  # s. Kopfkommentar: Filter nicht per Wrapper erzwingbar
  esac
  # readlink -m liefert nie einen abschliessenden Slash - Vergleichsliste ebenso normalisieren,
  # auch wenn sie dort (als Verzeichnis-Kennzeichnung fuer Menschen) mit "/" eingetragen ist.
  for z in $RSYNC_ZIELE_AUSSERHALB_DATA; do [ "$aufgeloest" = "${z%/}" ] && return 0; done
  [[ "$aufgeloest" =~ ^/mnt/wser/mosich/[0-9]{14}/?$ ]] && return 0   # taeglicher MOSICH-Datumsordner
  return 1
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
      if ! pfad_lesbar_erlaubt "$rs_t"; then
        case "$(readlink -m -- "$rs_t" 2>/dev/null)" in
          /root/.getmail|/root/.getmail/*) log "ABGELEHNT-RSYNC-GETMAIL: $CMD";;
          *) log "ABGELEHNT-RSYNC-ZIEL: $CMD";;
        esac
        exit 1
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
  "/root/bin/sdauffuellen.sh -e"|"/root/bin/dopweg.sh -e"|"echo "|"mountpoint -q /DATA 2>/dev/null"|"mountpoint -q /DATA||mount /DATA"|"mountpoint -q /mnt/anmmw")
    log "OK-FEST: $CMD"
    exec bash -c "$CMD"
    ;;
esac

# --- 2b) findmnt auf den bekannten Windows-Freigaben-Pfaden (Mount-Pruefung vor dem Kopieren,
# bugem.sh kopiermt()) - fester Pfad, /mnt/wser/mosich/<Datumsordner> als Muster (14 Ziffern).
FINDMNT_PFADE="
/mnt/wser/indamed
/mnt/wser/indamed/dat
/mnt/wser/indamed/dat/files
/mnt/wser/indamed/dat/medoffDB
/mnt/wser/mosich
/mnt/wser/mosich/my.ini
"
if [[ "$CMD" =~ ^findmnt\ \"(.+)\"\ -n\ \>/dev/null$ ]]; then
  pfad="${BASH_REMATCH[1]}"; gefunden=
  for z in $FINDMNT_PFADE; do [ "$pfad" = "$z" ] && gefunden=1; done
  [[ "$pfad" =~ ^/mnt/wser/mosich/[0-9]{14}$ ]] && gefunden=1
  if [ -n "$gefunden" ]; then log "OK-FINDMNT: $CMD"; exec findmnt "$pfad" -n >/dev/null; fi
  log "ABGELEHNT-FINDMNT: $CMD"; exit 1
fi

# --- 2c) mariadb-Abfragen: NUR exakte, vorab geprueft-gleiche Zeilen aus
# mariadb_erlaubte_abfragen.txt (s. dort - reine SELECT/SHOW-Lesebefehle + eine SET GLOBAL-
# Zeitlimit-Zeile, alle aus bulinux.sh). Volltextvergleich, keine erneute Auswertung von $CMD
# als Muster - ein Treffer bedeutet byteidentisch mit einer vorab von Hand geprueften Zeile.
MARIADB_LISTE=/root/neuserver/mariadb_erlaubte_abfragen.txt
case "$CMD" in
  "mariadb --defaults-extra-file=/root/.mysqlrpwd "*)
    if [ -f "$MARIADB_LISTE" ] && grep -qxF -- "$CMD" "$MARIADB_LISTE" 2>/dev/null; then
      log "OK-MARIADB: $CMD"
      exec bash -c "$CMD"
    else
      log "ABGELEHNT-MARIADB: $CMD"; exit 1
    fi
    ;;
esac

# --- 3) Befehlsmuster mit eingebettetem Pfad (nur /DATA bzw. /var/lib/bustate) ------------------
if [[ "$CMD" =~ ^test\ -([edf])\ \"(.+)\"$ ]]; then
  flag="${BASH_REMATCH[1]}"; pfad="${BASH_REMATCH[2]}"
  pfad_lesbar_erlaubt "$pfad" && { log "OK-TEST-$flag: $CMD"; test "-$flag" "$pfad"; exit $?; }

elif [[ "$CMD" =~ ^\[\ -([edf])\ \"(.+)\"\ \]$ ]]; then
  # gleichwertig zu "test -X", nur Klammersyntax (kopieros()-Einzeldatei-Vorpruefung in bugem.sh)
  flag="${BASH_REMATCH[1]}"; pfad="${BASH_REMATCH[2]}"
  pfad_lesbar_erlaubt "$pfad" && { log "OK-BRACKET-$flag: $CMD"; test "-$flag" "$pfad"; exit $?; }

elif [[ "$CMD" =~ ^test\ -([ef])\ (/root/[^\ \"]+)$ ]]; then
  # unquotiert, kein "/", kein Leerzeichen im Namen (kopieros(): "test -f /root/$1", bugem.sh Zeile ~677/679)
  flag="${BASH_REMATCH[1]}"; pfad="${BASH_REMATCH[2]}"
  pfad_lesbar_erlaubt "$pfad" && { log "OK-TEST-ROOT-$flag: $CMD"; test "-$flag" "$pfad"; exit $?; }

elif [[ "$CMD" =~ ^sha256sum\ \"(.+)\"\ 2\>/dev/null$ ]] || [[ "$CMD" =~ ^sha256sum\ (/root/[^\ \"]+)\ 2\>/dev/null$ ]]; then
  pfad="${BASH_REMATCH[1]}"
  # Kanarienvogel-Vergleich (SDLISTE in bugem.sh, Ransomware-Fruehwarnung): reine Hash-Ausgabe,
  # keine Inhaltspreisgabe. Zusaetzlich zu pfad_lesbar_erlaubt() an den tatsaechlich beobachteten
  # Ablageorten erlaubt (Ordner exakt, nicht als Praefix - neue Orte erst nach Pruefung ergaenzen).
  KANARIEN_ORTE="
/root
/srv/www/htdocs/fachliches
/mnt/wser/indamed/dat/medoffDB
/mnt/wser/indamed/dat/files
"
  case "$pfad" in */.getmail/*|*/.getmail) pfad="";; esac  # s. Kopfkommentar: .getmail nie als Eingabepfad akzeptieren, auch nicht hier
  case "${pfad##*/}" in
    "Schutzdatei_bitte_belassen.doc"|"Auch_eine_Schutzdatei_bitte_belassen.jpg"|"zusätzliche_Schutzdatei_bitte_belassen.pdf")
      _ko_dir=$(dirname -- "$(readlink -m -- "$pfad" 2>/dev/null)")
      for _ko_z in $KANARIEN_ORTE; do
        if [ "$_ko_dir" = "$_ko_z" ]; then log "OK-SHA256-KANARIE: $CMD"; exec sha256sum -- "$pfad" 2>/dev/null; fi
      done
      ;;
  esac
  pfad_lesbar_erlaubt "$pfad" && { log "OK-SHA256: $CMD"; exec sha256sum -- "$pfad" 2>/dev/null; }

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
