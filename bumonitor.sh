#!/bin/bash
# bumonitor.sh - Warnmail, wenn die Sicherungen auf linux0/linux7 nicht richtig gelaufen sind.
#
# Auswertung der Heartbeat-Dateien /DATA/Backup-Status_<Rechner>.txt auf linux1. Die Reserver
# schreiben dort nach jedem ECHTEN Lauf von bumo.sh/bulinux.sh/bunacht.sh eine Zeile
#   <Skript>  <Datum> <Uhrzeit>  OK|FEHLER          (bugem.sh: backupstatus())
# Gemeldet wird: Statusdatei/Zeile fehlt, Status FEHLER, oder letzter Lauf zu alt.
#
# Aufruf:  bumonitor.sh [voll|mittag] [-n] [-t]
#   voll     (Vorgabe) alle drei Skripte pruefen; per cron morgens nach den Nachtfenstern
#   mittag   nur bumo.sh, mit engem Zeitfenster; per cron nachmittags nach den Mittagsfenstern
#   -n       nur anzeigen, nichts mailen, Zustand nicht veraendern
#   -t       Testmail (immer senden, Betreff mit TEST)
# Mailfrequenz: nur wenn sich die Problemliste aendert oder seit der letzten Mail > 24 h vergangen
# sind; bei Wegfall aller Probleme eine "Entwarnung". Laeuft nur auf linux1.
EMPFAENGER="diabetologie@dachau-mail.de"
RESERVER="linux0 linux7"
STATUSDIR=/DATA
ZUSTAND=/var/lib/bumonitor
MODUS=voll; NUR_ANZEIGEN=; TESTMAIL=
for a in "$@"; do case "$a" in voll|mittag) MODUS=$a;; -n) NUR_ANZEIGEN=1;; -t) TESTMAIL=1;; *) sed -n '2,17p' "$0"; exit 1;; esac; done
h=$(hostname); [ "${h%%.*}" = linux1 ] || { echo "bumonitor.sh laeuft nur auf linux1"; exit 0; }
# erlaubtes Alter in Stunden je Skript
if [ "$MODUS" = mittag ]; then SKRIPTE="bumo.sh"; declare -A MAXH=([bumo.sh]=3)
else SKRIPTE="bumo.sh bulinux.sh bunacht.sh"; declare -A MAXH=([bumo.sh]=26 [bulinux.sh]=30 [bunacht.sh]=30); fi
JETZT=$(date +%s); PROBLEME=""
add() { PROBLEME="${PROBLEME}${1}"$'\n'; }
alter_text() { # Sekunden -> "6,5 Stunden" / "10,0 Tage"
  awk -v s="$1" 'BEGIN{ if (s>=172800) printf "%.1f Tagen", s/86400; else printf "%.1f Stunden", s/3600 }' | sed 's/\./,/'; }
for r in $RESERVER; do
  f="$STATUSDIR/Backup-Status_$r.txt"
  if [ ! -s "$f" ]; then add "$r: Statusdatei $f fehlt oder ist leer (noch nie gesichert?)"; continue; fi
  for s in $SKRIPTE; do
    zeile=$(grep -E "^$s[[:space:]]" "$f" | tail -1)
    if [ -z "$zeile" ]; then add "$r: $s hat keinen Eintrag (nicht gelaufen?)"; continue; fi
    d=$(echo "$zeile" | awk '{print $2" "$3}'); st=$(echo "$zeile" | awk '{print $4}')
    ts=$(date -d "$d" +%s 2>/dev/null) || { add "$r: $s Zeitstempel unlesbar: $zeile"; continue; }
    al=$((JETZT-ts)); dd=$(date -d "@$ts" '+%d.%m.%Y %H:%M')
    if [ "$st" != OK ]; then add "$r: $s endete mit $st (Lauf vom $dd, vor $(alter_text $al))"
    elif [ "$al" -gt $(( ${MAXH[$s]} * 3600 )) ]; then add "$r: $s veraltet - letzter OK-Lauf am $dd (vor $(alter_text $al), erlaubt ${MAXH[$s]} Stunden)"
    fi
  done
done
sig=$(printf '%s' "$PROBLEME" | sha256sum | cut -c1-16)
SF="$ZUSTAND/zustand_$MODUS"; letzte_sig=; letzte_zeit=0
[ -f "$SF" ] && { read -r letzte_sig letzte_zeit < "$SF"; }
mailen() { printf '%s\n' "$2" | mail -s "$1" "$EMPFAENGER"; }
kopf="Sicherungspruefung auf $h, $(date '+%d.%m.%Y %H:%M'), Modus: $MODUS"
if [ -n "$PROBLEME" ]; then
  text="Achtung,"$'\n\n'"die Sicherungen auf den Reserverechnern sind nicht richtig gelaufen:"$'\n\n'"$PROBLEME"$'\n'"Naeheres: /DATA/Backup-Status_<Rechner>.txt auf linux1, /var/log/wecklauf.log auf dem jeweiligen Reserver."$'\n'"($kopf)"
  echo "$kopf: PROBLEME"; printf '%s' "$PROBLEME"
  if [ -n "$TESTMAIL" ]; then [ -n "$NUR_ANZEIGEN" ] || mailen "TEST Sicherungswarnung linux1 - Probleme (Testmail)" "$text"
  elif [ -z "$NUR_ANZEIGEN" ] && { [ "$sig" != "$letzte_sig" ] || [ $((JETZT-${letzte_zeit:-0})) -gt 86400 ]; }; then
    mailen "WARNUNG Sicherung: $(printf '%s' "$PROBLEME" | grep -c .) Problem(e) auf linux0/linux7" "$text"
    mkdir -p "$ZUSTAND"; echo "$sig $JETZT" > "$SF"; echo "Warnmail gesendet an $EMPFAENGER"
  elif [ -n "$NUR_ANZEIGEN" ]; then echo "(Anzeigemodus: keine Mail, Zustand unveraendert)"
  else echo "keine neue Mail (unveraendert seit letzter Meldung)"; fi
else
  echo "$kopf: alles in Ordnung"
  if [ -n "$TESTMAIL" ]; then [ -n "$NUR_ANZEIGEN" ] || mailen "TEST Sicherungswarnung linux1 - alles in Ordnung (Testmail)" "Die Sicherungspruefung auf $h meldet keine Probleme. ($kopf)"
  elif [ -z "$NUR_ANZEIGEN" ] && [ -n "$letzte_sig" ] && [ "$letzte_sig" != "$(printf '' | sha256sum | cut -c1-16)" ]; then
    mailen "Entwarnung Sicherung linux0/linux7" "Die zuvor gemeldeten Sicherungsprobleme sind behoben, alle geprueften Laeufe sind OK."$'\n'"($kopf)"
    mkdir -p "$ZUSTAND"; echo "$(printf '' | sha256sum | cut -c1-16) $JETZT" > "$SF"; echo "Entwarnung gesendet"
  fi
fi
exit 0
