#!/bin/bash
# dokrechte.sh - haelt /DATA/Patientendokumente fuer DokimpKurz.au3 (Dokumentimport ueber
# Samba, p:\) bearbeitbar: Eigentuemer sturm:praxis und Rechte 770 fuer Dateien und
# Verzeichnisse. Hintergrund: Dateien/Verzeichnisse, die root (v.a. vmparse2, speichert
# E-Mails in dok/<pat_id>/), vsftp (--wxrw-rw-) oder schade (schade:schade 744) anlegen,
# lassen sich ueber Samba oft nicht verschieben/umbenennen; dann scheitert der Import.
# Aendert nur, was abweicht (find-Bedingungen), daher billig, solange alles stimmt.
#
# Aufruf: dokrechte.sh           schnell (~1 s): oberste Ebene (Importquelle) + dok/ komplett
#                                + eingelesen/ und seine Jahresverzeichnisse (ohne deren Inhalt)
#         dokrechte.sh --voll    ganzer Baum (~2 Mio. Dateien, ~15 s, meist Plattenzugriff)
#         dokrechte.sh -n [...]  nur zaehlen, nichts aendern
B=/DATA/Patientendokumente
VOLL=; TROCKEN=
for a; do
  case "$a" in
    --voll) VOLL=1;;
    -n) TROCKEN=1;;
    *) sed -n '2,14p' "$0"; exit 1;;
  esac
done
mountpoint -q /DATA && [ -d "$B/dok" ] || exit 0
exec 9>/run/dokrechte.lock
flock -n 9 || exit 0   # voriger Lauf (z.B. --voll) noch aktiv

# $@ = find-Startpunkt(e) und Tiefenoptionen; Symlinks bleiben unberuehrt (chmod folgt ihnen)
fix() {
  local nown nmod
  if [ "$TROCKEN" ]; then
    nown=$(find "$@" ! -type l \( ! -user sturm -o ! -group praxis \) -printf . | wc -c)
    nmod=$(find "$@" ! -type l ! -perm 770 -printf . | wc -c)
  else
    nown=$(find "$@" ! -type l \( ! -user sturm -o ! -group praxis \) -exec chown sturm:praxis {} + -printf . | wc -c)
    nmod=$(find "$@" ! -type l ! -perm 770 -exec chmod 770 {} + -printf . | wc -c)
  fi
  [ "$nown$nmod" = 00 ] || echo "$(date '+%F %T') dokrechte${TROCKEN:+ (nur gezaehlt)}: $*: chown $nown, chmod $nmod"
}

if [ "$VOLL" ]; then
  fix "$B"
else
  fix "$B" -maxdepth 1
  fix "$B/dok"
  fix "$B/eingelesen" -maxdepth 1
fi
