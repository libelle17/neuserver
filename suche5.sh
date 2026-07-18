#!/bin/bash
# suche5.sh - wie suche.sh, aber zusätzlich auf Dateien beschränkt, die in
# den letzten 5 Tagen geändert wurden (-mtime -5). Aufruf: suche5.sh
# <Verzeichnis> <Dateimuster> <Suchstring>. Anders als suche.sh gibt dieses
# Skript die Suchanfrage vorab per echo aus (Zeile unten nicht auskommentiert).
echo "Suche in $1 nach $2, mit enthaltenem """$3""""
find "$1" -type f -mtime -5 -iname "$2" -print0 | /usr/bin/xargs -0 -r grep -il """$3""" --null | /usr/bin/xargs -0 -r ls -l --time-style=full-iso | sort -nk 6,7
