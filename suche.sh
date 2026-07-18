#!/bin/bash
# suche.sh - sucht rekursiv unter Verzeichnis $1 nach Dateien mit Namensmuster
# $2 (z.B. "*.txt", ohne Beachtung von Groß-/Kleinschreibung), deren Inhalt
# den String $3 enthält (ebenfalls ohne Groß-/Kleinschreibung), und listet die
# Treffer sortiert nach Änderungsdatum auf (ls -l --time-style=full-iso |
# sort -nk 6,7). Aufruf: suche.sh <Verzeichnis> <Dateimuster> <Suchstring>.
# Varianten: suche5.sh (nur letzte 5 Tage), suchehier.sh/suchexdev.sh (bleibt
# im selben Dateisystem, -xdev), suchek.sh (kürzere Ausgabe ohne Sortierung),
# suchev.sh (öffnet Treffer in vi statt sie nur zu listen), suchep.sh/
# suchepv.sh (sucht stattdessen in $PATH statt in einem Verzeichnis).
# Der "if false; then...fi"-Block unten ist toter Code (nie ausgeführter
# älterer Anlauf derselben Logik) und wird nie erreicht.
#echo "Suche in $1 nach $2, mit enthaltenem """$3""""
if false; then
erg=$(find "$1" -type f -iname "$2" -print0 | /usr/bin/xargs -0 grep -il """$3""" --null)
if test -z "$erg"; then
 echo "nichts gefunden"
else
 echo Ergebnis:$erg:
 echo "$erg" | /usr/bin/xargs -0 ls -l --time-style=full-iso | sort -nk 6,7 # geht nicht, echo schluckt vermutlich die 0er
fi
fi
find "$1" -type f -iname "$2" -print0 | /usr/bin/xargs -0 -r grep -il """$3""" --null | /usr/bin/xargs -0 -r ls -l --time-style=full-iso | sort -nk 6,7
