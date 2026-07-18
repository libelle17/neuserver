#!/bin/bash
# suchepv.sh - wie suchep.sh (durchsucht $PATH nach Dateimuster $1 mit
# Inhalt $2), öffnet die Treffer aber direkt in vi als Tabs (-p), im ersten
# Treffer an der Fundstelle positioniert - "pv" = PATH + vi. Aufruf:
# suchepv.sh <Dateimuster> <Suchstring>.
#echo "Suche in $1 nach $2, mit enthaltenem """$3""""
vi +/"""$2""" `find $(echo $PATH|tr ':' ' ') -type f -iname "$1" -print0 | /usr/bin/xargs -0 -r grep -il """$2""" --null | /usr/bin/xargs -0 -r ls` -p
