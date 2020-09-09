#!/bin/sh
VZ="/DATA/eigene Dateien/Programmierung/"
DATEI="${VZ}/AcKnack/AcKnack.ex"
test -f "$DATEI"e || cp -ai "$DATEI"_ "$DATEI"e
DATEI="${VZ}/BDTkompr/BDTkompr.ex"
test -f "$DATEI"e || cp -ai "$DATEI"_ "$DATEI"e
