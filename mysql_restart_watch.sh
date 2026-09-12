#!/bin/bash
# Wartet auf Trigger-Datei-Schreibvorgaenge (von anzeig.php/tragein2.php/ianzeig.php
# per file_put_contents ausgeloest, wenn die MariaDB-Verbindung fehlschlaegt) und
# startet dann den mysql(mariadb)-Dienst. Laeuft als systemd-Dienst (root, NICHT
# unter der httpd_t-SELinux-Domain), da PHP/wwwrun unter enforcendem SELinux weder
# sudo noch eine Shell ausfuehren darf (verifiziert 2026-09-12: "entrypoint"-Denials
# fuer shell_exec_t UND sudo_exec_t - betraf urspruenglich
# shell_exec('sudo systemctl start mysql') in allen drei Dateien, siehe
# /DATA/down/linux1_testlauf_befunde.txt).
TRIGGERDIR=/var/lib/mo-mysql-restart
mkdir -p "$TRIGGERDIR"
inotifywait -m -e close_write,create --format '%f' "$TRIGGERDIR" | while read -r _f; do
  systemctl start mysql
done
