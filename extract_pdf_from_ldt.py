#!/usr/bin/env python3
"""
Extrahiert eine Base64-kodierte PDF aus einer LDT-Datei.

LDT-Format: Jede Zeile beginnt mit einer 3-stelligen Längenangabe,
gefolgt von einer 4-stelligen Feldkennung und dem Inhalt.

Feldkennung 8242 = base64-kodierte_Anlage (Nutzlast)
Feldkennung 9970 = Metainfo zum Anhang

Verwendung:
    python3 extract_pdf_from_ldt.py <ldt-datei> [ausgabe.pdf]
"""

import sys
import base64
from pathlib import Path


def extract_pdf_from_ldt(ldt_path: str, output_path: str = None) -> None:
    ldt_file = Path(ldt_path)
    if not ldt_file.exists():
        print(f"Fehler: Datei '{ldt_path}' nicht gefunden.")
        sys.exit(1)

    # Ausgabedateiname ableiten, falls nicht angegeben
    if output_path is None:
        output_path = ldt_file.with_suffix(".pdf").name

    print(f"Lese LDT-Datei: {ldt_file}")

    base64_chunks = []
    in_attachment = False

    # LDT-Dateien sind oft in latin-1 oder cp1252 kodiert
    for encoding in ("utf-8", "latin-1", "cp1252"):
        try:
            lines = ldt_file.read_text(encoding=encoding).splitlines()
            break
        except UnicodeDecodeError:
            continue
    else:
        print("Fehler: Datei konnte nicht dekodiert werden.")
        sys.exit(1)

    for line in lines:
        if len(line) < 7:
            continue

        # LDT-Zeilenstruktur: LLL FFFF Inhalt
        # LLL = Zeilenlänge (3 Ziffern, inklusive CRLF)
        # FFFF = Feldkennung (4 Ziffern)
        field_id = line[3:7]
        content = line[7:]

        # Feldkennung 8242 = Marker "base64-kodierte_Anlage" → Anhang beginnt
        if field_id == "8242" and "base64" in content.lower():
            in_attachment = True

        # Feldkennung 6329 = eigentliche Base64-Nutzlast
        elif field_id == "6329" and in_attachment:
            base64_chunks.append(content)

        # Andere Felder nach dem Anhang beenden ihn
        elif in_attachment and field_id != "6329":
            in_attachment = False

    if not base64_chunks:
        print("Keine Base64-kodierten Anlagen (Feldkennung 8242) gefunden.")
        sys.exit(1)

    print(f"  {len(base64_chunks)} Base64-Blöcke gefunden.")

    # Zusammensetzen und dekodieren
    raw_b64 = "".join(base64_chunks)
    # Whitespace entfernen (Zeilenumbrüche innerhalb der Chunks)
    raw_b64 = raw_b64.replace("\n", "").replace("\r", "").replace(" ", "")

    try:
        pdf_bytes = base64.b64decode(raw_b64)
    except Exception as e:
        print(f"Fehler beim Base64-Dekodieren: {e}")
        sys.exit(1)

    # PDF-Magic-Bytes prüfen
    if pdf_bytes[:4] == b"%PDF":
        version = pdf_bytes[4:8].decode("ascii", errors="replace")
        print(f"  PDF erkannt (Version {version.strip()})")
    else:
        print(f"  Warnung: Kein PDF-Header gefunden (erste 4 Bytes: {pdf_bytes[:4]!r})")
        print("           Die Datei wird trotzdem gespeichert.")

    # Passwortschutz-Hinweis (einfacher Heuristik-Check)
    if b"/Encrypt" in pdf_bytes[:2048]:
        print("  Hinweis: PDF enthält möglicherweise einen Verschlüsselungs-Eintrag (/Encrypt).")
    else:
        print("  Kein Hinweis auf Passwortschutz gefunden.")

    Path(output_path).write_bytes(pdf_bytes)
    print(f"\nErfolgreich gespeichert: {output_path}  ({len(pdf_bytes):,} Bytes)")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(0)

    ldt_path = sys.argv[1]
    out_path = sys.argv[2] if len(sys.argv) > 2 else None
    extract_pdf_from_ldt(ldt_path, out_path)
