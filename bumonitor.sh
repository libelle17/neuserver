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
# Zusaetzlich (nur Modus voll): freier Platz auf /DATA der Reserver. Quelle 1: die Zeile "platz" im Heartbeat, die
# bugem.sh (platzstatus) nach jedem Lauf schreibt; Quelle 2 (Vorrang, wenn der Reserver gerade laeuft): live
# "df /DATA" ueber den eingeschraenkten Backup-Schluessel (der Wrapper erlaubt "df /pfad"). Warnung unter
# BU_MIN_FREI_PROZENT (Vorgabe 10 %), "KRITISCH" unter BU_KRIT_FREI_PROZENT (Vorgabe 3 %). Ist der Reserver aus und
# die Platzmeldung aelter als 3 Tage, wird nur vermerkt (kein Alarm). Testhilfen: BUMON_STATUSDIR, BUMON_ZUSTAND, BUMON_SSH.
# Mailfrequenz: nur wenn sich die Problemliste aendert oder seit der letzten Mail > 24 h vergangen
# sind; bei Wegfall aller Probleme eine "Entwarnung". Laeuft nur auf linux1.
EMPFAENGER="diabetologie@dachau-mail.de"
RESERVER="linux0 linux7"
STATUSDIR=${BUMON_STATUSDIR:-/DATA}
ZUSTAND=${BUMON_ZUSTAND:-/var/lib/bumonitor}
BUSSH=${BUMON_SSH:-ssh -i /root/.ssh/id_ed25519_backup -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new}
MIN_FREI=${BU_MIN_FREI_PROZENT:-10}; KRIT_FREI=${BU_KRIT_FREI_PROZENT:-3}
MODUS=voll; NUR_ANZEIGEN=; TESTMAIL=
for a in "$@"; do case "$a" in voll|mittag) MODUS=$a;; -n) NUR_ANZEIGEN=1;; -t) TESTMAIL=1;; *) sed -n '2,17p' "$0"; exit 1;; esac; done
h=$(hostname); [ "${h%%.*}" = linux1 ] || { echo "bumonitor.sh laeuft nur auf linux1"; exit 0; }
# erlaubtes Alter in Stunden je Skript
if [ "$MODUS" = mittag ]; then SKRIPTE="bumo.sh"; declare -A MAXH=([bumo.sh]=3)
else SKRIPTE="bumo.sh bulinux.sh bunacht.sh"; declare -A MAXH=([bumo.sh]=26 [bulinux.sh]=30 [bunacht.sh]=30); fi
JETZT=$(date +%s); PROBLEME=""
add() { PROBLEME="${PROBLEME}${1}"$'\n'; }
DETAILS=""
detail() { DETAILS="${DETAILS}${1}"$'\n'; }
platz_pruefen() { # Rechner Statusdatei
  local r=$1 f=$2 live pct gb gbg quelle zeile zt ts al
  live=$(timeout 25 $BUSSH root@$r 'df /DATA' 2>/dev/null | tail -1 | awk 'NF>=5 && $(NF-4)>0 {printf "%d %d", $(NF-2), $(NF-4)}')
  if [ -n "$live" ]; then
    pct=$(echo "$live" | awk '{printf "%d", $1*100/$2}'); gb=$(echo "$live" | awk '{printf "%d", $1/1048576}'); gbg=$(echo "$live" | awk '{printf "%d", $2/1048576}')
    quelle="live gemessen (df /DATA)"
  else
    zeile=$(grep -E '^platz[[:space:]]' "$f" 2>/dev/null | tail -1)
    if [ -z "$zeile" ]; then detail "$r: freier Platz /DATA nicht pruefbar (Rechner aus, noch keine Platzmeldung im Heartbeat)"; return; fi
    zt=$(echo "$zeile" | awk '{print $2" "$3}'); ts=$(date -d "$zt" +%s 2>/dev/null) || { detail "$r: Platzmeldung unlesbar: $zeile"; return; }
    al=$((JETZT-ts))
    if [ "$al" -gt 259200 ]; then detail "$r: freier Platz /DATA nicht pruefbar (Rechner aus, letzte Platzmeldung vom $(date -d "@$ts" '+%d.%m.%Y %H:%M') ist aelter als 3 Tage)"; return; fi
    pct=$(echo "$zeile" | sed -n 's/.*frei=\([0-9]*\)%.*/\1/p'); gb=$(echo "$zeile" | sed -n 's/.* \([0-9]*\)GB\/[0-9]*GB.*/\1/p'); gbg=$(echo "$zeile" | sed -n 's/.*GB\/\([0-9]*\)GB.*/\1/p')
    [ -n "$pct" ] || { detail "$r: Platzmeldung unlesbar: $zeile"; return; }
    quelle="Heartbeat vom $(date -d "@$ts" '+%d.%m.%Y %H:%M')"
  fi
  detail "$r: /DATA frei ${gb:-?} GB von ${gbg:-?} GB (${pct} %), Quelle: $quelle"
  if [ "$pct" -lt "$KRIT_FREI" ]; then add "$r: Speicherplatz /DATA KRITISCH (unter $KRIT_FREI % frei) - Sicherungen koennen scheitern"
  elif [ "$pct" -lt "$MIN_FREI" ]; then add "$r: Speicherplatz /DATA knapp (unter $MIN_FREI % frei)"; fi
}
alter_text() { # Sekunden -> "6,5 Stunden" / "10,0 Tage"
  awk -v s="$1" 'BEGIN{ if (s>=172800) printf "%.1f Tagen", s/86400; else printf "%.1f Stunden", s/3600 }' | sed 's/\./,/'; }
for r in $RESERVER; do
  f="$STATUSDIR/Backup-Status_$r.txt"
  if [ ! -s "$f" ]; then add "$r: Statusdatei $f fehlt oder ist leer (noch nie gesichert?)"; [ "$MODUS" = voll ] && platz_pruefen "$r" "$f"; continue; fi
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
  [ "$MODUS" = voll ] && platz_pruefen "$r" "$f"
done
sig=$(printf '%s' "$PROBLEME" | sha256sum | cut -c1-16)
SF="$ZUSTAND/zustand_$MODUS"; letzte_sig=; letzte_zeit=0
[ -f "$SF" ] && { read -r letzte_sig letzte_zeit < "$SF"; }
mailen() { printf '%s\n' "$2" | mail -s "$1" "$EMPFAENGER"; }
kopf="Sicherungspruefung auf $h, $(date '+%d.%m.%Y %H:%M'), Modus: $MODUS"
if [ -n "$PROBLEME" ]; then
  text="Achtung,"$'\n\n'"die Sicherungen auf den Reserverechnern sind nicht richtig gelaufen:"$'\n\n'"$PROBLEME"$'\n'"$DETAILS"$'\n'"Naeheres: /DATA/Backup-Status_<Rechner>.txt auf linux1, /var/log/wecklauf.log auf dem jeweiligen Reserver."$'\n'"($kopf)"
  echo "$kopf: PROBLEME"; printf '%s' "$PROBLEME"; [ -n "$DETAILS" ] && printf 'Details:\n%s' "$DETAILS"
  if [ -n "$TESTMAIL" ]; then [ -n "$NUR_ANZEIGEN" ] || mailen "TEST Sicherungswarnung linux1 - Probleme (Testmail)" "$text"
  elif [ -z "$NUR_ANZEIGEN" ] && { [ "$sig" != "$letzte_sig" ] || [ $((JETZT-${letzte_zeit:-0})) -gt 86400 ]; }; then
    mailen "WARNUNG Sicherung: $(printf '%s' "$PROBLEME" | grep -c .) Problem(e) auf linux0/linux7" "$text"
    mkdir -p "$ZUSTAND"; echo "$sig $JETZT" > "$SF"; echo "Warnmail gesendet an $EMPFAENGER"
  elif [ -n "$NUR_ANZEIGEN" ]; then echo "(Anzeigemodus: keine Mail, Zustand unveraendert)"
  else echo "keine neue Mail (unveraendert seit letzter Meldung)"; fi
else
  echo "$kopf: alles in Ordnung"; [ -n "$DETAILS" ] && printf 'Details:\n%s' "$DETAILS"
  if [ -n "$TESTMAIL" ]; then [ -n "$NUR_ANZEIGEN" ] || mailen "TEST Sicherungswarnung linux1 - alles in Ordnung (Testmail)" "Die Sicherungspruefung auf $h meldet keine Probleme. ($kopf)"
  elif [ -z "$NUR_ANZEIGEN" ] && [ -n "$letzte_sig" ] && [ "$letzte_sig" != "$(printf '' | sha256sum | cut -c1-16)" ]; then
    mailen "Entwarnung Sicherung linux0/linux7" "Die zuvor gemeldeten Sicherungsprobleme sind behoben, alle geprueften Laeufe sind OK."$'\n'"($kopf)"
    mkdir -p "$ZUSTAND"; echo "$(printf '' | sha256sum | cut -c1-16) $JETZT" > "$SF"; echo "Entwarnung gesendet"
  fi
fi
exit 0
