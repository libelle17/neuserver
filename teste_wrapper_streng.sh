#!/bin/bash
# Testet bupull_wrapper_streng.sh gegen reale Lernlog-Befehle (sollen ERLAUBT werden)
# und gegen Angriffs-/Randfall-Varianten (sollen ABGELEHNT werden).
# Sicherheitsmassnahmen gegen echte Seiteneffekte auf dem Produktivsystem:
#   - alle "exec ..."-Aufrufe im Original werden durch "echo WUERDE-LAUFEN: ..." ersetzt
#   - mkdir/touch/mv werden zusaetzlich als no-op-Funktionen ueberdeckt (die einzigen
#     schreibenden Aufrufe ausserhalb von "exec", in den mkdir+touch- und Heartbeat-Zweigen)
#   - das Log schreibt in eine temporaere Datei statt /var/log/...
set -u
W=/root/neuserver/bupull_wrapper_streng.sh
TESTROOT=$(mktemp -d)
trap 'rm -rf "$TESTROOT"' EXIT

WTEST="$TESTROOT/wrapper_test.sh"
cp "$W" "$WTEST"
LOGDATEI="$TESTROOT/log.txt"
sed -i "s#/var/log/backup_pull_wrapper_streng.log#$LOGDATEI#" "$WTEST"
chmod +x "$WTEST"

# "exec" selbst als Funktion ueberdecken (bash erlaubt das, s. Test) statt Zeilen per sed zu
# ersetzen - erfasst JEDEN exec-Aufruf, auch mitten in "if ...; then ...; exec ...; fi" oder
# "... && { ...; exec ...; }", nicht nur Zeilen, die mit "exec " beginnen.
exec()  { echo "WUERDE-LAUFEN(exec): $*"; exit 0; }  # exit, nicht return: die echte exec-Builtin kehrt auch nie zurueck
mkdir() { echo "WUERDE-LAUFEN: mkdir $*"; return 0; }
touch() { echo "WUERDE-LAUFEN: touch $*"; return 0; }
mv()    { echo "WUERDE-LAUFEN: mv $*"; return 0; }
export -f exec mkdir touch mv

pass=0; fail=0
lauf() {
  local besch="$1" quelle="$2" erwartet="$3" cmd="$4"
  local out rc ok=0
  out=$(SSH_ORIGINAL_COMMAND="$cmd" SSH_CONNECTION="$quelle 12345 192.168.178.21 22" "$WTEST" 2>&1)
  rc=$?
  if [ "$erwartet" = 0 ]; then [ "$rc" = 0 ] && ok=1; else [ "$rc" != 0 ] && ok=1; fi
  if [ "$ok" = 1 ]; then
    pass=$((pass+1)); printf "OK   %-48s rc=%s\n" "$besch" "$rc"
  else
    fail=$((fail+1)); printf "FAIL %-48s rc=%s erwartet=%s\n     Befehl: %s\n     Ausgabe: %s\n" "$besch" "$rc" "$erwartet" "$cmd" "$out"
  fi
}

echo "=== A) reale Lernlog-Befehle (muessen ERLAUBT werden, rc=0) ==="
lauf "sdauffuellen.sh -e"          192.168.178.20 0 '/root/bin/sdauffuellen.sh -e'
lauf "dopweg.sh -e"                192.168.178.27 0 '/root/bin/dopweg.sh -e'
lauf "echo-ping"                   192.168.178.20 0 'echo '
lauf "mountpoint /DATA"            192.168.178.20 0 'mountpoint -q /DATA||mount /DATA'
lauf "test -e DATA"                192.168.178.20 0 'test -e "/DATA/Patientendokumente"'
lauf "test -d DATA"                192.168.178.20 0 'test -d "/DATA/Patientendokumente"'
lauf "test-f-stat-oder-du (Leerz)" 192.168.178.20 0 'test -f "/DATA/eigene\ Dateien"&&{ stat /DATA/eigene\ Dateien -c %s||echo 0;:;}||du /DATA/eigene\ Dateien -d0;'
lauf "stat -c %Y bustate"          192.168.178.20 0 'stat -c %Y "/var/lib/bustate/bu_lokal.ts" 2>/dev/null'
lauf "mkdir+touch bustate"         192.168.178.20 0 'mkdir -p "/var/lib/bustate" && { [ -f "/var/lib/bustate/bu_lokal.ts" ] || touch -t 197001010000 "/var/lib/bustate/bu_lokal.ts"; }'
lauf "find -newer"                 192.168.178.20 0 'find "/DATA/Patientendokumente" -newer "/var/lib/bustate/bu_lokal.ts" \( -type f -o -type l \) -print 2>/dev/null'
lauf "stat-oder-du sql"            192.168.178.20 0 'test -f "/DATA/sql"&&{ stat /DATA/sql -c %s||echo 0;:;}||du /DATA/sql -d0;'
lauf "testd-du Papierkorb"         192.168.178.20 0 'test -d "/DATA/sql/Papierkorb/" && du /DATA/sql/Papierkorb/ -d0'
lauf "heartbeat bumo linux7"       192.168.178.27 0 'mkdir -p /DATA 2>/dev/null; touch "/DATA/Backup-Status_linux7.txt" 2>/dev/null; { grep -v "^bumo.sh " "/DATA/Backup-Status_linux7.txt" 2>/dev/null; echo "bumo.sh      2026-09-21 14:45:33  OK"; } | sort -o "/DATA/Backup-Status_linux7.txt.neu" -; mv "/DATA/Backup-Status_linux7.txt.neu" "/DATA/Backup-Status_linux7.txt"'
lauf "heartbeat platz linux7"      192.168.178.27 0 'mkdir -p /DATA 2>/dev/null; touch "/DATA/Backup-Status_linux7.txt" 2>/dev/null; { grep -v "^platz " "/DATA/Backup-Status_linux7.txt" 2>/dev/null; echo "platz        2026-09-21 23:55:41  frei=42% 3917GB/9216GB"; } | sort -o "/DATA/Backup-Status_linux7.txt.neu" -; mv "/DATA/Backup-Status_linux7.txt.neu" "/DATA/Backup-Status_linux7.txt"'
lauf "rsync sender DATA/sql"       192.168.178.20 0 'rsync --server --sender -vulogDtpre.iLsfxCIvu . /DATA/sql/'
lauf "rsync sender DATA/Mail inplace" 192.168.178.20 0 'ionice -c2 nice -n10 rsync --server --sender -vulogDtpXre.iLsfxCIvu --inplace . /DATA/Mail/'
lauf "rsync sender DATA (Wurzel)"  192.168.178.20 0 'ionice -c2 nice -n10 rsync --server --sender -vulogDtpXre.iLsfxCIvu . /DATA/'
lauf "rsync sender files-from/from0" 192.168.178.27 0 'ionice -c2 nice -n10 rsync --server --sender -vlogDtpXRe.LsfxCIvu --files-from=- --from0 . /DATA/Patientendokumente//'

echo
echo "=== A2) neu freigegebene Kategorien (muessen ERLAUBT werden, rc=0) ==="
lauf "rsync sender /root/.mysqlrpwd"                 192.168.178.20 0 'rsync --server --sender -vulDtpXre.iLsfxCIvu . /root/.mysqlrpwd'
lauf "rsync sender /root/bin/ (rekursiv)"            192.168.178.20 0 'ionice -c2 nice -n10 rsync --server --sender -vulogDtpre.LsfxCIvu . /root/bin/'
lauf "rsync sender /etc/postfix/main.cf"             192.168.178.20 0 'ionice -c2 nice -n10 rsync --server --sender -vulogDtpXre.iLsfxCIvu . /etc/postfix/main.cf'
lauf "rsync sender /home/schade/.wincredentials"     192.168.178.20 0 'ionice -c2 nice -n10 rsync --server --sender -vulogDtpXre.iLsfxCIvu . /home/schade/.wincredentials'
lauf "rsync sender /mnt/wser/mosich/Datumsordner"    192.168.178.20 0 'ionice -c2 nice -n10 rsync --server --sender -vulogDtpre.iLsfxCIvu . /mnt/wser/mosich/20260921200000/'
lauf "mariadb SHOW DATABASES (exakte Zeile)"         192.168.178.20 0 'mariadb --defaults-extra-file=/root/.mysqlrpwd -BN        -e "SHOW DATABASES" 2>/dev/null'
lauf "mariadb SET GLOBAL Timeout (exakte Zeile)"     192.168.178.20 0 'mariadb --defaults-extra-file=/root/.mysqlrpwd           -e "SET GLOBAL net_write_timeout=3600; SET GLOBAL net_read_timeout=3600;"'
lauf "findmnt /mnt/wser/indamed (jetzt erlaubt)"     192.168.178.20 0 'findmnt "/mnt/wser/indamed" -n >/dev/null'
lauf "findmnt /mnt/wser/mosich/Datumsordner"         192.168.178.20 0 'findmnt "/mnt/wser/mosich/20260921200000" -n >/dev/null'
lauf "mountpoint /mnt/anmmw"                         192.168.178.20 0 'mountpoint -q /mnt/anmmw'
lauf "test -f /root/.wser (unquotiert, Vorpruefung)" 192.168.178.20 0 'test -f /root/.wser'
lauf "test -e /root/.mysqlrpwd (unquotiert)"         192.168.178.20 0 'test -e /root/.mysqlrpwd'
lauf "sha256sum Kanarie unter /root"                 192.168.178.20 0 'sha256sum /root/Schutzdatei_bitte_belassen.doc 2>/dev/null'
lauf "sha256sum Kanarie unter /srv (Ort wechselt)"   192.168.178.20 0 'sha256sum "/srv/www/htdocs/fachliches/Schutzdatei_bitte_belassen.doc" 2>/dev/null'
lauf "sha256sum Kanarie mit Sonderzeichen im Namen"  192.168.178.20 0 'sha256sum "/mnt/wser/indamed/dat/files/zusätzliche_Schutzdatei_bitte_belassen.pdf" 2>/dev/null'
lauf "sha256sum auf erlaubtem /etc/postfix-Pfad"     192.168.178.20 0 'sha256sum "/etc/postfix/main.cf" 2>/dev/null'

echo
echo "=== B) weiterhin NICHT freigegebene Muster (muessen ABGELEHNT werden, rc!=0) ==="
lauf "rsync sender /root/.getmail (Symlink-Risiko, bleibt ausgeschlossen)" 192.168.178.20 1 'ionice -c2 nice -n10 rsync --server --sender -vuldDtXe.LsfxCIvu . /root/.getmail/'
lauf "rsync sender /root/.getmail/ mit Endslash-Variante" 192.168.178.20 1 'ionice -c2 nice -n10 rsync --server --sender -vuldDtXe.LsfxCIvu . /root/.getmail'
lauf "rsync sender unbekannter /root-Pfad (nicht auf der Liste)" 192.168.178.20 1 'rsync --server --sender -vulDtpXre.iLsfxCIvu . /root/.ssh/authorized_keys'
lauf "test -f /root/.ssh/authorized_keys (unquotiert, nicht erlaubt)" 192.168.178.20 1 'test -f /root/.ssh/authorized_keys'
lauf "sha256sum /etc/shadow (kein Kanariename, kein erlaubter Pfad)" 192.168.178.20 1 'sha256sum "/etc/shadow" 2>/dev/null'
lauf "sha256sum Kanariename an nicht erlaubtem Ort"  192.168.178.20 1 'sha256sum "/root/.ssh/Schutzdatei_bitte_belassen.doc" 2>/dev/null'
lauf "sha256sum Kanarie ueber .getmail-Symlink (bleibt ausgeschlossen)" 192.168.178.20 1 'sha256sum "/root/.getmail/Schutzdatei_bitte_belassen.doc" 2>/dev/null'
lauf "mariadb: Abfrage NICHT auf der Liste (neue DB)" 192.168.178.20 1 'mariadb --defaults-extra-file=/root/.mysqlrpwd -BN -e "SHOW TABLES FROM geheim" 2>/dev/null'
lauf "mariadb: bekannte Zeile mit angehaengtem Befehl" 192.168.178.20 1 'mariadb --defaults-extra-file=/root/.mysqlrpwd -BN        -e "SHOW DATABASES" 2>/dev/null; cat /etc/shadow'
lauf "findmnt auf nicht gelistetem Pfad"             192.168.178.20 1 'findmnt "/mnt/anderefreigabe" -n >/dev/null'
lauf "sftp-server (bewusst nicht freigegeben)"       192.168.178.20 1 '/usr/libexec/ssh/sftp-server'
lauf "crontab -l"                  192.168.178.20 1 'crontab -l'
lauf "interaktive Sitzung (leer)"  192.168.178.20 1 ''

echo
echo "=== C) Angriffsvarianten (muessen ABGELEHNT werden, rc!=0) ==="
lauf "Injektion via Semikolon in Pfad"        192.168.178.20 1 'test -e "/DATA/x; rm -rf /"'
lauf "Injektion via Backticks"                192.168.178.20 1 'test -e "/DATA/$(cat /etc/shadow)"'
lauf "Pfad ausserhalb DATA (..)"              192.168.178.20 1 'test -e "/DATA/../etc/shadow"'
lauf "cat /etc/shadow direkt"                 192.168.178.20 1 'cat /etc/shadow'
lauf "interaktive Shell erzwingen"            192.168.178.20 1 'bash -i'
lauf "rsync sender ohne --sender (Schreiben!)" 192.168.178.20 1 'rsync --server -vulogDtpre.iLsfxCIvu . /DATA/sql/'
lauf "rsync sender mit -e (Remote-Shell-Option)" 192.168.178.20 1 'rsync --server --sender -e/bin/sh -vulogDtpre.iLsfxCIvu . /DATA/sql/'
lauf "rsync sender Pfad ausserhalb via .."    192.168.178.20 1 'rsync --server --sender -vulogDtpre.iLsfxCIvu . /DATA/../etc/'
lauf "rsync sender Metazeichen im Pfad"       192.168.178.20 1 'rsync --server --sender -vulogDtpre.iLsfxCIvu . "/DATA/x;id"'
lauf "rsync sender zwei Zielpfade (DATA+root)" 192.168.178.20 1 'rsync --server --sender -vulogDtpre.iLsfxCIvu . /DATA/ /root/'
lauf "gefaelschte Quelladresse (nicht .20/.27)" 192.168.178.99 1 '/root/bin/sdauffuellen.sh -e'
lauf "heartbeat: linux0 meldet fuer linux7"   192.168.178.20 1 'mkdir -p /DATA 2>/dev/null; touch "/DATA/Backup-Status_linux7.txt" 2>/dev/null; { grep -v "^bumo.sh " "/DATA/Backup-Status_linux7.txt" 2>/dev/null; echo "bumo.sh      2026-09-21 14:45:33  OK"; } | sort -o "/DATA/Backup-Status_linux7.txt.neu" -; mv "/DATA/Backup-Status_linux7.txt.neu" "/DATA/Backup-Status_linux7.txt"'
lauf "heartbeat mit falschem Pseudo-Skriptnamen" 192.168.178.20 1 'mkdir -p /DATA 2>/dev/null; touch "/DATA/Backup-Status_linux0.txt" 2>/dev/null; { grep -v "^boesewicht.sh " "/DATA/Backup-Status_linux0.txt" 2>/dev/null; echo "boesewicht.sh 2026-09-21 14:45:33  OK"; } | sort -o "/DATA/Backup-Status_linux0.txt.neu" -; mv "/DATA/Backup-Status_linux0.txt.neu" "/DATA/Backup-Status_linux0.txt"'
lauf "heartbeat Status mit Befehlseinschleusung" 192.168.178.20 1 'mkdir -p /DATA 2>/dev/null; touch "/DATA/Backup-Status_linux0.txt" 2>/dev/null; { grep -v "^bumo.sh " "/DATA/Backup-Status_linux0.txt" 2>/dev/null; echo "bumo.sh      2026-09-21 14:45:33  $(id)"; } | sort -o "/DATA/Backup-Status_linux0.txt.neu" -; mv "/DATA/Backup-Status_linux0.txt.neu" "/DATA/Backup-Status_linux0.txt"'
lauf "heartbeat grep/echo-Skriptname inkonsistent" 192.168.178.20 1 'mkdir -p /DATA 2>/dev/null; touch "/DATA/Backup-Status_linux0.txt" 2>/dev/null; { grep -v "^bumo.sh " "/DATA/Backup-Status_linux0.txt" 2>/dev/null; echo "bunacht.sh   2026-09-21 14:45:33  OK"; } | sort -o "/DATA/Backup-Status_linux0.txt.neu" -; mv "/DATA/Backup-Status_linux0.txt.neu" "/DATA/Backup-Status_linux0.txt"'

echo
echo "=== Ergebnis: $pass bestanden, $fail fehlgeschlagen ==="
[ "$fail" = 0 ]
