#!/bin/sh
# treesize.sh - listet die direkten Unterverzeichnisse/Dateien von $1 (bleibt
# im selben Dateisystem, -x) mit ihrer Größe auf, absteigend sortiert, und
# formatiert die Byte-Angaben von "du -k" lesbar in KB/MB/GB/TB um (eigene
# awk-Umrechnung statt "du -h", damit die Sortierung nach der reinen
# Zahlengröße vorher noch numerisch korrekt bleibt). Aufruf: treesize.sh
# <Verzeichnis>.
du "$1" -x -k --max-depth=1 | sort -nr | awk '
    BEGIN {
	split("KB,MB,GB,TB", Units, ",");
    }
    {
       u = 1;
       while ($1 >= 1024) {
         $1 = $1 / 1024;
         u += 1;
       }
       $1 = sprintf("%.lf %s", $1, Units[u]);
       print $0;
    }
   '
