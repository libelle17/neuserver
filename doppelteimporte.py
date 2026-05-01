#!/usr/bin/env python3

# doppelteimporte.py
# Findet Dateien, die sich nur durch " (1)", " (2)" etc. vor der Endung unterscheiden
# und inhaltlich identisch mit der Originaldatei sind.
#
# Verwendung:
#   ./doppelteimporte.py          -> Probelauf (nur Ausgabe, kein Löschen)
#   ./doppelteimporte.py --delete -> Echtlauf (löscht Duplikate)

import os
import re
import sys
import hashlib
from datetime import datetime

SEARCH_DIRS = [
    "/DATA/Patientendokumente/dok",
    "/DATA/Patientendokumente/eingelesen",
]

# Regex: "Name (N).ext" – N ist eine oder mehrere Ziffern
DUP_PATTERN = re.compile(r'^(.*) \((\d+)\)((\.[^.]+)?)$')

# ANSI-Farben
# Farben – werden in main() ggf. auf '' gesetzt
BLUE   = '\033[0;34m'
PURPLE = '\033[0;35m'
RESET  = '\033[0m'

BLOCK_SIZE = 65536  # 64 KB Blöcke für MD5-Berechnung


def format_size(n):
    """Formatiert eine Byte-Zahl mit Leerzeichen als Tausendertrenner."""
    s = str(n)
    groups = []
    while len(s) > 3:
        groups.append(s[-3:])
        s = s[:-3]
    groups.append(s)
    return ' '.join(reversed(groups))


def file_meta(path):
    """Gibt (datetime_str, size_col) zurück."""
    st = os.stat(path)
    dt = datetime.fromtimestamp(st.st_mtime).strftime('%Y%m%d %H%M%S')
    size_col = format_size(st.st_size).rjust(13)
    return dt, size_col


def md5(path):
    """Berechnet MD5-Hash blockweise; gibt None bei Fehler zurück."""
    h = hashlib.md5()
    try:
        with open(path, 'rb') as f:
            while True:
                chunk = f.read(BLOCK_SIZE)
                if not chunk:
                    break
                h.update(chunk)
    except OSError:
        return None
    return h.hexdigest()


def print_file_line(label, path, color=""):
    dt, size_col = file_meta(path)
    name = os.path.basename(path)
    print(f"  {label}  {dt}  {size_col}  {color}{name}{RESET}")


def nat_sort_key(path):
    """Sortierschlüssel für natürliche Sortierung (Nummer in Klammern)."""
    name = os.path.basename(path)
    m = DUP_PATTERN.match(name)
    return int(m.group(2)) if m else 0


def scan_directory(dirpath):
    """
    Gibt ein Dict zurück: KEY (Originalname) -> Liste der Duplikat-Pfade.
    Nur Einträge, für die auch eine Originaldatei existiert.
    """
    # Alle Dateinamen im Verzeichnis in einem Aufruf einlesen
    try:
        entries = {e.name: e.path for e in os.scandir(dirpath) if e.is_file(follow_symlinks=False)}
    except OSError:
        return {}

    groups: dict[str, list[str]] = {}
    for name, path in entries.items():
        m = DUP_PATTERN.match(name)
        if not m:
            continue
        original_name = m.group(1) + m.group(3)  # Name + Endung ohne " (N)"
        if original_name in entries:
            groups.setdefault(original_name, []).append(path)

    return groups


def process_group(original, dup_paths, dry_run, total):
    """Vergleicht Duplikate mit Original und gibt Ergebnis aus."""

    # Schnellcheck: Größe verschieden -> sicher kein Duplikat
    try:
        orig_size = os.path.getsize(original)
    except OSError:
        return

    orig_hash: str | None = None  # lazy: nur berechnen wenn nötig

    echte:  list[str] = []
    andere: list[str] = []

    for dup in sorted(dup_paths, key=nat_sort_key):
        try:
            dup_size = os.path.getsize(dup)
        except OSError:
            continue

        if dup_size != orig_size:
            andere.append(dup)
            continue

        # Größen gleich -> Hash-Vergleich
        if orig_hash is None:
            orig_hash = md5(original)
            if orig_hash is None:
                return  # Original nicht lesbar

        dup_hash = md5(dup)
        if dup_hash == orig_hash:
            echte.append(dup)
        else:
            andere.append(dup)

    if not echte and not andere:
        return

    dirpath = os.path.dirname(original)
    print(f"Gruppe: {BLUE}{dirpath}{RESET}")
    print_file_line("Original (wird behalten):", original, BLUE)

    for dup in echte:
        try:
            dup_size = os.path.getsize(dup)
        except OSError:
            dup_size = 0
        print_file_line("Duplikat (wird gelöscht):", dup)
        total['found'] += 1
        total['size_found'] += dup_size
        if not dry_run:
            try:
                os.remove(dup)
                total['deleted'] += 1
                total['size_deleted'] += dup_size
            except OSError as e:
                print(f"  FEHLER beim Löschen von {dup}: {e}")

    for dup in andere:
        print_file_line("Duplikat (unterschiedl.):", dup, PURPLE)

    print()


def main() -> None:
    global BLUE, PURPLE, RESET
    dry_run  = '--delete' not in sys.argv
    no_color = '--no-color' in sys.argv
    if no_color:
        BLUE = PURPLE = RESET = ''

    if dry_run:
        print("=== PROBELAUF (kein Löschen) ===")
        print(f"Zum echten Löschen: {sys.argv[0]} --delete")
    else:
        print("=== ECHTLAUF (Duplikate werden gelöscht) ===")
    print()

    total = {'found': 0, 'deleted': 0, 'size_found': 0, 'size_deleted': 0}

    for base_dir in SEARCH_DIRS:
        if not os.path.isdir(base_dir):
            print(f"WARNUNG: Verzeichnis '{base_dir}' nicht gefunden, wird übersprungen.\n")
            continue

        # os.walk ist effizienter als rekursive find-Aufrufe
        for dirpath, dirnames, _ in os.walk(base_dir):
            dirnames.sort()  # alphabetische Reihenfolge
            groups = scan_directory(dirpath)
            for original_name, dup_paths in sorted(groups.items()):
                original = os.path.join(dirpath, original_name)
                process_group(original, dup_paths, dry_run, total)

    print("================================")
    if dry_run:
        print(f"Probelauf abgeschlossen.")
        print(f"Gefundene Duplikate:      {total['found']}")
        print(f"Gesamtgröße (zu löschen): {format_size(total['size_found'])} Bytes")
        print(f"(Keine Dateien wurden gelöscht)")
    else:
        print(f"Echtlauf abgeschlossen.")
        print(f"Gefundene Duplikate:  {total['found']}")
        print(f"Gelöschte Duplikate:  {total['deleted']}")
        print(f"Freigegebene Größe:   {format_size(total['size_deleted'])} Bytes")


if __name__ == '__main__':
    main()
