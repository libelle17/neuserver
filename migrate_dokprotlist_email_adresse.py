# -*- coding: utf-8 -*-
# Einmalige Migration (Nutzerauftrag 2026-09-12): fuellt die neue Spalte
# dokprotlist.EmailAdresse rueckwirkend fuer alle bereits archivierten
# Emails in P:\dok und benennt die zugehoerigen Dateien + datName-Zeilen
# um von "Nachname Vorname (angek./gesan.) Email yymmdd hhmmss, Rest" nach
# "Nachname [Titel ][Vorsatzwort ][Zusatzwort ]Vorname Email von/an
# xy@z.de yymmdd hhmmss, Rest" (Nachname/Vorname/Titel/Vorsatzwort/
# Zusatzwort werden frisch aus medoff.patstamm ueber Pat_ID gelesen, nicht
# aus dem alten Dateinamen geparst - robuster bei Leerzeichen in Namen).
#
# Hintergrund: die Patientenzuordnung bei Thunderbird-Mails wird zunehmend
# komplex und muss z.T. nachtraeglich korrigiert werden - mit der Adresse
# im Dateinamen/in der DB laesst sich das leichter nachvollziehen.
#
# Ablauf pro "Email-Ereignis" (Pat_ID+direction+Zeitstempel, kann mehrere
# dokprotlist-Zeilen umfassen: die Email-PDF selbst + je eine Zeile pro
# Anhang): Basis-Zeile (die Email-PDF, NICHT ein Anhang) ermitteln, deren
# PDF-Text nach der "Von:"/"An:"-Zeile durchsuchen (angek. -> Von:,
# gesan. -> An:), Adresse extrahieren (bei mehreren Kandidaten gegen die
# bekannten Adressen des Patienten - medoff.patstamm.FEmail + gestagte
# quelle.pat_email_adr - abgleichen), dieselbe Adresse und denselben neuen
# Namens-Praefix auf ALLE Zeilen der Gruppe anwenden.
#
# Standardmaessig NUR Trockenlauf (zaehlt/protokolliert, schreibt nichts).
# --apply schreibt tatsaechlich (Datei-Umbenennung + UPDATE dokprotlist).
# connect_dokprot() laeuft mit autocommit=True - jede UPDATE-Anweisung ist
# sofort dauerhaft, es gibt also keine echte Transaktionsgrenze pro Gruppe.
# Deshalb wird JEDE alte Quelldatei einer Gruppe VOR dem ersten rename()
# auf Existenz geprueft (verhindert die Bruchursache von Vorfall Pat_ID
# 2146, 2026-09-12: eine fehlende Anhang-Datei mitten in einer Gruppe, erst
# nachdem andere Zeilen der Gruppe schon umbenannt+committet waren). Ein
# erneuter Lauf bearbeitet automatisch nur noch die Zeilen, die weiterhin
# auf das ALTE Namensmuster passen (WHERE-Bedingung) - bereits erledigte
# werden nicht doppelt angefasst.
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import patient_addresses_db as padb
import linux1_medoff_connect as medoff_conn_helper
from archive_patient_emails import (
    extract_pdf_text, cap_filename_length, DOK_ROOT, build_name_prefix,
)

OLD_PATTERN_RE = re.compile(
    r"\((?P<direction>angek|gesan)\.\) Email (?P<ts>\d{6} \d{6}), (?P<rest>.*)$")
EMAIL_RE = re.compile(r"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}")
DIRECTION_MARKER = {"angek": "von", "gesan": "an"}
DIRECTION_HEADER_LABEL = {"angek": "Von", "gesan": "An"}


def load_patstamm(medoff_cur, pat_ids):
    if not pat_ids:
        return {}
    placeholders = ",".join(["%s"] * len(pat_ids))
    medoff_cur.execute(
        "SELECT FSurogat, FVorname, FNachname, FTitel, FNamensvorsatz, FNamenszusatz "
        f"FROM patstamm WHERE FSurogat IN ({placeholders})", tuple(pat_ids))
    return {str(r["FSurogat"]): r for r in medoff_cur.fetchall()}


def load_known_addresses(medoff_cur, staged_by_patient, pat_id):
    addrs = set()
    medoff_cur.execute("SELECT FEmail FROM patstamm WHERE FSurogat=%s", (pat_id,))
    row = medoff_cur.fetchone()
    if row and row.get("FEmail"):
        addrs.add(row["FEmail"].strip().lower())
    for a in staged_by_patient.get(str(pat_id), []):
        addrs.add(a.strip().lower())
    return addrs


def find_base_row(rows):
    """rows: Liste von dicts mit id/datName fuer EINE Gruppe (gleicher
    Pat_ID+direction+Zeitstempel). Liefert die Basis-Zeile (die Email-PDF
    selbst, kein Anhang) oder None, wenn nicht eindeutig bestimmbar."""
    candidates = []
    for r in rows:
        dn = r["datName"]
        if not dn.lower().endswith(".pdf"):
            continue
        stem = dn[: -len(".pdf")]
        if all(o["id"] == r["id"] or o["datName"].startswith(stem + "; ") for o in rows):
            candidates.append(r)
    if len(candidates) == 1:
        return candidates[0]
    return None


def extract_address(pdf_path, direction, known_addrs):
    txt = extract_pdf_text(pdf_path) or ""
    label = DIRECTION_HEADER_LABEL[direction]
    m = re.search(rf"{label}\s*:?[ \t]*([^\n]*)", txt)
    if not m:
        return None, "Header-Zeile nicht gefunden"
    candidates = EMAIL_RE.findall(m.group(1))
    # Deduplizieren (case-insensitiv) - haeufigster Fall: Anzeigename ==
    # Adresse (z.B. "patient@email.de <patient@email.de>"), das ergaebe
    # sonst faelschlich zwei "Kandidaten" fuer dieselbe Adresse und wuerde
    # als nicht eindeutig gewertet (Befund des Nutzers 2026-09-12, betraf
    # den Grossteil der urspruenglich 1028 "2 Adressen, davon 2 bekannt"-
    # Faelle).
    seen = set()
    deduped = []
    for c in candidates:
        cl = c.lower()
        if cl not in seen:
            seen.add(cl)
            deduped.append(c)
    candidates = deduped
    if not candidates:
        return None, "keine Adresse in Header-Zeile"
    if len(candidates) == 1:
        return candidates[0].lower(), None
    matching = [c for c in candidates if c.lower() in known_addrs]
    if len(matching) == 1:
        return matching[0].lower(), None
    return None, f"{len(candidates)} Adressen, davon {len(matching)} bekannt (nicht eindeutig)"


def main():
    apply_changes = "--apply" in sys.argv
    limit = None
    for a in sys.argv[1:]:
        if a.startswith("--limit="):
            limit = int(a.split("=", 1)[1])

    padb_conn = padb.connect()
    medoff = medoff_conn_helper.connect_medoff()
    medoff_cur = medoff.cursor()
    dokprot_conn = padb.connect_dokprot()
    dokprot_cur = dokprot_conn.cursor()

    dokprot_cur.execute(
        "SELECT id, Pat_ID, datName FROM dokprotlist "
        "WHERE datName REGEXP '\\\\((angek|gesan)\\\\.\\\\) Email [0-9]{6} [0-9]{6}, ' "
        "ORDER BY Pat_ID, datName")
    all_rows = dokprot_cur.fetchall()
    print(f"Zeilen mit altem Namensmuster: {len(all_rows)}")

    groups = {}
    for r in all_rows:
        m = OLD_PATTERN_RE.search(r["datName"])
        if not m:
            continue
        key = (r["Pat_ID"], m.group("direction"), m.group("ts"))
        groups.setdefault(key, []).append({**r, "_rest": m.group("rest")})
    print(f"Gruppen (Email-Ereignisse): {len(groups)}")

    pat_ids = sorted({k[0] for k in groups if k[0] is not None})
    patstamm = load_patstamm(medoff_cur, pat_ids)
    staged_by_patient = padb.addresses_by_patient(padb_conn)
    known_addr_cache = {}

    n_ok_groups = 0
    n_ok_rows = 0
    n_skip_no_patid = 0
    n_skip_no_patstamm = 0
    n_skip_no_base = 0
    n_skip_file_missing = 0
    n_skip_addr = {}
    skip_examples = {}

    for key, rows in groups.items():
        pat_id, direction, ts = key
        if limit is not None and n_ok_groups >= limit:
            break
        if pat_id is None:
            n_skip_no_patid += 1
            continue
        p = patstamm.get(str(pat_id))
        if p is None:
            n_skip_no_patstamm += 1
            continue
        base = find_base_row(rows)
        if base is None:
            n_skip_no_base += 1
            continue
        base_path = os.path.join(DOK_ROOT, str(pat_id), base["datName"])
        if not os.path.exists(base_path):
            n_skip_file_missing += 1
            continue
        known = known_addr_cache.get(pat_id)
        if known is None:
            known = load_known_addresses(medoff_cur, staged_by_patient, pat_id)
            known_addr_cache[pat_id] = known
        addr, err = extract_address(base_path, direction, known)
        if addr is None:
            n_skip_addr[err] = n_skip_addr.get(err, 0) + 1
            skip_examples.setdefault(err, []).append(base["id"])
            continue

        prefix = build_name_prefix(p)
        marker = DIRECTION_MARKER[direction]
        new_prefix_full = f"{prefix} Email {marker} {addr} {ts}, "

        group_ok = True
        skip_reason = None
        planned = []
        for r in rows:
            new_name = cap_filename_length(new_prefix_full + r["_rest"])
            new_path = os.path.join(DOK_ROOT, str(pat_id), new_name)
            old_path = os.path.join(DOK_ROOT, str(pat_id), r["datName"])
            if old_path != new_path and not os.path.exists(old_path):
                group_ok = False
                skip_reason = "Anhang-/Quelldatei fehlt auf Platte"
                break
            if new_path != old_path and os.path.exists(new_path):
                group_ok = False
                skip_reason = "Zieldatei existiert bereits"
                break
            planned.append((r["id"], old_path, new_path, new_name))
        if not group_ok:
            n_skip_addr[skip_reason] = n_skip_addr.get(skip_reason, 0) + 1
            continue

        if apply_changes:
            try:
                for _id, old_path, new_path, new_name in planned:
                    if old_path != new_path:
                        os.rename(old_path, new_path)
                    dokprot_cur.execute(
                        "UPDATE dokprotlist SET datName=%s, EmailAdresse=%s WHERE id=%s",
                        (new_name, addr, _id))
            except Exception as e:
                # ACHTUNG: connect_dokprot() laeuft mit autocommit=True - jede
                # UPDATE-Anweisung oben ist bereits beim Ausfuehren dauerhaft
                # committet, nicht erst hier. Ein Fehler auf Zeile N dieser
                # Gruppe hinterlaesst also Zeilen 1..N-1 bereits umbenannt+
                # aktualisiert, Zeile N und der Rest der Gruppe noch im alten
                # Zustand - das ist NICHT automatisch atomar rueckrollbar
                # (Dateisystem-Renames sind es ohnehin nie). Der Vorbau oben
                # (Existenzpruefung ALLER old_paths vor dem ersten rename())
                # verhindert die urspruengliche Bruchursache (fehlende Anhang-
                # Datei, Vorfall Pat_ID 2146, 2026-09-12) praeventiv - dieser
                # except-Block faengt nur noch echte Ueberraschungen ab, damit
                # sie den restlichen, langen Lauf nicht abbrechen. Eine so
                # entstehende Teil-Migration muss von Hand nachgezogen werden
                # (siehe [[project-missing-patient-emails]]).
                key = f"Fehler bei Anwendung ({type(e).__name__})"
                n_skip_addr[key] = n_skip_addr.get(key, 0) + 1
                skip_examples.setdefault(key, []).append(f"Pat_ID {pat_id}")
                continue
        n_ok_groups += 1
        n_ok_rows += len(planned)

    print(f"\n{'Angewendet' if apply_changes else 'Wuerde anwenden'}: "
          f"{n_ok_groups} Gruppen ({n_ok_rows} Zeilen/Dateien)")
    print(f"Uebersprungen - kein Pat_ID: {n_skip_no_patid}")
    print(f"Uebersprungen - Pat_ID nicht (mehr) in patstamm: {n_skip_no_patstamm}")
    print(f"Uebersprungen - Basis-Email-PDF nicht eindeutig bestimmbar: {n_skip_no_base}")
    print(f"Uebersprungen - Basis-Datei fehlt auf Platte: {n_skip_file_missing}")
    for err, n in sorted(n_skip_addr.items(), key=lambda kv: -kv[1]):
        beispiel_ids = skip_examples.get(err, [])[:5]
        print(f"Uebersprungen - {err}: {n}" +
              (f" (Beispiel-IDs: {beispiel_ids})" if beispiel_ids else ""))

    if not apply_changes:
        print("\nTrockenlauf beendet. Mit --apply erneut aufrufen, um tatsaechlich zu schreiben.")

    dokprot_conn.close()
    medoff.close()
    padb_conn.close()


if __name__ == "__main__":
    main()
