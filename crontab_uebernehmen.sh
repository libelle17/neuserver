#!/bin/bash
# crontab_uebernehmen.sh - gleicht die crontab DIESES Rechners an die kanonische Fassung im
# Repository an (/root/neuserver/crontabdump). linux1 pflegt crontabdump (git commit, wie
# bisher schon ueblich, z.B. Commit d4f13a2); linux0/linux7 bekommen die Datei ganz normal
# per "git pull" (bzw. shziel fuer /root/bin) - dieses Skript macht daraus KEIN automatisches
# "crontab -", sondern zeigt den Unterschied und installiert nur mit "--anwenden".
#
# Hintergrund: jede Zeile der crontab traegt eine HOST=$(hostname)-Bedingung; nur der jeweils
# passende Rechner fuehrt sie aus. Der crontab-TEXT kann daher auf allen drei Rechnern
# identisch sein (Kontrolle bisher taeglich um 00:00 per Hash von /root/crontabakt gegen-
# geprueft, s. Bericht vom 22.9.2026). Dieses Skript ersetzt das bisherige manuelle
# "crontab -l > Sicherung; ...; crontab -" durch einen einzigen, sicheren Schritt.
#
# NICHT per Cron aufrufen (kein Auto-Install) - immer von Hand, nach eigener Kontrolle des
# angezeigten Unterschieds. Sichert die bisherige crontab vor jeder Aenderung.
#
# Aufruf: crontab_uebernehmen.sh              zeigt nur den Unterschied (nichts wird geschrieben)
#         crontab_uebernehmen.sh --anwenden   sichert die aktuelle crontab und installiert crontabdump
#         crontab_uebernehmen.sh -f <Kanon-Datei> [-h <Rechnername>] [--anwenden]   fuer Tests
KANON=/root/neuserver/crontabdump
ANWENDEN=; HOSTUEBER=
while [ $# -gt 0 ]; do
  case "$1" in
    --anwenden) ANWENDEN=1;;
    -f) KANON=$2; shift;;
    -h) HOSTUEBER=$2; shift;;
    *) sed -n '2,17p' "$0"; exit 1;;
  esac
  shift
done

[ -f "$KANON" ] || { echo "kanonische Datei fehlt: $KANON (git pull?)"; exit 1; }

host=${HOSTUEBER:-$(hostname)}; host=${host%%.*}
case "$host" in
  linux1|linux0|linux7) ;;
  *) echo "WARNUNG: unbekannter Rechnername '$host' - die HOST=\$(hostname)-Bedingungen in der crontab greifen nur fuer linux1/linux0/linux7. Nichts geschrieben, bitte erst pruefen (neuer Rechnername? Uebernahme-Server?)."; exit 1;;
esac
grep -q 'HOST=\$(hostname)' "$KANON" || { echo "$KANON enthaelt keine HOST=\$(hostname)-Bedingung - sieht nicht nach der erwarteten Mehrrechner-crontab aus, abgebrochen."; exit 1; }

if [ -n "$HOSTUEBER" ]; then AKTUELL=$(cat "${TESTCRONTAB:-/dev/null}" 2>/dev/null); else AKTUELL=$(crontab -l 2>/dev/null); fi
NEU=$(cat "$KANON")

if [ "$AKTUELL" = "$NEU" ]; then echo "$host: crontab bereits identisch mit $KANON"; exit 0; fi

echo "Unterschiede ($host; < aktuell / > $KANON):"
diff <(printf '%s\n' "$AKTUELL") <(printf '%s\n' "$NEU") | cut -c1-230

if [ -z "$ANWENDEN" ]; then echo "(Anzeigemodus: nichts geschrieben. Zum Anwenden: --anwenden)"; exit 0; fi

BD=/root/neuserver/private_backups; [ -d /root/neuserver ] && mkdir -p "$BD" || BD=/root
B="$BD/crontab_${host}_vor_uebernahme_$(date +%Y%m%d_%H%M%S).txt"
printf '%s\n' "$AKTUELL" > "$B" && echo "Sicherung: $B"

if [ -n "$HOSTUEBER" ]; then
  echo "(Testmodus -h: es wird NICHT wirklich 'crontab' aufgerufen)"; exit 0
fi
crontab "$KANON" && echo "crontab installiert."
KONTROLLE=$(crontab -l 2>/dev/null)
if [ "$KONTROLLE" = "$NEU" ]; then
  echo "Kontrolle OK: crontab entspricht jetzt $KANON"
else
  echo "WARNUNG: crontab weicht nach der Installation noch ab - bitte pruefen"; exit 1
fi
