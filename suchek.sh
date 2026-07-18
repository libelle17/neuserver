#!/bin/bash
# suchek.sh - wie suche.sh, aber "kurz": listet Treffer nur mit einfachem
# "ls" (Dateinamen ohne Datum/Größe/Sortierung) statt der ausführlichen,
# nach Änderungsdatum sortierten Liste. Aufruf: suchek.sh <Verzeichnis>
# <Dateimuster> <Suchstring>.
#echo "Suche in $1 nach $2, mit enthaltenem """$3""""
find "$1" -type f -iname "$2" -print0 | xargs -0 -r grep -il """$3""" --null | xargs -0 -r ls
