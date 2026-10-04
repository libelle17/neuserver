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
# Sicherheitsprinzip 3 (s. Vorfall 24./25.07.2026 auf linux0: waehrend
# bunacht.sh noch lief, hat ein unabhaengiger - vermutlich manueller,
# ueber die Desktop-Oberflaeche ausgeloester - Shutdown das System
# heruntergefahren; das Aushaengen von /root blieb dabei haengen, weil
# bunacht.sh es noch benutzte ("Ziel wird gerade benutzt"), und der
# Rechner war danach einen Monat lang unerreichbar, ohne dass wecklauf.sh
# selbst dafuer verantwortlich war): waehrend der eigentlichen
# Sicherungslaeufe haelt wecklauf.sh per systemd-inhibit einen
# Delay-Inhibitor auf shutdown/sleep. Ein waehrenddessen angeforderter
# Shutdown/Sleep (egal ob manuell, per Desktop oder "systemctl poweroff")
# wird dadurch verzoegert, bis die Sicherung fertig ist - hoechstens
# aber um $InhibitDelayMaxSec aus logind.conf(.d/) (Standard nur 5s!,
# muss dort ausreichend hoch gesetzt sein, damit das wirkt).
#
# Jeder Sicherungslauf ist mit "timeout" gegen unbegrenztes Haengen
# abgesichert. Ohne -e wird alles nur simuliert (rtcwake -Ausgabe, kein
# shutdown, kein Setzen von Merkerdateien, -e wird nicht an die
# Unterskripte durchgereicht).
#
# -e: echt (Alarm setzen, Skripte mit -e aufrufen, ggf. am Ende abschalten)
# ohne -e: Trockenlauf (nur anzeigen, nichts schalten/abschalten/merken)
# -alarm: nur den Weckalarm auf das naechste Fenster pruefen/setzen und beenden (wecklauf-alarm.service)
# -zeit "HH:MM": Testzeit statt der echten Uhrzeit verwenden (fuer Tests ohne
#   auf die richtige Tageszeit warten zu muessen; Datum bleibt real)

MUPR=$(readlink -f "$0");
. "${MUPR%/*}/bul1.sh"; # LINEINS, buhost, EIGENHOST/EIGENNR, DATAZIEL festlegen

obecht=;
testzeit=;
while [ $# -gt 0 ]; do
  case "$1" in
    -e) obecht=1;;
    -alarm) nuralarm=1;; # nur Weckalarm-Wache, dann Ende (wecklauf-alarm.service beim Herunterfahren)
    -zeit) shift; testzeit="$1";;
  esac;
  shift;
done;

blau="\033[1;34m"; rot="\033[1;31m"; reset="\033[0m";
LOG=/var/log/wecklauf.log;
log() { printf '%s %b\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG"; }

TOLERANZ_S=$((7 * 60)); # Toleranzfenster um die Zielzeiten, groesser als das 5-Minuten-Pollintervall
UPTIME_SCHWELLE_S=$((10 * 60));
NACHHOL_MAX_S=$((12 * 3600)); # ausgefallene Fenster hoechstens so alt nachholen # nur abschalten, wenn seit weniger als 10 Min. gebootet
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

# Weckalarm-Wache (4.10.2026): Jeder Start ausser der Reihe (von Hand, nach "zypper up" usw.) schaltet auf
# diesen Hauptplatinen den RTC-Alarm ab (alarm_IRQ: no). Neu gesetzt wurde er bisher nur beim Bearbeiten
# eines Fensters - wer den Rechner vorher wieder ausschaltete, legte den ganzen Fahrplan still (z.B. linux7
# 1.10., linux0 4.10.). Deshalb bei JEDEM 5-Minuten-Aufruf: ist der Alarm nicht auf das naechste kuenftige
# Fenster gesetzt, neu setzen. Log nur bei Aenderung. Laeuft vor der Fenster-Erkennung; ein dort spaeter
# gesetzter Alarm (das jeweils andere Fenster) ueberschreibt diesen wie bisher.
if [ "$obecht" ] && [ -z "$testzeit" ]; then
  _wa_soll=; _wa_erledigt=$(cat "$LETZTER_LAUF_DATEI" 2>/dev/null);
  for _wa_tag in today tomorrow; do
    for _wa_zeit in "$MITTAG" "$NACHT"; do
      _wa_k=$(date -d "$_wa_tag $_wa_zeit" +%s 2>/dev/null) || continue;
      # schon bearbeitetes Fenster ueberspringen (es wird bis zu 7 min VOR der Zielzeit bearbeitet,
      # liegt dann also noch "in der Zukunft" - sonst wuerde der Rechner dazu erneut geweckt):
      [ "$_wa_k" = "$_wa_erledigt" ] && continue;
      [ "$_wa_k" -gt "$JETZT_EPOCHE" ] && { [ -z "$_wa_soll" ] || [ "$_wa_k" -lt "$_wa_soll" ]; } && _wa_soll=$_wa_k;
    done;
  done;
  _wa_ist=$(cat /sys/class/rtc/rtc0/wakealarm 2>/dev/null);
  if [ -n "$_wa_soll" ] && [ "$_wa_ist" != "$_wa_soll" ]; then
    _wa_txt="nicht gesetzt"; [ -n "$_wa_ist" ] && _wa_txt="auf $(date -d "@$_wa_ist" '+%d.%m. %H:%M')";
    log "Weckalarm-Wache: Alarm war $_wa_txt - setze auf naechstes Fenster $(date -d "@$_wa_soll" '+%d.%m. %H:%M')";
    rtcwake -m no -t "$_wa_soll" 2>&1 | tee -a "$LOG";
  fi;
fi;
[ "$nuralarm" ] && exit 0; # -alarm: nur die Wache (z.B. beim Herunterfahren), keine Fenster-Bearbeitung

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

# Nachholen (4.10.2026): liegt gerade kein Fenster an, aber das juengste vergangene Fenster (hoechstens
# NACHHOL_MAX_S alt) wurde nicht bearbeitet - Rechner war aus/hing, wurde von linux1 (weckwacht.sh) per
# Wake-on-LAN/Steckdose oder von Hand gestartet -, dann dieses Fenster jetzt nachholen.
NACHHOLEN=;
if [ "$BESTER_ABSTAND" -gt "$TOLERANZ_S" ]; then
  _nh_p=; _nh_m=;
  _nh_heute=$(date -d "@$JETZT_EPOCHE" +%F); _nh_gestern=$(date -d "$_nh_heute -1 day" +%F);
  for _nh_tag in "$_nh_gestern" "$_nh_heute"; do
    for _nh_e in "mittag:$MITTAG" "nacht:$NACHT"; do
      _nh_k=$(date -d "$_nh_tag ${_nh_e#*:}" +%s 2>/dev/null) || continue;
      [ "$_nh_k" -le "$JETZT_EPOCHE" ] && { [ -z "$_nh_p" ] || [ "$_nh_k" -gt "$_nh_p" ]; } && { _nh_p=$_nh_k; _nh_m=${_nh_e%%:*}; };
    done;
  done;
  _nh_letzt=$(cat "$LETZTER_LAUF_DATEI" 2>/dev/null);
  if [ -z "$_nh_p" ] || [ $((JETZT_EPOCHE - _nh_p)) -gt "$NACHHOL_MAX_S" ] || { [ -n "$_nh_letzt" ] && [ "$_nh_letzt" -ge "$_nh_p" ]; }; then
    exit 0; # kein Fenster gerade und nichts nachzuholen - still beenden
  fi;
  NACHHOLEN=1; BESTE_EPOCHE=$_nh_p; BESTER_MODUS=$_nh_m; BESTER_ABSTAND=$((JETZT_EPOCHE - _nh_p));
fi;

LETZTER_LAUF=$(cat "$LETZTER_LAUF_DATEI" 2>/dev/null);
[ "$LETZTER_LAUF" = "$BESTE_EPOCHE" ] && exit 0; # dieses Fenster schon behandelt - still beenden

[ "$NACHHOLEN" ] && log "${rot}Ausgefallenes Fenster wird nachgeholt:${reset}";
log "${blau}wecklauf.sh${reset} auf $buhost: Fenster erkannt (Modus: $BESTER_MODUS, Zielzeit $(date -d "@$BESTE_EPOCHE" '+%Y-%m-%d %H:%M:%S'), Abstand ${BESTER_ABSTAND}s)";
# Als behandelt markieren, BEVOR die (evtl. lange) Sicherung laeuft, damit
# der naechste 5-Minuten-Tick waehrenddessen nicht erneut auslöst:
[ "$obecht" ] && echo "$BESTE_EPOCHE" > "$LETZTER_LAUF_DATEI";
# Beginn an linux1 melden (weckwacht.sh weckt sonst nach 20 min), best effort:
[ "$obecht" ] && ssh -o ConnectTimeout=20 -o BatchMode=yes linux1 "mkdir -p /var/lib/wecklauf && echo $BESTE_EPOCHE > /var/lib/wecklauf/lauf_$buhost" 2>&1 | tee -a "$LOG";
# Rechnerschluessel der Uebernahme-Kandidaten auch unter "linux1" bekannt machen (s. hostkeys_uebernahme.sh):
[ "$obecht" ] && [ -x /root/bin/hostkeys_uebernahme.sh ] && /root/bin/hostkeys_uebernahme.sh -e 2>&1 | tee -a "$LOG";

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

# Uptime JETZT merken, VOR den Sicherungslaeufen - Bugfix 20.07.2026: die
# fruehere Pruefung NACH den Laeufen (s. Git-Historie) ergab bei variabler
# Laufzeit (z.B. haelftig-automatischer Faxversand aller DMP-Dokumente an
# Hausaerzte innerhalb bunacht.sh, je nach Betrieb mal kurz, mal lang)
# faelschlich "laeuft schon laenger, vermutlich von Hand eingeschaltet" und
# verhinderte dadurch das Abschalten, obwohl der Rechner tatsaechlich frisch
# per rtcwake gestartet war (beobachtet 20.07.2026 auf linux7: Nachtlauf
# dauerte bis 02:05 Uhr bei Boot um 00:00 Uhr, Uptime beim spaeten Check
# 7486s >= Schwelle). Die Uptime direkt nach Fenster-Erkennung ist der
# richtige Messzeitpunkt, unabhaengig von der spaeteren Laufzeit.
UPTIME_BEIM_START_S=$(awk '{print int($1)}' /proc/uptime 2>/dev/null);
if [ -n "$UPTIME_BEIM_START_S" ] && [ "$UPTIME_BEIM_START_S" -lt "$UPTIME_SCHWELLE_S" ]; then
  OB_FRISCH_GEBOOTET=1;
  log "Uptime beim Fenster-Start: ${UPTIME_BEIM_START_S}s < ${UPTIME_SCHWELLE_S}s - frisch gebootet (vermutlich rtcwake), wird am Ende abgeschaltet.";
else
  OB_FRISCH_GEBOOTET=;
  log "Uptime beim Fenster-Start: ${UPTIME_BEIM_START_S:-?}s >= ${UPTIME_SCHWELLE_S}s - laeuft schon laenger (vermutlich von Hand eingeschaltet/in Benutzung), wird am Ende NICHT abgeschaltet.";
fi;

# Beim Nachholen entscheidet nicht die Uptime: abgeschaltet wird nur, wenn linux1 (weckwacht.sh) den Rechner
# fuer genau dieses Fenster geweckt hat (Notiz /var/lib/wecklauf/geweckt_<host> auf linux1). Hat ihn ein
# Mensch eingeschaltet, wird nachgeholt, aber nicht abgeschaltet.
if [ "$NACHHOLEN" ]; then
  _nh_geweckt=$(ssh -o ConnectTimeout=20 -o BatchMode=yes linux1 "cat /var/lib/wecklauf/geweckt_$buhost 2>/dev/null" 2>/dev/null);
  if [ "$_nh_geweckt" = "$BESTE_EPOCHE" ]; then
    OB_FRISCH_GEBOOTET=1;
    log "Nachholen: von linux1 fuer dieses Fenster geweckt - wird am Ende abgeschaltet.";
  else
    OB_FRISCH_GEBOOTET=;
    log "Nachholen: nicht von linux1 geweckt (vermutlich von Hand eingeschaltet) - wird am Ende NICHT abgeschaltet.";
  fi;
fi;

_lauf() { # $1 = Skript, Rest = Argumente, ohne -e nur anzeigen
  local skript="$1"; shift;
  if [ "$obecht" ]; then
    log "${blau}Starte${reset} $skript $* -e";
    timeout "${WECKLAUF_TIMEOUT:-8h}" "$skript" "$@" -e 2>&1 | tee -a "$LOG";
    # Bugfix 4.10.2026: frueher "$?" = Exitcode von tee (immer 0) - ein Abbruch durch die
    # Zeitbegrenzung (bulinux.sh in der Nacht 3./4.10. auf linux0 UND linux7) erschien als
    # "Exitcode 0". Jetzt der echte Exitcode von timeout/Skript; 124 = Zeitbegrenzung erreicht.
    local rc=${PIPESTATUS[0]};
    log "${blau}Ende${reset} $skript (Exitcode der timeout-Huelle: $rc)";
    [ "$rc" = 124 ] && log "${rot}ABGEBROCHEN:${reset} $skript nach ${WECKLAUF_TIMEOUT:-8h} durch die Zeitbegrenzung beendet - Sicherung UNVOLLSTAENDIG!";
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

# Shutdown/Sleep-Inhibitor fuer die Dauer der Sicherungslaeufe setzen, s.
# Sicherheitsprinzip 3 oben. $INHIBIT_PID haelt den systemd-inhibit-Prozess,
# der den Lock nur haelt, solange er lebt - Beenden gibt ihn wieder frei.
# Der EXIT-Trap sorgt dafuer, dass der Lock auch bei einem unerwarteten
# Abbruch von wecklauf.sh selbst (z.B. Strg-C bei einem manuellen Test)
# nicht dauerhaft haengen bleibt.
INHIBIT_PID=;
_inhibit_freigeben() {
  if [ "$INHIBIT_PID" ]; then
    kill "$INHIBIT_PID" 2>/dev/null;
    wait "$INHIBIT_PID" 2>/dev/null;
    INHIBIT_PID=;
    log "Shutdown/Sleep-Inhibitor wieder freigegeben.";
  fi;
}
if [ "$obecht" ] && command -v systemd-inhibit >/dev/null 2>&1; then
  trap _inhibit_freigeben EXIT;
  systemd-inhibit --what=shutdown:sleep --who=wecklauf.sh \
    --why="Sicherungslauf ($BESTER_MODUS) auf $buhost laeuft" --mode=delay \
    sleep infinity &
  INHIBIT_PID=$!;
  log "Shutdown/Sleep-Inhibitor gesetzt (PID $INHIBIT_PID) - schuetzt die folgenden Sicherungslaeufe.";
fi;

case "$BESTER_MODUS" in
  mittag)
    _lauf /root/bin/bumo.sh;
    ;;
  nacht)
    _lauf /root/bin/bumo.sh;
    _lauf /root/bin/bulinux.sh -f;
    _lauf /root/bin/bunacht.sh;
    # Eigene C++-Programme (autofax, anrliste, fbfax ...) auf den neuesten github-Stand
    # bringen, damit dieser Ersatzrechner bei Ausfall von linux1 sofort bereit ist
    # (5.10.2026). Nicht ueber _lauf: los.sh kennt kein -e; baut nur Geaendertes.
    if [ "$obecht" ]; then
      log "${blau}Starte${reset} los.sh -pa";
      timeout 2h /root/bin/los.sh -pa 2>&1 | tee -a "$LOG";
      log "${blau}Ende${reset} los.sh -pa (Exitcode der timeout-Huelle: ${PIPESTATUS[0]})";
    else
      log "Simulation: timeout 2h /root/bin/los.sh -pa";
    fi;
    ;;
esac;

_inhibit_freigeben;

# Entscheidung nutzt die beim Fenster-START gemerkte Uptime (s.o.), nicht
# eine erneute Messung hier - genau das war der Bugfix vom 20.07.2026.
if [ "$OB_FRISCH_GEBOOTET" ]; then
  if [ "$obecht" ]; then
    log "${rot}War beim Fenster-Start frisch gebootet - schalte $buhost jetzt ab.${reset}";
    shutdown -h now;
  else
    log "Simulation: shutdown -h now (war beim Fenster-Start frisch gebootet)";
  fi;
else
  log "${blau}War beim Fenster-Start schon laenger gelaufen (vermutlich von Hand eingeschaltet/in Benutzung) - schalte NICHT ab.${reset}";
fi;
