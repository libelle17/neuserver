#!/bin/sh
# wiederherstell.sh - stellt zwei selbstgeschriebene Windows-Programme
# (AcKnack, BDTkompr) wieder her, indem die ohne ".exe"-Endung abgelegte
# Vorlage ("...ex_") auf ".exe" kopiert wird - aber nur, wenn die .exe-Datei
# noch nicht existiert. Der Umweg über einen Nicht-".exe"-Namen dient
# vermutlich dazu, dass die Datei bei der Übertragung/Lagerung nicht von
# Virenscannern als ausführbare Datei blockiert/gescannt wird. Aufruf ohne
# Parameter.
VZ="/DATA/eigene Dateien/Programmierung/"
DATEI="${VZ}/AcKnack/AcKnack.ex"
test -f "$DATEI"e || cp -ai "$DATEI"_ "$DATEI"e
DATEI="${VZ}/BDTkompr/BDTkompr.ex"
test -f "$DATEI"e || cp -ai "$DATEI"_ "$DATEI"e
