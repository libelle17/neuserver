#!/bin/bash
# suchexdev.sh - inhaltlich identisch zu suchehier.sh (Suche unter $1,
# bleibt im selben Dateisystem, -xdev, Dateimuster $2, Suchstring $3,
# Ausgabe sortiert nach Änderungsdatum); im Unterschied zu suchehier.sh ist
# hier die Such-Ankündigung auskommentiert, das Skript bleibt also stumm bis
# zur Ergebnisliste. Aufruf: suchexdev.sh <Verzeichnis> <Dateimuster>
# <Suchstring>.
# echo "Suche in $1 nach $2, mit enthaltenem """$3"""
find "$1" -xdev -type f -iname "$2" -print0 | /usr/bin/xargs -0 -r grep -il """$3""" --null | /usr/bin/xargs -0 -r ls -l --time-style=full-iso | sort -nk 6,7
