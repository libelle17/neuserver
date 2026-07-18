# copydat.sh - synchronisiert /DATA nach /DAT3 (Kopie auf einer zweiten
# lokalen Platte) per dorsync.sh --delete, mit Ausschlüssen für Papierkorb,
# diverse Backup-/Auslagerungs-Verzeichnisse und *.tmp-Dateien. Läuft nur,
# wenn nicht schon ein passender dorsync.sh-Prozess für dasselbe Ziel aktiv
# ist und beide Pfade tatsächlich gemountet sind (verhindert Vollschreiben
# von "/", falls ein Mount fehlt). Aufruf ohne Parameter; kein Shebang - wird
# über "sh copydat.sh" bzw. per Cron mit vorangestelltem Interpreter benutzt.
# Hinweis: "--exclued" (statt "--exclude") vor "/TMBackloe***" ist vermutlich
# ein Tippfehler; dieser eine Ausschluss greift dadurch ggf. nicht wie gedacht.
Q=/DATA;Z=/DAT3;pgrep -c -f "dorsync.sh.* $Z" >/dev/null||{ mountpoint -q "$Q"&&mountpoint -q "$Z"&&/root/bin/dorsync.sh --delete --exclude "/ausgelagert***" --exclude "/down***" --exclude "/Oberanger***" --exclude "/Papierkorb***" --exclude "/DBBackloe***" --exclued "/TMBackloe***" --exclude "/sqlloe***" --exclude \"*.tmp*\" "$Q/" "$Z";}
