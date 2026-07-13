#!/bin/bash
# wecklauf.sh - Nacht-/Mittagssicherung fuer linux0/linux7. Wird per Cron
# ALLE 5 MINUTEN aufgerufen (nicht per @reboot!) und prueft selbst, ob die
# aktuelle Uhrzeit in einem Toleranzfenster um die geplanten Weckzeiten
# liegt. Vorteil gegenueber @reboot: laeuft auch dann, wenn der Rechner
# schon vorher von Hand eingeschaltet wurde und einfach an blieb - nicht nur
# unmittelbar nach einem frischen Boot.
#
# Sicherheitsprinzip 1 (s. frueherer Ausfall bei linux7, bei dem irgendwann
# das Abschalten nicht mehr funktionierte und dadurch auch die naechste
# Weckzeit verloren ging): der naechste rtcwake-Alarm wird GANZ AM ANFANG
# gesetzt, VOR den eigentlichen Sicherungslaeufen - ein haengender oder
# fehlschlagender Lauf kann so bestenfalls das Abschalten diesmal
# verhindern (sichtbar/harmlos), nie aber das naechste Wecken.
#
# Sicherheitsprinzip 2: abgeschaltet wird am Ende nur, wenn der Rechner
# System-Uptime unterhalb $UPTIME_SCHWELLE_S hat, also offenbar gerade erst
# gebootet wurde (vermutlich durch rtcwake). Laeuft er schon laenger, war
# er vermutlich von Hand eingeschaltet/in Benutzung - dann wird zwar
# trotzdem gesichert (s.o.), aber NICHT abgeschaltet, um ihn niemandem
# unter den Fuessen wegzuschalten.
#
# Jeder Sicherungslauf ist mit "timeout" gegen unbegrenztes Haengen
# abgesichert. Ohne -e wird alles nur simuliert (rtcwake -Ausgabe, kein
# shutdown, kein Setzen von Merkerdateien, -e wird nicht an die
# Unterskripte durchgereicht).
#
# -e: echt (Alarm setzen, Skripte mit -e aufrufen, ggf. am Ende abschalten)
# ohne -e: Trockenlauf (nur anzeigen, nichts schalten/abschalten/merken)
# -zeit "HH:MM": Testzeit statt der echten Uhrzeit verwenden (fuer Tests ohne
#   auf die richtige Tageszeit warten zu muessen; Datum bleibt real)

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

TOLERANZ_S=$((7 * 60)); # Toleranzfenster um die Zielzeiten, groesser als das 5-Minuten-Pollintervall
UPTIME_SCHWELLE_S=$((10 * 60)); # nur abschalten, wenn seit weniger als 10 Min. gebootet
GRACE_DATEI=/root/.kein_wecklauf;
LETZTER_LAUF_DATEI=/root/.wecklauf_letzter_lauf_epoche; # zuletzt behandeltes Fenster (Ziel-Epoche)

# Wartungsschalter: wenn diese Datei existiert, macht wecklauf.sh gar nichts
# (kein Alarm, keine Skripte, kein Abschalten). Reicht, sie IRGENDWANN vor
# dem naechsten Fenster anzulegen (naechster Tick ist hoechstens 5 Min.
# entfernt) - nicht nur vorab wie bei @reboot. Danach wieder entfernen,
# sonst bleibt der Rechner dauerhaft von der Automatik ausgenommen.
if [ -f "$GRACE_DATEI" ]; then
  exit 0; # bewusst kein Log-Eintrag bei jedem 5-Minuten-Tick
fi;

case "$buhost" in
  linux0) MITTAG="14:18"; NACHT="21:45";;
  linux7) MITTAG="14:48"; NACHT="00:00";;
  *) exit 0;; # anderer Host (z.B. linux1) - still beenden
esac;

if [ "$testzeit" ]; then JETZT_EPOCHE=$(date -d "today $testzeit" +%s);
else JETZT_EPOCHE=$(date +%s); fi;

# Naechstgelegenen Kandidaten unter {MITTAG,NACHT} x {gestern,heute,morgen}
# suchen (deckt auch Mitternachts-Zeiten wie linux7s NACHT=00:00 robust ab,
# ohne zyklische Minutenrechnung mit Sonderfaellen):
BESTER_ABSTAND=; BESTE_EPOCHE=; BESTER_MODUS=;
for tag in yesterday today tomorrow; do
  for eintrag in "mittag:$MITTAG" "nacht:$NACHT"; do
    modus=${eintrag%%:*}; zeit=${eintrag#*:};
    kand=$(date -d "$tag $zeit" +%s 2>/dev/null) || continue;
    abst=$(( kand - JETZT_EPOCHE )); abst=${abst#-};
    if [ -z "$BESTER_ABSTAND" ] || [ "$abst" -lt "$BESTER_ABSTAND" ]; then
      BESTER_ABSTAND=$abst; BESTE_EPOCHE=$kand; BESTER_MODUS=$modus;
    fi;
  done;
done;

[ "$BESTER_ABSTAND" -gt "$TOLERANZ_S" ] && exit 0; # kein Fenster gerade - still beenden

LETZTER_LAUF=$(cat "$LETZTER_LAUF_DATEI" 2>/dev/null);
[ "$LETZTER_LAUF" = "$BESTE_EPOCHE" ] && exit 0; # dieses Fenster schon behandelt - still beenden

log "${blau}wecklauf.sh${reset} auf $buhost: Fenster erkannt (Modus: $BESTER_MODUS, Zielzeit $(date -d "@$BESTE_EPOCHE" '+%Y-%m-%d %H:%M:%S'), Abstand ${BESTER_ABSTAND}s)";
# Als behandelt markieren, BEVOR die (evtl. lange) Sicherung laeuft, damit
# der naechste 5-Minuten-Tick waehrenddessen nicht erneut auslöst:
[ "$obecht" ] && echo "$BESTE_EPOCHE" > "$LETZTER_LAUF_DATEI";

# Naechsten Alarm bestimmen (das jeweils andere Fenster, naechstes
# Vorkommen NACH diesem) und ZUERST setzen (s. Kommentar oben):
if [ "$BESTER_MODUS" = mittag ]; then NAECHSTE_ZEIT="$NACHT"; else NAECHSTE_ZEIT="$MITTAG"; fi;
NAECHSTE_EPOCHE=$(date -d "today $NAECHSTE_ZEIT" +%s);
[ "$NAECHSTE_EPOCHE" -le "$BESTE_EPOCHE" ] && NAECHSTE_EPOCHE=$(date -d "tomorrow $NAECHSTE_ZEIT" +%s);
log "Naechster Alarm: $NAECHSTE_ZEIT ($(date -d "@$NAECHSTE_EPOCHE" '+%Y-%m-%d %H:%M:%S'))";
if [ "$obecht" ]; then
  rtcwake -m no -t "$NAECHSTE_EPOCHE" 2>&1 | tee -a "$LOG"; # "-m no": nur Alarm setzen, kein Energiesparmodus
else
  log "Simulation: rtcwake -m no -t $NAECHSTE_EPOCHE";
fi;

_lauf() { # $1 = Skript, Rest = Argumente, ohne -e nur anzeigen
  local skript="$1"; shift;
  if [ "$obecht" ]; then
    log "${blau}Starte${reset} $skript $* -e";
    timeout "${WECKLAUF_TIMEOUT:-8h}" "$skript" "$@" -e 2>&1 | tee -a "$LOG";
    log "${blau}Ende${reset} $skript (Exitcode der timeout-Huelle: $?)";
  else
    log "Simulation: timeout ${WECKLAUF_TIMEOUT:-8h} $skript $* -e";
  fi;
}

# Schutzdateien auf linux1 (Quelle) vor dem Pull auffuellen - vermeidet
# "Schutzdatei fehlte auf Quelle"-Warnmails durch neu entstandene
# Verzeichnisse (z.B. neues Mail-Profil, neuer Jahresordner unter
# Patientendokumente/eingelesen). Laeuft ueber den normalen, uneinge-
# schraenkten Key (kein $QL/$ZL=linux0/linux7 hier), s. sdauffuellen.sh.
if [ "$obecht" ]; then
  log "${blau}Starte${reset} ssh linux1 sdauffuellen.sh -e";
  ssh linux1 '/root/bin/sdauffuellen.sh -e' 2>&1 | tee -a "$LOG";
else
  log "Simulation: ssh linux1 /root/bin/sdauffuellen.sh -e";
fi;

case "$BESTER_MODUS" in
  mittag)
    _lauf /root/bin/bumo.sh;
    ;;
  nacht)
    _lauf /root/bin/bumo.sh;
    _lauf /root/bin/bulinux.sh -f;
    _lauf /root/bin/bunacht.sh;
    ;;
esac;

UPTIME_S=$(awk '{print int($1)}' /proc/uptime 2>/dev/null);
if [ -n "$UPTIME_S" ] && [ "$UPTIME_S" -lt "$UPTIME_SCHWELLE_S" ]; then
  if [ "$obecht" ]; then
    log "${rot}Uptime ${UPTIME_S}s < ${UPTIME_SCHWELLE_S}s (vermutlich durch rtcwake gestartet) - schalte $buhost jetzt ab.${reset}";
    shutdown -h now;
  else
    log "Simulation: shutdown -h now (Uptime ${UPTIME_S}s < ${UPTIME_SCHWELLE_S}s)";
  fi;
else
  log "${blau}Uptime ${UPTIME_S:-?}s >= ${UPTIME_SCHWELLE_S}s - Rechner laeuft schon laenger (vermutlich von Hand eingeschaltet/in Benutzung) - schalte NICHT ab.${reset}";
fi;
