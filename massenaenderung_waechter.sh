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
#
# Zusaetzlich zur Einzelintervall-Schwelle $SCHWELLE alarmiert das Script auch,
# wenn zwei aufeinanderfolgende Intervalle (also zwei Cron-Laeufe in Folge)
# jeweils mehr als $SCHWELLE_FOLGE Aenderungen zeigen - das faengt einen
# langsameren, aber anhaltenden Verschluesselungsvorgang ab, der die hohe
# Einzelschwelle allein nicht reisst. Der Zustand (ob der vorige Lauf schon
# ueber $SCHWELLE_FOLGE lag) wird ueber $FOLGE_MARKER zwischen den Laeufen
# gemerkt.

MINUTEN=15
SCHWELLE=20000
SCHWELLE_FOLGE=1200
COOLDOWN_MIN=60
MARKER=/root/.massenaenderung_waechter_letzter_alarm
FOLGE_MARKER=/root/.massenaenderung_waechter_folge_ueberschritten
EMPFAENGER="diabetologie@dachau-mail.de gerald.schade@gmx.de geraldschade@gmx.de"

[ -d /DATA ] || exit 0
mountpoint -q /DATA 2>/dev/null || exit 0

ANZAHL=$(find /DATA -mmin -$MINUTEN -type f \
  -not -path "/DATA/rett/*" \
  -not -path "/DATA/Papierkorb/*" \
  2>/dev/null | wc -l)

ALARM=0
GRUND=""

if [ "$ANZAHL" -gt "$SCHWELLE" ]; then
  ALARM=1
  GRUND="Einzelintervall ueberschreitet Schwelle ($ANZAHL > $SCHWELLE)"
fi

if [ "$ANZAHL" -gt "$SCHWELLE_FOLGE" ]; then
  if [ -f "$FOLGE_MARKER" ]; then
    ALARM=1
    [ -n "$GRUND" ] && GRUND="$GRUND; "
    GRUND="${GRUND}zwei aufeinanderfolgende Intervalle ueber $SCHWELLE_FOLGE ($ANZAHL im aktuellen Lauf)"
  fi
  touch "$FOLGE_MARKER"
else
  rm -f "$FOLGE_MARKER"
fi

if [ "$ALARM" -eq 1 ]; then
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
    printf "Achtung,\n\nunter /DATA auf %s wurden in den letzten %s Minuten %s Dateien geaendert, ausserhalb der bekannten Haushaltsverzeichnisse rett/ und Papierkorb/.\n\nGrund: %s\n\nDas kann ein Hinweis auf eine laufende Ransomware-Verschluesselung sein - bitte umgehend pruefen!\n\nGesendet: %s\n" \
      "$(hostname)" "$MINUTEN" "$ANZAHL" "$GRUND" "$(date '+%d.%m.%Y %H:%M:%S')" \
      | mail -s "ACHTUNG: Massenaenderung unter /DATA auf $(hostname) - moeglicher Ransomware-Verdacht" $EMPFAENGER
  fi
fi
