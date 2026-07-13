#!/bin/bash
# Loescht doppelte "UEFI: SanDisk SDSSDXPS240G, Partition 1"-Booteintraege,
# die ein Firmware-Bug auf linux7 bei (fast) jedem Reboot neu anlegt (Diagnose
# 13.7.2026: 430 Duplikate angesammelt). Der vorhandene "UEFI OS"-Eintrag
# zeigt auf denselben Fallback-Pfad (\EFI\BOOT\BOOTX64.EFI), daher werden ALLE
# Duplikate geloescht statt einen davon zu erhalten.

NAME="UEFI: SanDisk SDSSDXPS240G, Partition 1"
LOG=/var/log/efibootmgr_bereinigen.log
BACKUPDIR=/root

command -v efibootmgr >/dev/null 2>&1 || exit 0

ids=$(efibootmgr | grep -F "$NAME" | sed -nE 's/^Boot([0-9A-F]{4}).*/\1/p')
count=$(printf '%s\n' "$ids" | grep -c .)

[ "$count" -eq 0 ] && exit 0

{
  echo "$(date '+%F %T'): $count Eintraege '$NAME' gefunden, bereinige...";
  efibootmgr -v > "$BACKUPDIR/efibootmgr_backup_$(date +%F_%H%M%S).txt";

  deleted=0;
  for id in $ids; do
    if efibootmgr -b "$id" -B >/dev/null 2>&1; then
      deleted=$((deleted+1));
    else
      echo "  Fehler beim Loeschen von Boot$id";
    fi
  done
  echo "$(date '+%F %T'): $deleted von $count Eintraegen geloescht.";

  find "$BACKUPDIR" -maxdepth 1 -name 'efibootmgr_backup_*.txt' -mtime +30 -delete;
} >> "$LOG" 2>&1
