#!/bin/bash
# Signiert einen oeffentlichen Schluessel. Aufruf (auf dem CA-Rechner):
#   ca_sign.sh <schluessel.pub> <Kennung> <principals,komma> [Gueltigkeit]
# Beispiele:
#   ca_sign.sh /root/.ssh/id_ed25519.pub root-linux1 admin +13w
#   ca_sign.sh /tmp/pc07_schade.pub  schade-pc07 schade +52w
# Ergebnis: <schluessel>-cert.pub neben dem Schluessel (ssh findet <name>-cert.pub selbst).
# Jedes Zertifikat bekommt eine laufende Seriennummer und wird in issued.log vermerkt
# (fuer Widerruf und Uebersicht).
set -e
CAD=${CAD:-/root/ca-pilot}
[ $# -ge 3 ] || { sed -n '2,9p' "$0"; exit 1; }
PUB=$1; ID=$2; PRIN=$3; VAL=${4:-+13w}
[ -f "$PUB" ] || { echo "Schluessel $PUB fehlt"; exit 1; }
[ -f "$CAD/user_ca" ] || { echo "Keine CA unter $CAD (erst ca_init.sh)"; exit 1; }
case "$PRIN" in *[!A-Za-z0-9_,.-]*|"") echo "Ungueltige Principals: $PRIN"; exit 1;; esac
exec 9>"$CAD/.lock"; flock 9
SER=$(( $(cat "$CAD/serial") + 1 )); echo $SER > "$CAD/serial"
ssh-keygen -q -s "$CAD/user_ca" -I "$ID" -n "$PRIN" -V "$VAL" -z "$SER" \
  -O no-agent-forwarding -O no-port-forwarding -O no-x11-forwarding "$PUB"
CERT="${PUB%.pub}-cert.pub"
printf '%s serial=%s id=%s principals=%s valid=%s key=%s\n' "$(date '+%F %T')" "$SER" "$ID" "$PRIN" "$VAL" \
  "$(ssh-keygen -lf "$PUB" | awk '{print $2}')" >> "$CAD/issued.log"
echo "Zertifikat: $CERT"; ssh-keygen -Lf "$CERT" | sed -n '1,12p'
