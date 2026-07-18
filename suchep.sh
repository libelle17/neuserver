#!/bin/bash
# suchep.sh - wie suche.sh, aber durchsucht statt eines übergebenen
# Verzeichnisses alle Verzeichnisse in $PATH ("p" = PATH) nach Dateien mit
# Namensmuster $1, deren Inhalt $2 enthält - deshalb hier nur zwei statt drei
# Parameter. Aufruf: suchep.sh <Dateimuster> <Suchstring>. Variante mit
# vi-Öffnen statt Auflisten: suchepv.sh. Enthält denselben toten
# "if false; then...fi"-Block wie suche.sh.
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
find $(echo $PATH|tr ':' ' ') -type f -iname "$1" -print0 | /usr/bin/xargs -0 -r grep -il """$2""" --null | /usr/bin/xargs -0 -r ls -l --time-style=full-iso | sort -nk 6,7
