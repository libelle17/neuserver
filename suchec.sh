#!/bin/bash
# suchec.sh - sucht unter Verzeichnis $1 (bleibt im selben Dateisystem, -xdev)
# in C/C++-Quell-/Header-Dateien (*.h, *.c, *.hpp, *.cpp) nach Inhalt $2 und
# öffnet alle Treffer direkt in vi als Tabs (-p), im ersten Treffer bereits an
# der Fundstelle positioniert (vi +/"$2"). Aufruf: suchec.sh <Verzeichnis>
# <Suchstring>.
#echo "Suche in $1 nach *.h, *.c, *.hpp oder *.cpp, mit enthaltenem """$2""""
vi +/"""$2""" `find "$1" -xdev -type f \( -iname "*.h" -o -iname "*.c" -o -iname "*.hpp" -o -iname "*.cpp" \) -print0 | /usr/bin/xargs -0 -r grep -il """$2""" --null | /usr/bin/xargs -0 -r ls` -p
