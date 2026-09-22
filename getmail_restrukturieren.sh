#!/bin/bash
# getmail_restrukturieren.sh - ersetzt den Symlink /root/.getmail -> "." durch ein ECHTES
# Verzeichnis, das nur die getmail-Konfig- und Statusdateien enthaelt.
#
# Hintergrund (22.9.2026): /root/.getmail war absichtlich ein Symlink auf "." (= /root), weil
# die *rc-Dateien historisch direkt in /root liegen und getmail sie per Vorgabe unter
# ~/.getmail/<name>rc sucht. Das hatte einen Nebeneffekt: jede rsync-Kopie von ".getmail/"
# kopiert(e) potenziell GANZ /root (der urspruengliche Fehler, der zum Verlust von
# /root/.ssh/authorized_keys auf den Reservern fuehrte, s. Commit 5d50714). Der dortige Fix
# schraenkt die rsync-Filter beim KOPIEREN ein, kann aber nicht erzwingen, dass ein Client sie
# tatsaechlich mitschickt (rsync-Filter werden ueber das Protokoll uebertragen, nicht als
# Kommandozeile - ein Wrapper kann sie nicht sehen, s. bupull_wrapper_streng.sh Kopfkommentar).
# SAUBERER Fix: die Dateien tatsaechlich dorthin verschieben, wo getmail sie per Vorgabe ohnehin
# erwartet (~/.getmail/), statt es per Symlink vorzutaeuschen. Damit ist /root/.getmail danach
# ein normales, kleines Verzeichnis, dessen kompletter Inhalt unbedenklich kopierbar ist.
#
# BETROFFENE FREMDE SKRIPTE (nur zur Information, nicht automatisch geaendert): rett.sh (Notfall-
# Rettungskopie), copyseag.sh, copyseagg.sh, copytoshz.sh, copytosh.sh, copyverb.sh, copywd.sh
# listen "/root/.getmail" explizit als rsync-Quelle neben anderen Einzeldateien. Nach dieser
# Restrukturierung kopieren sie dort nur noch die getmail-Dateien statt (wie bisher, ueber den
# Symlink) implizit ganz /root - das war vermutlich ohnehin nie beabsichtigt, da diese Skripte
# /root/bin und die uebrigen wichtigen Dateien schon einzeln auflisten.
#
# Aufruf: getmail_restrukturieren.sh              zeigt nur, was getan wuerde (nichts wird geschrieben)
#         getmail_restrukturieren.sh --anwenden    fuehrt es aus (mit Sicherung vorher)
#         getmail_restrukturieren.sh --pruefen     nur die --dump-Kontrolle laufen lassen (nach --anwenden)
set -u
WURZEL=/root
ZIEL="$WURZEL/.getmail"
SICHERUNG_DIR="$WURZEL/neuserver/private_backups"
# Die derzeit AKTIVEN rc-Dateien (aus getmail_alle.sh/getmail_gmx7.sh/crontab abgeleitet, 22.9.2026).
# Bewusst eine feste Liste, kein "*rc"-Glob: /root/vimrc endet zufaellig auch auf "rc", hat aber
# nichts mit getmail zu tun und darf NICHT verschoben werden.
RC_DATEIEN="buchhrc freenetrc gmx1rc gmx2rc gmx3rc gmx4rc gmx5rc gmx6rc gmx7rc googlerc google2rc mnetrc web_rc webrc"
# Nicht mehr aktiv referenziert (nur in einer auskommentierten crontab-Zeile), werden NICHT
# automatisch verschoben, damit nichts Unerwartetes passiert - Kontrolle zeigt sie an:
RC_UNSICHER="lrzrc vrwebrc"

pruefen() {
  echo "--- Kontrolle: getmail --dump je rc-Datei (nur Konfig-Test, keine Verbindung) ---"
  local fehler=0
  for n in $RC_DATEIEN; do
    if timeout 8 getmail --dump -r"$n" >/dev/null 2>&1; then
      echo "  $n: OK"
    else
      echo "  $n: FEHLER (getmail --dump -r$n liefert einen Fehler)"; fehler=1
    fi
  done
  [ "$fehler" = 0 ] && echo "Alle rc-Dateien liefern eine gueltige Konfiguration." || echo "ACHTUNG: mindestens eine rc-Datei liefert keine gueltige Konfiguration mehr."
  return $fehler
}

if [ "${1:-}" = --pruefen ]; then pruefen; exit $?; fi

echo "=== Ist-Zustand ==="
ls -la "$ZIEL" 2>&1 | head -1
if [ -L "$ZIEL" ]; then
  ziel_von=$(readlink -- "$ZIEL")
  echo "$ZIEL ist ein Symlink auf \"$ziel_von\""
  if [ "$ziel_von" != "." ]; then echo "Unerwartet (nicht \".\") - abgebrochen, bitte von Hand pruefen."; exit 1; fi
elif [ -d "$ZIEL" ]; then
  echo "$ZIEL ist bereits ein echtes Verzeichnis - vermutlich schon erledigt."
  pruefen; exit $?
else
  echo "$ZIEL existiert nicht - unerwarteter Zustand, abgebrochen."; exit 1
fi

echo
echo "=== Zu verschiebende Dateien ==="
n_rc=0; n_om=0
for n in $RC_DATEIEN; do [ -f "$WURZEL/$n" ] && n_rc=$((n_rc+1)); done
n_om=$(find "$WURZEL" -maxdepth 1 -name 'oldmail-*' -type f 2>/dev/null | wc -l)
echo "rc-Dateien (fest gelistet): $n_rc von $(echo $RC_DATEIEN | wc -w)"
echo "oldmail-* Dateien (Muster): $n_om"
for n in $RC_UNSICHER; do [ -f "$WURZEL/$n" ] && echo "NICHT verschoben (nicht mehr aktiv referenziert, bitte von Hand pruefen): $n"; done
echo "NICHT verschoben (kein getmail-Bezug, nur zufaellig gleiche Endung): vimrc"

if [ "${1:-}" != --anwenden ]; then
  echo
  echo "(Anzeigemodus: nichts geschrieben. Zum Ausfuehren: --anwenden)"
  exit 0
fi

echo
echo "=== Sicherung ==="
mkdir -p "$SICHERUNG_DIR"
B="$SICHERUNG_DIR/getmail_vor_restrukturierung_$(date +%Y%m%d_%H%M%S).tar"
( cd "$WURZEL" && tar -cf "$B" $RC_DATEIEN oldmail-* 2>/dev/null )
if [ -s "$B" ]; then echo "Sicherung: $B ($(du -h "$B" | cut -f1))"; else echo "Sicherung fehlgeschlagen - abgebrochen"; exit 1; fi

echo
echo "=== Umbau ==="
rm -- "$ZIEL" || { echo "Symlink konnte nicht entfernt werden - abgebrochen"; exit 1; }
mkdir -m 700 -- "$ZIEL" || { echo "mkdir fehlgeschlagen - Symlink NICHT wiederhergestellt, bitte von Hand: ln -s . $ZIEL"; exit 1; }
verschoben=0
for n in $RC_DATEIEN; do
  [ -f "$WURZEL/$n" ] && { mv -- "$WURZEL/$n" "$ZIEL/$n" && verschoben=$((verschoben+1)); }
done
for f in "$WURZEL"/oldmail-*; do
  [ -f "$f" ] && { mv -- "$f" "$ZIEL/" && verschoben=$((verschoben+1)); }
done
chown -R root:root "$ZIEL"; chmod 700 "$ZIEL"; find "$ZIEL" -type f -exec chmod 600 {} \;
echo "$verschoben Dateien nach $ZIEL verschoben."

echo
pruefen
erg=$?
if [ "$erg" != 0 ]; then
  echo
  echo "!!! Kontrolle fehlgeschlagen. Wiederherstellung aus der Sicherung:"
  echo "    rm -rf $ZIEL && mkdir $ZIEL.leer 2>/dev/null; rmdir $ZIEL 2>/dev/null; ln -s . $ZIEL; tar -xf $B -C $WURZEL"
fi
exit $erg
