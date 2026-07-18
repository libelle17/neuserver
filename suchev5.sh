#!/bin/bash
# suchev5.sh - wie suchev.sh, aber zusätzlich auf Dateien beschränkt, die in
# den letzten 5 Tagen geändert wurden (-mtime -5); listet die Fundstellen
# intern mit "ls -Q" (Dateinamen in Anführungszeichen) statt schlichtem "ls".
# Aufruf: suchev5.sh <Verzeichnis> <Dateimuster> <Suchstring>.
#echo "Suche in $1 nach $2, mit enthaltenem """$3""""
vi +/"""$3""" `find "$1" -type f -mtime -5 -iname "$2" -print0 | xargs -0 -r grep -il """$3""" --null | xargs -0 -r ls -Q` -p
