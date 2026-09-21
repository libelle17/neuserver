#!/bin/bash
# shziel_vorschau.sh - zeigt VOR "make shziel", welche Dateien aus "ziele" es kopieren wuerde (nur lesend, aendert nichts).
#
# "make shziel" installiert jede in "ziele" stehende Datei, die im Repo neuer ist als die installierte (und sich im Inhalt
# unterscheidet), in das jeweilige [/ziel/verzeichnis] - also auch fremde, noch nicht ausgerollte Aenderungen. Diese Vorschau
# rechnet genauso wie das Makefile (cmp; Zeitstempel der Datei, ersatzweise der letzte Git-Commit, falls dieser aelter ist)
# und listet, was kaeme. Ausserdem: Eintraege in "ziele", zu denen es im Repo keine Datei gibt.
#
# Aufruf:  shziel_vorschau.sh [Repo-Verzeichnis]      (Vorgabe: /root/neuserver)
# Ergebnis: Zeile je zu kopierender Datei, am Ende "=> n Datei(en) auf <Rechner>". Rueckgabe 0; 1 nur, wenn das Verzeichnis kein Repo mit ziele ist.
R=${1:-/root/neuserver}
cd "$R" 2>/dev/null && [ -f ziele ] || { echo "kein Repo mit ziele in $R"; exit 1; }
Z=; n=0; fehlt=
for D in $(cat ziele); do
  case $D in \[*\]) Z=$(printf %s "$D" | sed 's/^\[//;s/\]$//;s:/$::'); continue;; esac
  [ -n "$Z" ] || continue
  [ -f "$D" ] || { fehlt="$fehlt $D"; continue; }
  cmp -s -- "$D" "$Z/$D" && continue
  AHr=$(stat -c %Y "$D"); APC=0; [ -f "$Z/$D" ] && APC=$(stat -c %Y "$Z/$D")
  AGit=0; command -v git >/dev/null 2>&1 && AGit=$(git log -1 --format=%at -- "$D" 2>/dev/null); AGit=${AGit:-0}
  [ "$AGit" -ne 0 ] && [ "$AGit" -lt "$AHr" ] && AHr=$AGit
  if [ "$AHr" -gt "$APC" ]; then
    echo "wuerde kopieren: $D -> $Z/   (Repo $(date -d "@$AHr" '+%F %T'), Ziel $([ "$APC" -gt 0 ] && date -d "@$APC" '+%F %T' || echo fehlt))"
    n=$((n+1))
  fi
done
[ -n "$fehlt" ] && echo "in ziele, aber nicht im Repo:$fehlt"
echo "=> $n Datei(en) auf $(hostname)"
