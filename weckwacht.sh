#!/bin/bash
# weckwacht.sh - laeuft auf linux1 alle 5 Minuten (Cron). Prueft, ob die Sicherungsrechner linux0/linux7
# ihr letztes Sicherungsfenster (wecklauf.sh) begonnen haben, und weckt sie sonst. Eingerichtet 4.10.2026.
#
# Signal: wecklauf.sh schreibt zu Beginn jedes (auch nachgeholten) Fensters dessen Zielzeit (Epoche) per ssh
# nach /var/lib/wecklauf/lauf_<host> auf linux1. linux1 selbst hat bewusst KEINEN ssh-Zugang zu
# linux0/linux7 (Schutz der Sicherungen) - Wecken per Wake-on-LAN (weckalle.sh) gibt keinen Zugang.
#
# Ablauf je Rechner, sobald seit der Zielzeit FRUEH_S vergangen sind (bis hoechstens SPAET_S):
#  1. lauf_<host> >= Zielzeit                      -> Fenster lief, nichts zu tun
#  2. Rechner antwortet auf Ping                   -> laeuft, aber ohne Lauf (Wartung?) - einmal melden, nicht wecken
#  3. noch nicht geweckt fuer dieses Fenster       -> geweckt_<host> = Zielzeit schreiben, per WOL wecken, mailen
#     (wecklauf.sh auf dem Rechner holt das Fenster dann nach und schaltet nur ab, weil geweckt_<host> passt)
#  4. Stufe 3 (nur wenn /var/lib/wecklauf/strom_<host> die tinytuya-Steckdosennummer enthaelt): geweckt, aber
#     nach STROM_NACH_S immer noch kein Lauf und kein Ping -> Steckdose 20 s aus, wieder ein (BIOS "Restore AC
#     Power Loss = Power On" noetig), mailen. Je Fenster hoechstens einmal. Fuer Haenger beim Abschalten.
#
# Abschalten: /root/.kein_weckwacht (alles) bzw. /var/lib/wecklauf/kein_<host> (ein Rechner).
# Aufruf: weckwacht.sh [-e] [-zeit "JJJJ-MM-TT HH:MM"]   ohne -e nur anzeigen (kein Wecken/Schalten/Mailen/Merken)

obecht=; testzeit=;
while [ $# -gt 0 ]; do
  case "$1" in -e) obecht=1;; -zeit) shift; testzeit="$1";; esac; shift;
done;
S=/var/lib/wecklauf; LOG=/var/log/weckwacht.log;
FRUEH_S=$((20*60)); SPAET_S=$((3*3600)); STROM_NACH_S=$((15*60));
EMPF=root; # wird auf linux1 an die Praxisadresse weitergeleitet
[ -f /root/.kein_weckwacht ] && exit 0;
mkdir -p "$S";
log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG"; }
mail_an() { { printf 'To: %s\nSubject: %s\nContent-Type: text/plain; charset=UTF-8\n\n' "$EMPF" "$1"; printf '%s\n' "$2"; } | /usr/sbin/sendmail -t; }
if [ "$testzeit" ]; then JETZT=$(date -d "$testzeit" +%s); else JETZT=$(date +%s); fi;

# Rechner IP MITTAG NACHT MAC (Weckzeiten wie in wecklauf.sh)
# Im Notfallbetrieb (uebernahme.sh: dieser Rechner spielt linux1, eigentlich z.B. linux0) die eigene,
# eigentliche Identitaet nicht pruefen - sonst Fehlalarme bzw. Wecken seiner selbst (4.10.2026).
EIGEN=$(cat /etc/notfallbetrieb 2>/dev/null);
while read -r h ip mittag nacht mac; do
  [ -f "$S/kein_$h" ] && continue;
  [ -n "$EIGEN" ] && [ "$h" = "$EIGEN" ] && continue;
  # juengstes Fenster, dessen Pruefzeit (Zielzeit + FRUEH_S) erreicht ist, hoechstens SPAET_S alt
  P=;
  heute=$(date -d "@$JETZT" +%F); gestern=$(date -d "$heute -1 day" +%F);
  for tag in "$gestern" "$heute"; do
    for z in "$mittag" "$nacht"; do
      k=$(date -d "$tag $z" +%s);
      [ $((k + FRUEH_S)) -le "$JETZT" ] && [ $((JETZT - k)) -le "$SPAET_S" ] && { [ -z "$P" ] || [ "$k" -gt "$P" ]; } && P=$k;
    done;
  done;
  [ -z "$P" ] && continue;
  pz=$(date -d "@$P" '+%d.%m. %H:%M');
  lauf=$(cat "$S/lauf_$h" 2>/dev/null); [ -n "$lauf" ] && [ "$lauf" -ge "$P" ] && continue; # Fenster lief
  if ping -c1 -W2 "$ip" >/dev/null 2>&1; then
    [ "$(cat "$S/gemeldet_$h" 2>/dev/null)" = "$P" ] && continue;
    # selbst fuer dieses Fenster geweckt (WOL/Steckdose) und das ist noch keine STROM_NACH_S her: der Rechner
    # startet gerade und holt nach, sein lauf_<host> kommt erst mit dem naechsten wecklauf-Aufruf - nicht melden
    # (Fehlalarm 9.10.2026 22:30, 5 min nach dem Stromschnitt)
    gz=$(cat "$S/geweckt_zeit_$h" 2>/dev/null);
    [ "$(cat "$S/geweckt_$h" 2>/dev/null)" = "$P" ] && [ -n "$gz" ] && [ $((JETZT - gz)) -lt "$STROM_NACH_S" ] && continue;
    log "$h: Fenster $pz nicht begonnen, Rechner laeuft aber (Wartungsdatei? Fehler?) - wecke nicht.";
    [ "$obecht" ] && { echo "$P" > "$S/gemeldet_$h"; mail_an "weckwacht: $h hat Sicherungsfenster $pz nicht begonnen" "$h laeuft (antwortet auf Ping), hat das Sicherungsfenster $pz aber nicht begonnen. Bitte /var/log/wecklauf.log auf $h pruefen (Wartungsdatei /root/.kein_wecklauf?)."; };
    continue;
  fi;
  if [ "$(cat "$S/geweckt_$h" 2>/dev/null)" != "$P" ]; then
    log "$h: Fenster $pz nicht begonnen und Rechner aus/haengt - wecke per Wake-on-LAN ($mac).";
    if [ "$obecht" ]; then
      echo "$P" > "$S/geweckt_$h"; date +%s > "$S/geweckt_zeit_$h";
      # weckalle.sh schreibt Farbcodes und eine mit \r ueberschriebene Fortschrittszeile ohne Zeilenende - sonst
      # haengt die naechste Logzeile dahinter und ist in less/tail unsichtbar (10.10.2026)
      /root/bin/weckalle.sh "$mac" 2>&1 | sed 's/\x1b\[[0-9;]*m//g; s/\r/\n/g' | grep -v '^ *$' >> "$LOG";
      mail_an "weckwacht: $h fuer ausgefallenes Fenster $pz geweckt" "$h hat das Sicherungsfenster $pz nicht begonnen und antwortete nicht auf Ping. linux1 hat ihn per Wake-on-LAN geweckt; er sollte die Sicherung nachholen und sich danach abschalten.";
    else log "Simulation: weckalle.sh $mac"; fi;
    continue;
  fi;
  # schon geweckt - Stufe 3 (Steckdose) nur wenn eingerichtet
  sw=$(cat "$S/strom_$h" 2>/dev/null); [ -z "$sw" ] && continue;
  [ "$(cat "$S/strom_erledigt_$h" 2>/dev/null)" = "$P" ] && continue;
  gz=$(cat "$S/geweckt_zeit_$h" 2>/dev/null); [ -n "$gz" ] && [ $((JETZT - gz)) -ge "$STROM_NACH_S" ] || continue;
  log "$h: nach Wake-on-LAN $(( (JETZT - gz) / 60 )) min ohne Lauf und ohne Ping - schalte Steckdose $sw 20 s aus (vermutlich Haenger beim Abschalten).";
  if [ "$obecht" ]; then
    echo "$P" > "$S/strom_erledigt_$h";
    # Antwort der Leiste auswerten: sie erlaubt oft nur EINE lokale Verbindung - ist die App "Smart Life"
    # auf einem Handy im WLAN geoeffnet, schlaegt das Schalten fehl (festgestellt 4.10.2026).
    _st_aus=$(/opt/tinytuya/bin/python - "$sw" 2>&1 <<'ENDE_TUYA'
import json, sys, time, tinytuya
sw = sys.argv[1]
x = [d for d in json.load(open("/root/tinytuya/devices.json")) if d["id"] == "0031545070039f0e28e4"][0]
dev = tinytuya.OutletDevice(x["id"], "192.168.178.73", x["key"], version=3.3)
dev.set_socketTimeout(5); dev.set_socketRetryLimit(5)
def schalte(an):
    for versuch in range(6):
        r = dev.set_value(sw, an)
        if r and r.get("dps", {}).get(sw) == an:
            return True
        print(time.strftime("%H:%M:%S"), "switch_%s %s fehlgeschlagen:" % (sw, "EIN" if an else "AUS"), r, flush=True)
        time.sleep(10)
    return False
if not schalte(False):
    print("FEHLER: Steckdose liess sich nicht ausschalten (App Smart Life offen? Leiste erreichbar?)"); sys.exit(1)
print(time.strftime("%H:%M:%S"), "switch_%s AUS" % sw, flush=True)
time.sleep(20)
if not schalte(True):
    print("FEHLER: Steckdose liess sich NICHT WIEDER EINSCHALTEN - bitte von Hand/per App einschalten!"); sys.exit(2)
print(time.strftime("%H:%M:%S"), "switch_%s EIN" % sw, flush=True)
ENDE_TUYA
); _st_rc=$?;
    printf '%s\n' "$_st_aus" >> "$LOG";
    # Stromschnitt gilt als neues Wecken (Schonfrist fuer die "laeuft aber"-Meldung, s.o.)
    [ "$_st_rc" = 0 ] && date +%s > "$S/geweckt_zeit_$h";
    case $_st_rc in
      0) mail_an "weckwacht: Strom von $h kurz unterbrochen" "$h hat auch $(( (JETZT - gz) / 60 )) Minuten nach dem Wake-on-LAN-Wecken das Fenster $pz nicht begonnen und antwortete nicht auf Ping (vermutlich Haenger beim Abschalten). linux1 hat seine Steckdose (switch_$sw) 20 Sekunden ausgeschaltet; er sollte jetzt starten und nachholen.";;
      2) mail_an "weckwacht: DRINGEND - Steckdose von $h bleibt AUS" "linux1 hat die Steckdose von $h (switch_$sw) ausgeschaltet, konnte sie aber nicht wieder einschalten. Bitte per App Smart Life oder von Hand einschalten! Ausgabe: $_st_aus";;
      *) mail_an "weckwacht: Steckdose von $h nicht schaltbar" "$h haengt vermutlich (kein Lauf, kein Ping nach Wake-on-LAN), aber linux1 konnte seine Steckdose (switch_$sw) nicht schalten - ist die App Smart Life auf einem Handy im WLAN geoeffnet? Bitte $h von Hand aus- und einschalten. Ausgabe: $_st_aus";;
    esac;
  else log "Simulation: Steckdose switch_$sw 20 s aus, dann ein"; fi;
done <<'EOF'
linux0 192.168.178.20 14:18 21:45 FC:34:97:11:89:AD
linux7 192.168.178.27 14:48 00:00 40:8D:5C:52:ED:75
EOF
