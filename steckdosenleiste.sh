#!/bin/bash
# steckdosenleiste.sh - Steckdosenleiste im Serverraum (Logilink SH0104) von linux1 aus pruefen; schaltet NICHTS.
#   steckdosenleiste.sh status       zeigt, welche Steckdosen an sind
#   steckdosenleiste.sh schluessel   nach einer Neueinrichtung der Leiste in der App "Smart Life": holt den neuen
#                                    Schluessel ("Local Key") aus der Tuya-Plattform und prueft danach den Status
# Nur auf linux1 als root. Schluessel liegen in /root/tinytuya (nicht anzeigen/weitergeben). Eingerichtet 4.10.2026.
# Fehler 901 = keine Verbindung (App "Smart Life" auf einem Handy offen? Leiste nicht im WLAN?)
# Fehler 904/914 = Schluessel passt nicht (Leiste wurde in der App neu eingerichtet) -> "steckdosenleiste.sh schluessel"
V=/root/tinytuya; PY=/opt/tinytuya/bin/python; ID=0031545070039f0e28e4; MAC=70:03:9f:0e:28:e4; SOLL_IP=192.168.178.73
[ -x "$PY" ] && [ -d "$V" ] || { echo "tinytuya ist auf diesem Rechner nicht eingerichtet (nur auf linux1)."; exit 1; }

ip_finden() { # aktuelle IP der Leiste ueber ihre (feste) MAC-Adresse
  ping -c1 -W2 "$SOLL_IP" >/dev/null 2>&1;
  if ip neigh | grep -i "$MAC" | grep -qv FAILED; then ip neigh | grep -i "$MAC" | grep -v FAILED | awk '{print $1; exit}'; return; fi;
  for i in $(seq 2 254); do ping -c1 -W1 192.168.178.$i >/dev/null 2>&1 & done; wait;
  ip neigh | grep -i "$MAC" | grep -v FAILED | awk '{print $1; exit}';
}

status() {
  IP=$(ip_finden);
  if [ -z "$IP" ]; then echo "Die Leiste ist nicht im Netz zu finden (Strom? WLAN? in der App eingerichtet?)."; return 1; fi;
  [ "$IP" != "$SOLL_IP" ] && echo "ACHTUNG: Die Leiste hat jetzt die IP $IP statt $SOLL_IP - in weckwacht.sh anpassen oder in der Fritzbox wieder $SOLL_IP fest zuweisen!";
  cd "$V" && "$PY" - "$ID" "$IP" <<'ENDE_STATUS'
import json, sys, tinytuya
did, ip = sys.argv[1], sys.argv[2]
x = [d for d in json.load(open("devices.json")) if d["id"] == did]
if not x:
    print("Die Leiste fehlt in devices.json - 'steckdosenleiste.sh schluessel' ausfuehren."); sys.exit(1)
dev = tinytuya.OutletDevice(did, ip, x[0]["key"], version=3.3); dev.set_socketTimeout(5); dev.set_socketRetryLimit(3)
st = dev.status()
if not st or "dps" not in st:
    err = (st or {}).get("Err")
    hinweis = {"901": "keine Verbindung - ist die App 'Smart Life' auf einem Handy im WLAN geoeffnet? Ganz schliessen und erneut versuchen.",
               "904": "Schluessel passt nicht - Leiste wurde neu eingerichtet: 'steckdosenleiste.sh schluessel' ausfuehren.",
               "914": "Schluessel passt nicht - Leiste wurde neu eingerichtet: 'steckdosenleiste.sh schluessel' ausfuehren."}.get(str(err), "")
    print("FEHLER:", st, "\n", hinweis); sys.exit(1)
namen = {"1": "linux0 (Sicherungsrechner)", "2": "linux1 (Hauptserver)", "3": "KoCoBox (TI-Konnektor)",
         "4": "Telefonanlage Panasonic KX-NS700", "5": "USB-Ausgang"}
print("Steckdosenleiste %s:" % ip)
for k in ("1", "2", "3", "4", "5"):
    print("  switch_%s  %-34s %s" % (k, namen[k], "AN" if st["dps"].get(k) else "AUS"))
ENDE_STATUS
}

case "$1" in
  status|"") status;;
  schluessel)
    cd "$V" || exit 1;
    cp -p devices.json "devices.json.vor_$(date +%Y%m%d_%H%M%S)" 2>/dev/null;
    echo "Hole den neuen Schluessel aus der Tuya-Plattform (Ausgabe wird absichtlich nicht angezeigt) ...";
    printf 'Y\nn\nn\n' | timeout 120 "$PY" -m tinytuya wizard >/dev/null 2>&1;
    chmod 600 "$V"/*.json;
    status;;
  *) sed -n '2,8p' "$0"; exit 1;;
esac
