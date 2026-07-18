#!/bin/bash
# zuutf.sh - benennt Dateien direkt unter /DATA/Patientendokumente (nicht in
# Unterverzeichnissen) um, deren Namen die Bytes \xb4 (´), \xfc (ü in
# Latin-1) oder \xc3 (erstes Byte eines UTF-8-Umlauts) enthalten: \xb4 wird
# zu Leerzeichen, \xfc zu "ü", \xc3 zu ".". Damit werden falsch codierte
# (Latin-1 statt UTF-8 bzw. Mojibake-) Dateinamen grob bereinigt. Aufruf ohne
# Parameter; Fehler beim Umbenennen (z.B. Ziel existiert schon) werden
# stillschweigend verschluckt (2>/dev/null).
find /DATA/Patientendokumente -maxdepth 1 -type f -print0|while IFS= read -r -d '' file; do mv "$file" "$(echo $file|sed 'y/\xb4\xfc\xc3/\x20ü./')" 2>/dev/null; done;
