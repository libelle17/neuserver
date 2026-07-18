#/bin/bash
# vgl12.sh - vergleicht Dateien in entsprechenden Unterpfaden von $1 und $2:
# ermittelt rekursiv alle relativen Pfade unter $1 und ruft für jeden
# denselben relativen Pfad unter $2 "fc" mit beiden Dateien auf, meldet bei
# Ungleichheit "<Pfad> ungleich". Aufruf: vgl12.sh <Verzeichnis1>
# <Verzeichnis2>, z.B. vgl12.sh "/DATA/down/1" "/DATA/down/2".
# ACHTUNG: "fc" ist auf diesem System nur das bash-history-Kommando "fc",
# kein externes Datei-Vergleichsprogramm (kein /usr/bin/fc installiert) -
# der Vergleich hier dürfte deshalb nicht wie beabsichtigt funktionieren,
# vermutlich war ursprünglich "diff" oder "cmp" gemeint.
if test $# -ne 2; then
  echo "$0: Aufruf z.B.: 'W=/DATA/down; $0 \"\$W/1\" \"\$W/2\"'"
else
  Q=$1;
  Z=$2;
  find "$Q" -printf "%P\0"| while IFS= read -r -d '' line; do
    fc "$Q/$line" "$Z/$line"||echo $line ungleich
  done;
fi;
