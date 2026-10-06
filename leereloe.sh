#!/bin/bash
# leereloe.sh - loescht endgueltig, was die stutze*.sh-Rotation (instutz.sh) vor mehr als $TAGE Tagen in die
# Durchsichtsordner /DATA/sqlloe, /DATA/DBBackloe, /DATA/TMBackloe und /DATA/TMExportloe verschoben hat.
#
# Anlass (6.10.2026): instutz.sh lief seit ca. 5/2026 nicht mehr (chronyd -q scheiterte am laufenden Dienst);
# nach der Reparatur landeten ~590 GB in den *loe-Ordnern, und nichts leerte sie je wieder.
#
# Alter nach ctime, nicht mtime: mv erhaelt die mtime (= Dumpdatum, oft Monate alt), setzt aber die ctime auf den
# Zeitpunkt des Verschiebens (auf /DATA, ext4, am 6.10.2026 geprueft). Aendert spaeter etwas die Metadaten
# (chmod/chown), beginnt die Frist neu - es wird also hoechstens spaeter, nie frueher geloescht.
# Nur Dateien direkt im jeweiligen Ordner (keine Unterverzeichnisse), nie *Schutzdatei* (Ransomware-Koeder).
# /mnt/wser/mosich/loe (stutzMOSich.sh) bleibt aussen vor: Windows-Share, ctime dort nicht verlaesslich.
#
# Aufruf: leereloe.sh [-n]    -n: nur anzeigen, was geloescht wuerde
# Einstellung per Umgebung: LOE_TAGE (30); Testhilfe: LOE_VZE (Ordnerliste statt der vier obigen)
TAGE=${LOE_TAGE:-30}
VZE=${LOE_VZE:-"/DATA/sqlloe /DATA/DBBackloe /DATA/TMBackloe /DATA/TMExportloe"}
NUR=; case "$1" in -n) NUR=1;; "") ;; *) sed -n '2,15p' "$0"; exit 1;; esac
mountpoint -q /DATA || exit 0
for v in $VZE; do
  [ -d "$v" ] || continue
  n=0; s=0
  while IFS=$'\t' read -r gr pf; do
    [ -n "$pf" ] || continue
    if [ "$NUR" ]; then printf 'wuerde loeschen: %s\n' "$pf"
    else rm -f -- "$pf" && printf 'geloescht: %s\n' "$pf" || continue; fi
    n=$((n+1)); s=$((s+gr))
  done < <(find "$v" -maxdepth 1 -type f -ctime +"$TAGE" ! -iname '*schutzdatei*' -printf '%s\t%p\n')
  [ "$n" -gt 0 ] && printf '%s %s: %d Dateien, %s GB %s (aelter als %d Tage im Ordner)\n' "$(date '+%F %T')" "$v" "$n" \
    "$(LC_ALL=C awk -v b="$s" 'BEGIN{printf "%.1f", b/1e9}')" "$([ "$NUR" ] && echo 'wuerden geloescht' || echo geloescht)" "$TAGE"
done
exit 0
