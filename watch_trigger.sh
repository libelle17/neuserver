#!/bin/bash
# Wartet auf Trigger-Datei-Schreibvorgaenge (von emailspei.php per file_put_contents
# ausgeloest, siehe [[project-missing-patient-emails]]) und stoesst dann
# linux1_commit_medoff.py --apply an. Laeuft als systemd-Dienst (root, NICHT unter
# der httpd_t-SELinux-Domain - siehe mo-emailadr-commit-watch.service), da PHP/wwwrun
# unter enforcendem SELinux weder sudo noch eine Shell/sudo-Kette ausfuehren darf
# (verifiziert 2026-09-12: "entrypoint"-Denials fuer shell_exec_t UND sudo_exec_t).
# PHP darf aber problemlos in das eigens dafuer angelegte, als httpd_var_lib_t
# beschriftete Verzeichnis /var/lib/mo-emailadr schreiben (siehe sesearch-Policy).
TRIGGERDIR=/var/lib/mo-emailadr
mkdir -p "$TRIGGERDIR"
inotifywait -m -e close_write,create --format '%f' "$TRIGGERDIR" | while read -r _f; do
  /usr/bin/python3 /opt/mo-emailadr/linux1_commit_medoff.py --apply
done
