#/bin/bash
# Vergleicht Dateien in entsprechenden Unterpfaden von $1 und $2
if test $# -ne 2; then
  echo "$0: Aufruf z.B.: 'W=/DATA/down; $0 \"\$W/1\" \"\$W/2\"'"
else
  Q=$1;
  Z=$2;
  find "$Q" -printf "%P\0"| while IFS= read -r -d '' line; do
    fc "$Q/$line" "$Z/$line"||echo $line ungleich
  done;
fi;
