#!/bin/bash
# nachholen.sh - versaeumte Sicherungen auf linux0/linux7 einmal ausser der
# Reihe nachholen (Ablauf wie wecklauf.sh Modus "nacht": sdauffuellen.sh auf
# linux1, bumo.sh, bulinux.sh -f, bunacht.sh), danach den naechsten regulaeren
# Weckalarm setzen und den Rechner ABSCHALTEN. Erstmals 30.09.2026 nach dem
# Shutdown-Haenger von linux0 (27.-30.09.2026).
#
# Aufruf (laeuft unabhaengig von der ssh-Sitzung weiter):
#   systemd-run --unit=sicherung-nachholen --collect /root/bin/nachholen.sh
# Nicht starten, wenn gerade jemand an dem Rechner arbeitet (schaltet am Ende ab)!
#
# Waehrenddessen existiert /root/.kein_wecklauf, damit wecklauf.sh in einem
# Weckfenster nicht parallel loslaeuft; wird am Ende wieder entfernt.
# Weckzeiten muessen zu wecklauf.sh passen.

LOG=/var/log/wecklauf.log;
GRACE=/root/.kein_wecklauf;
HOST=$(hostname); HOST=${HOST%%.*};
case "$HOST" in
  linux0) MITTAG="14:18"; NACHT="21:45";;
  linux7) MITTAG="14:48"; NACHT="00:00";;
  *) echo "nachholen.sh: nur fuer linux0/linux7 gedacht, nicht fuer $HOST" >&2; exit 1;;
esac;
log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG"; }
lauf() { log "Starte (Nachholen) $* -e"; timeout 8h "$@" -e 2>&1 | tee -a "$LOG"; log "Ende (Nachholen) $1 (Exitcode: ${PIPESTATUS[0]})"; }

touch "$GRACE"; # wecklauf.sh soll waehrenddessen nicht parallel loslaufen
log "Nachholen der versaeumten Sicherungen auf $HOST beginnt";
ssh linux1 '/root/bin/sdauffuellen.sh -e' 2>&1 | tee -a "$LOG";
systemd-inhibit --what=shutdown:sleep --who=nachholen --why="Nachholen der Sicherungen" --mode=delay bash -c '
  '"$(declare -f log lauf)"'; LOG='"$LOG"';
  lauf /root/bin/bumo.sh;
  lauf /root/bin/bulinux.sh -f;
  lauf /root/bin/bunacht.sh;
';
rm -f "$GRACE";

# naechsten regulaeren Weckzeitpunkt mind. 15 Min. in der Zukunft
jetzt=$(date +%s); ziel=;
for t in "today $MITTAG" "today $NACHT" "tomorrow $MITTAG" "tomorrow $NACHT"; do
  e=$(date -d "$t" +%s); [ $e -gt $((jetzt + 900)) ] && { [ -z "$ziel" ] || [ $e -lt $ziel ]; } && ziel=$e;
done;
log "Nachholen fertig, naechster Alarm $(date -d @$ziel '+%Y-%m-%d %H:%M')";
rtcwake -m no -t "$ziel" 2>&1 | tee -a "$LOG";
log "Schalte $HOST nach dem Nachholen ab.";
shutdown -h now;
