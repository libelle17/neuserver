#!/bin/bash
# suchehier.sh - wie suche.sh, aber bleibt beim Durchsuchen im selben
# Dateisystem wie $1 (-xdev, "hier" = überschreitet keine Mountpunkte, nützlich
# um z.B. mit "/" als Verzeichnis nicht auch alle gemounteten Netzlaufwerke zu
# durchsuchen). Aufruf: suchehier.sh <Verzeichnis> <Dateimuster> <Suchstring>.
# Fast identisch zu suchexdev.sh, das nur die Such-Ankündigung nicht ausgibt.
echo "Suche in $1 nach $2, mit enthaltenem """$3""""
find "$1" -xdev -type f -iname "$2" -print0 | /usr/bin/xargs -0 -r grep -il """$3""" --null | /usr/bin/xargs -0 -r ls -l --time-style=full-iso | sort -nk 6,7
