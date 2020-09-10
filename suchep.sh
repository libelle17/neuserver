#!/bin/bash
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
