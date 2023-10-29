#/bin/bash
# dann Angleichen des Datums, letztes Vorkommen
for A in *.pdf; do pdftotext "$A"; touch -r "$A" "$(echo $A|sed 's/\(.*\)pdf/\1txt/')"; done
