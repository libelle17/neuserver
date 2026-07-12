#!/bin/bash
# wecklauf.sh - Nacht-/Mittagssicherung fuer linux0/linux7: wird per @reboot
# gestartet, nachdem rtcwake den Rechner geweckt hat, fuehrt je nach
# Tageszeit die Mittags- (nur bumo.sh) oder die Nachtsequenz (bumo.sh,
# bulinux.sh, bunacht.sh) aus und schaltet den Rechner danach wieder ab.
#
# Sicherheitsprinzip (s. frueherer Ausfall bei linux7, bei dem irgendwann das
# Abschalten nicht mehr funktionierte und die naechste Weckzeit verloren
# ging): der naechste rtcwake-Alarm wird GANZ AM ANFANG gesetzt, VOR den
# eigentlichen Sicherungslaeufen - damit ein haengender oder fehlschlagender
# Lauf niemals das naechste Aufwachen verhindert (hoechstens das Abschalten
# diesmal ausbleibt, was aber sichtbar/harmlos ist, da die Maschine dann
# einfach an bleibt statt zu verschwinden). Jeder Sicherungslauf ist mit
# "timeout" gegen unbegrenztes Haengen abgesichert; ohne -e wird alles nur
# simuliert (rtcwake -n, kein shutdown, -e wird nicht an die Unterskripte
# durchgereicht).
#
# -e: echt (Alarm setzen, Skripte mit -e aufrufen, am Ende abschalten)
# ohne -e: Trockenlauf (nur anzeigen, nichts schalten/abschalten)
# -zeit "HH:MM": Testzeit statt der echten Uhrzeit verwenden (fuer Tests ohne
#   auf die richtige Tageszeit warten zu muessen)

MUPR=$(readlink -f "$0");
. "${MUPR%/*}/bul1.sh"; # LINEINS, buhost, EIGENHOST/EIGENNR, DATAZIEL festlegen

obecht=;
testzeit=;
while [ $# -gt 0 ]; do
  case "$1" in
    -e) obecht=1;;
    -zeit) shift; testzeit="$1";;
  esac;
  shift;
done;

blau="\033[1;34m"; rot="\033[1;31m"; reset="\033[0m";
LOG=/var/log/wecklauf.log;
log() { printf '%s %b\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG"; }

# Wartungsschalter: wenn diese Datei existiert, macht wecklauf.sh gar nichts
# (kein Alarm, keine Skripte, kein Abschalten) - z.B. fuer manuelle Eingriffe.
# Danach unbedingt wieder entfernen, sonst bleibt der Rechner naechstes Mal an!
if [ -f /root/.kein_wecklauf ]; then
  log "/root/.kein_wecklauf vorhanden - wecklauf.sh tut nichts (auch kein Alarm gesetzt!).";
  exit 0;
fi;

case "$buhost" in
  linux0) MITTAG="14:18"; NACHT="21:45";;
  linux7) MITTAG="14:48"; NACHT="00:00";;
  *) log "wecklauf.sh: unbekannter/nicht vorgesehener Host '$buhost' - breche ab."; exit 1;;
esac;

_minuten() { local h=${1%%:*} m=${1##*:}; echo $((10#$h * 60 + 10#$m)); } # HH:MM -> Minuten seit Mitternacht
_zyklabstand() { local d=$(( $1 - $2 )); d=${d#-}; [ "$d" -gt 720 ] && d=$((1440 - d)); echo "$d"; }
_naechste_epoche() { # $1 = HH:MM -> naechste zukuenftige Epoche dieser Uhrzeit (heute oder morgen)
  local heute; heute=$(date -d "today $1" +%s);
  local jetzt; jetzt=$(date +%s);
  if [ "$heute" -gt "$jetzt" ]; then echo "$heute"; else date -d "tomorrow $1" +%s; fi;
}

JETZT="${testzeit:-$(date +%H:%M)}";
JETZT_MIN=$(_minuten "$JETZT");
AB_MITTAG=$(_zyklabstand "$JETZT_MIN" "$(_minuten "$MITTAG")");
AB_NACHT=$(_zyklabstand "$JETZT_MIN" "$(_minuten "$NACHT")");
if [ "$AB_MITTAG" -le "$AB_NACHT" ]; then MODUS=mittag; NAECHSTER="$NACHT"; else MODUS=nacht; NAECHSTER="$MITTAG"; fi;

NAECHSTE_EPOCHE=$(_naechste_epoche "$NAECHSTER");
log "${blau}wecklauf.sh${reset} auf $buhost, Uhrzeit $JETZT (Modus: $MODUS), naechster Weckzeitpunkt: $NAECHSTER ($(date -d "@$NAECHSTE_EPOCHE" '+%Y-%m-%d %H:%M:%S'))";

# Naechsten Alarm ZUERST setzen (s. Kommentar oben) - "-m no" setzt nur den
# RTC-Alarm, ohne den Rechner in irgendeinen Energiesparmodus zu versetzen:
if [ "$obecht" ]; then
  rtcwake -m no -t "$NAECHSTE_EPOCHE" 2>&1 | tee -a "$LOG";
else
  log "Simulation: rtcwake -m no -t $NAECHSTE_EPOCHE";
fi;

_lauf() { # $1 = Skript, Rest = Argumente, ohne -e nur anzeigen
  local skript="$1"; shift;
  if [ "$obecht" ]; then
    log "${blau}Starte${reset} $skript $* -e";
    timeout "${WECKLAUF_TIMEOUT:-5h}" "$skript" "$@" -e 2>&1 | tee -a "$LOG";
    log "${blau}Ende${reset} $skript (Exitcode der timeout-Huelle: $?)";
  else
    log "Simulation: timeout ${WECKLAUF_TIMEOUT:-5h} $skript $* -e";
  fi;
}

case "$MODUS" in
  mittag)
    _lauf /root/bin/bumo.sh;
    ;;
  nacht)
    _lauf /root/bin/bumo.sh;
    _lauf /root/bin/bulinux.sh -f;
    _lauf /root/bin/bunacht.sh;
    ;;
esac;

if [ "$obecht" ]; then
  log "${rot}Schalte $buhost jetzt ab.${reset}";
  shutdown -h now;
else
  log "Simulation: shutdown -h now";
fi;
