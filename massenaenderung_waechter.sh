#!/bin/bash
# Einfache Ransomware-Fruehwarnung, unabhaengig von den Backup-Zeitfenstern
# (die der Schutzdatei-Mechanismus in bugem.sh abdeckt): zaehlt, wie viele
# Dateien sich in den letzten $MINUTEN Minuten unter /DATA geaendert haben,
# und alarmiert per Mail bei Ueberschreiten von $SCHWELLE.
#
# /DATA/rett und /DATA/Papierkorb sind bewusst ausgenommen: interne
# Backup-Spiegelung bzw. Papierkorb erzeugen normale, haeufige Aenderungen,
# die sonst die Erkennung unbrauchbar machen wuerden (Basiswert am 12.7.2026
# ermittelt: ca. 3800 Aenderungen/15min INKL. dieser zwei Verzeichnisse,
# aber nur ca. 10 AUSSERHALB davon).
#
# Per Cron alle 15 Minuten aufrufen (Aufrufintervall = $MINUTEN).

MINUTEN=15
SCHWELLE=300
COOLDOWN_MIN=60
MARKER=/root/.massenaenderung_waechter_letzter_alarm
EMPFAENGER="diabetologie@dachau-mail.de gerald.schade@gmx.de geraldschade@gmx.de"

[ -d /DATA ] || exit 0
mountpoint -q /DATA 2>/dev/null || exit 0

ANZAHL=$(find /DATA -mmin -$MINUTEN -type f \
  -not -path "/DATA/rett/*" \
  -not -path "/DATA/Papierkorb/*" \
  2>/dev/null | wc -l)

if [ "$ANZAHL" -gt "$SCHWELLE" ]; then
  # Cooldown pruefen, um nicht bei jedem Lauf (alle 15 Min.) erneut zu alarmieren,
  # solange die Verschluesselung/Massenaenderung weiterhin im Gange ist:
  if [ -f "$MARKER" ]; then
    ALTER_MIN=$(( ( $(date +%s) - $(stat -c %Y "$MARKER") ) / 60 ))
  else
    ALTER_MIN=999999
  fi
  if [ "$ALTER_MIN" -ge "$COOLDOWN_MIN" ]; then
    touch "$MARKER"
    which mail >/dev/null 2>&1 && \
    printf "Achtung,\n\nunter /DATA auf %s wurden in den letzten %s Minuten %s Dateien geaendert (Schwelle: %s), ausserhalb der bekannten Haushaltsverzeichnisse rett/ und Papierkorb/.\n\nDas kann ein Hinweis auf eine laufende Ransomware-Verschluesselung sein - bitte umgehend pruefen!\n\nGesendet: %s\n" \
      "$(hostname)" "$MINUTEN" "$ANZAHL" "$SCHWELLE" "$(date '+%d.%m.%Y %H:%M:%S')" \
      | mail -s "ACHTUNG: Massenaenderung unter /DATA auf $(hostname) - moeglicher Ransomware-Verdacht" $EMPFAENGER
  fi
fi
