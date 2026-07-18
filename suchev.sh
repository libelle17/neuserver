#!/bin/bash
# suchev.sh - wie suche.sh (Verzeichnis $1, Dateimuster $2, Suchstring $3),
# öffnet die Treffer aber direkt in vi als Tabs (-p), im ersten Treffer an
# der Fundstelle des Suchstrings positioniert, statt sie nur aufzulisten.
# Aufruf: suchev.sh <Verzeichnis> <Dateimuster> <Suchstring>.
#echo "Suche in $1 nach $2, mit enthaltenem """$3""""
vi +/"""$3""" `find "$1" -type f -iname "$2" -print0 | /usr/bin/xargs -0 -r grep -il """$3""" --null | /usr/bin/xargs -0 -r ls` -p
