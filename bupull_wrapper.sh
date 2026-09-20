#!/bin/bash
# bupull_wrapper.sh - Forced-Command fuer die Schluessel der Reserver (linux0/linux7) auf linux1.
# LERNMODUS: protokolliert jeden Befehl nach /var/log/backup_pull_wrapper.log und fuehrt ihn
# UNVERAENDERT aus (genau wie sshd es mit der Login-Shell taete). Zweck: die tatsaechlich von
# den Reservern benoetigten Befehle sammeln, um daraus eine Erlaubnisliste (wie
# backup_ssh_wrapper.sh) abzuleiten. Auswertung: bupull_lernen.sh
# Eingetragen als command="/root/bin/bupull_wrapper.sh" vor dem Schluessel in authorized_keys.
LOG=/var/log/backup_pull_wrapper.log
CMD="$SSH_ORIGINAL_COMMAND"
QUELLE="${SSH_CONNECTION%% *}"
printf '%s [%s] %s\n' "$(date '+%F %T')" "$QUELLE" "${CMD:-<interaktive Sitzung>}" >>"$LOG" 2>/dev/null
SH="${SHELL:-/bin/bash}"
if [ -z "$CMD" ]; then exec -a "-${SH##*/}" "$SH"; fi
exec "$SH" -c "$CMD"
