#/bin/bash
# pdftotxte.sh - wandelt alle *.pdf-Dateien im aktuellen Verzeichnis per
# pdftotext in gleichnamige .txt-Dateien um und setzt danach deren
# Änderungszeitstempel auf den der jeweiligen PDF (touch -r), damit die
# Textdatei im Dateimanager/bei "-newer"-Vergleichen dasselbe Datum trägt wie
# die PDF, aus der sie stammt. Aufruf ohne Parameter, im PDF-Verzeichnis.
for A in *.pdf; do pdftotext "$A"; touch -r "$A" "$(echo $A|sed 's/\(.*\)pdf/\1txt/')"; done
