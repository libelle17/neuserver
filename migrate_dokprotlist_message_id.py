# -*- coding: utf-8 -*-
# Rueckwirkende Migration (Auftrag der Windows-Instanz, 2026-09-14): fuellt
# dokprotlist.MessageID/InReplyTo fuer den Email-Altbestand nach - Grundlage
# fuer resolve_ambiguous_patients() Kriterium 6 (_match_via_thread()) in
# archive_patient_emails.py, das diese Spalten seit demselben Tag bei jeder
# NEU archivierten Nachricht befuellt.
#
# Anders als bei der EmailAdresse-Migration (migrate_dokprotlist_email_
# adresse.py) steht Message-ID/In-Reply-To NICHT im gerenderten PDF-Text
# (build_pdf_html() schreibt nur Von/An/Datum/Betreff/Body) - die
# Original-Rohnachricht muss dafuer wiedergefunden werden. Quelle: exakt
# die DREI Mbox-Dateien, aus denen archive_patient_emails.py historisch je
# archiviert hat (siehe SOURCES dort) - erreichbar ueber eine vom Nutzer
# eingerichtete CIFS-Freigabe auf Thunderbirds Windows-Profil
# (MAIL_PROFILE_ROOT, per Umgebungsvariable ueberschreibbar).
#
# Abgleich ueber den im Dateinamen bereits vorhandenen Zeitstempel
# (yymmdd hhmmss) - exakt derselbe Wert, den archive_patient_emails.py bei
# der urspruenglichen Archivierung per email.utils.parsedate_to_datetime()
# aus demselben "Date:"-Header berechnet hat, daher zuverlaessig abgleichbar.
# Bei einer (seltenen) Kollision zweier Nachrichten in derselben Sekunde
# wird die Gruppe sicherheitshalber uebersprungen (kein Raten).
#
# Standardmaessig NUR Trockenlauf. --apply schreibt tatsaechlich. Ein
# erneuter Lauf bearbeitet automatisch nur noch Zeilen mit MessageID IS
# NULL - bereits erledigte werden nicht doppelt angefasst.
import email.utils
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import patient_addresses_db as padb
from find_missing_patient_emails import iter_headers
from archive_patient_emails import sanitize, decode_header_val

REPORT_PATH = os.environ.get(
    "REPORT_PATH", "/opt/mo-emailadr/protokolle/message_id_offene_faelle.csv")
MAIL_PROFILE_ROOT = os.environ.get(
    "MAIL_PROFILE_ROOT", "/mnt/szn4/profiles/Schade/Mail")
SOURCES = [
    os.path.join(MAIL_PROFILE_ROOT, "pop.mnet-online.de", "Inbox"),
    os.path.join(MAIL_PROFILE_ROOT, "pop.mnet-online.de", "Archiv"),
    os.path.join(MAIL_PROFILE_ROOT, "Local Folders", "Praxis.sbd", "Patientenmails"),
]

TS_RE = re.compile(r"(\d{6} \d{6}),")
ADDR_RE = re.compile(r"Email (?:von|an) (\S+) \d{6} \d{6}, ")
REST_RE = re.compile(r"\d{6} \d{6}, (.*)$")


def build_message_index():
    """Zeitstempel (yymmdd hhmmss) -> Liste von Kandidaten-Dicts (message_id,
    in_reply_to, from, to, cc, subject) - mehrere Eintraege bei einer
    Kollision zweier Nachrichten in derselben Sekunde. from/to/cc/subject
    dienen NUR dazu, eine solche Kollision anhand der im Dateinamen bereits
    vorhandenen Adresse/des Betreffs aufzuloesen (siehe resolve_collision()),
    nicht fuer den einfachen Eindeutig-Fall."""
    index = {}
    for path in SOURCES:
        n = 0
        for headers in iter_headers(path):
            date_raw = headers.get(b"date")
            msg_id = (headers.get(b"message-id") or b"").decode("utf-8", "replace").strip()
            if not date_raw or not msg_id:
                continue
            try:
                dt = email.utils.parsedate_to_datetime(date_raw.decode("utf-8", "replace"))
                ts = dt.strftime("%y%m%d %H%M%S")
            except (TypeError, ValueError, OverflowError, AttributeError):
                continue
            in_reply_to = (headers.get(b"in-reply-to") or b"").decode("utf-8", "replace").strip()
            entry = {
                "message_id": msg_id[:255],
                "in_reply_to": in_reply_to[:255] or None,
                "from": (headers.get(b"from") or b"").decode("utf-8", "replace").lower(),
                "to": (headers.get(b"to") or b"").decode("utf-8", "replace").lower(),
                "cc": (headers.get(b"cc") or b"").decode("utf-8", "replace").lower(),
                "subject": (headers.get(b"subject") or b"").decode("utf-8", "replace"),
            }
            index.setdefault(ts, []).append(entry)
            n += 1
        print(f"{path}: {n} Nachrichten mit Date+Message-ID indiziert", flush=True)
    return index


def resolve_collision(candidates, addr, direction_marker, betreff):
    """Loest eine Zeitstempel-Kollision (mehrere Nachrichten in derselben
    Sekunde) anhand der im Dateinamen bereits vorhandenen Adresse und des
    Betreffs auf - beides wurde bei der EmailAdresse-Migration bzw. der
    urspruenglichen Archivierung bereits aus genau DIESER Nachricht
    gewonnen, ist also ein zuverlaessiger Filter. 'von' -> Adresse muss im
    From-Header stehen, 'an' -> im To- oder Cc-Header. Liefert den
    eindeutigen Kandidaten oder None."""
    if addr:
        if direction_marker == "von":
            filtered = [c for c in candidates if addr in c["from"]]
        else:
            filtered = [c for c in candidates if addr in c["to"] or addr in c["cc"]]
        if len(filtered) == 1:
            return filtered[0]
        if filtered:
            candidates = filtered  # weiter einengen ueber den Betreff, s.u.
    if betreff:
        matching = [c for c in candidates
                    if sanitize(decode_header_val(c["subject"]))[:100] == betreff]
        if len(matching) == 1:
            return matching[0]
    return None


def extract_addr_betreff(row):
    """Adresse+Betreff aus dem (bereits von der EmailAdresse-Migration neu
    benannten) datName - nur fuer die Abschlussliste der offenen Faelle,
    unabhaengig davon ob eine Kollision vorlag."""
    m_addr = ADDR_RE.search(row["datName"])
    addr = m_addr.group(1) if m_addr else ""
    m_rest = REST_RE.search(row["datName"])
    rest = m_rest.group(1) if m_rest else ""
    betreff = rest.split("; ")[0] if "; " in rest else os.path.splitext(rest)[0]
    return addr, betreff


def write_report(skip_records):
    """Schreibt die am Ende dieses Laufs weiterhin offenen Faelle nach Grund
    sortiert in REPORT_PATH - Wunsch des Nutzers 2026-09-14, um die
    verbleibenden Luecken selbst durchsehen zu koennen."""
    os.makedirs(os.path.dirname(REPORT_PATH), exist_ok=True)
    skip_records = sorted(skip_records, key=lambda r: (r["grund"], r["pat_id"] or 0, r["zeitpunkt"]))
    with open(REPORT_PATH, "w", encoding="utf-8", newline="") as f:
        f.write("Grund;Pat_ID;Email-Adresse;Zeitpunkt;Betreff\n")
        for r in skip_records:
            zeile = ";".join([
                r["grund"], str(r["pat_id"] or ""), r["addr"], r["zeitpunkt"],
                r["betreff"].replace(";", ",").replace("\n", " "),
            ])
            f.write(zeile + "\n")
    print(f"\nOffene Faelle geschrieben nach: {REPORT_PATH} ({len(skip_records)} Zeilen)")


def main():
    apply_changes = "--apply" in sys.argv
    limit = None
    for a in sys.argv[1:]:
        if a.startswith("--limit="):
            limit = int(a.split("=", 1)[1])

    print("Baue Nachrichten-Index aus Mbox-Dateien auf ...", flush=True)
    index = build_message_index()
    print(f"Index: {len(index)} unterschiedliche Zeitstempel\n", flush=True)

    dokprot_conn = padb.connect_dokprot()
    cur = dokprot_conn.cursor()
    cur.execute(
        "SELECT id, Pat_ID, datName FROM dokprotlist "
        "WHERE datName LIKE '% Email %' AND MessageID IS NULL "
        "ORDER BY Pat_ID, datName")
    all_rows = cur.fetchall()
    print(f"Zeilen ohne MessageID: {len(all_rows)}")

    groups = {}
    n_skip_no_ts = 0
    skip_records = []
    for r in all_rows:
        m = TS_RE.search(r["datName"])
        if not m:
            n_skip_no_ts += 1
            skip_records.append({
                "grund": "kein_zeitstempel_im_dateinamen", "pat_id": r["Pat_ID"],
                "addr": "", "zeitpunkt": "", "betreff": "",
            })
            continue
        key = (r["Pat_ID"], m.group(1))
        groups.setdefault(key, []).append(r)
    print(f"Gruppen (Zeitstempel je Patient): {len(groups)}")

    n_ok_groups = 0
    n_ok_rows = 0
    n_ok_via_collision_resolve = 0
    n_skip_not_in_index = 0
    n_skip_ambiguous_ts = 0
    n_skip_error = 0

    for (pat_id, ts), rows in groups.items():
        if limit is not None and n_ok_groups >= limit:
            break
        addr, betreff = extract_addr_betreff(rows[0])
        candidates = index.get(ts)
        if not candidates:
            n_skip_not_in_index += 1
            skip_records.append({
                "grund": "kein_treffer_im_mail_index", "pat_id": pat_id,
                "addr": addr, "zeitpunkt": ts, "betreff": betreff,
            })
            continue
        if len(candidates) == 1:
            hit = candidates[0]
        else:
            m_addr = ADDR_RE.search(rows[0]["datName"])
            direction_marker = m_addr.group(0).split()[1] if m_addr else None
            hit = resolve_collision(candidates, addr.lower() if addr else None, direction_marker, betreff)
            if hit is None:
                n_skip_ambiguous_ts += 1
                skip_records.append({
                    "grund": "zeitstempel_mehrdeutig", "pat_id": pat_id,
                    "addr": addr, "zeitpunkt": ts, "betreff": betreff,
                })
                continue
            n_ok_via_collision_resolve += 1
        message_id, in_reply_to = hit["message_id"], hit["in_reply_to"]

        if apply_changes:
            try:
                for r in rows:
                    cur.execute(
                        "UPDATE dokprotlist SET MessageID=%s, InReplyTo=%s WHERE id=%s",
                        (message_id, in_reply_to, r["id"]))
            except Exception as e:
                n_skip_error += 1
                print(f"FEHLER bei Anwendung (Pat_ID {pat_id}): {type(e).__name__}", flush=True)
                skip_records.append({
                    "grund": "fehler_bei_anwendung", "pat_id": pat_id,
                    "addr": addr, "zeitpunkt": ts, "betreff": betreff,
                })
                continue
        n_ok_groups += 1
        n_ok_rows += len(rows)

    print(f"\n{'Angewendet' if apply_changes else 'Wuerde anwenden'}: "
          f"{n_ok_groups} Gruppen ({n_ok_rows} Zeilen)")
    print(f"  davon {n_ok_via_collision_resolve} ueber Adresse/Betreff aus einer "
          f"Zeitstempel-Kollision aufgeloest")
    print(f"Uebersprungen - kein Zeitstempel im Dateinamen erkennbar: {n_skip_no_ts}")
    print(f"Uebersprungen - kein Treffer im Mail-Index: {n_skip_not_in_index}")
    print(f"Uebersprungen - Zeitstempel im Index mehrdeutig (Kollision): {n_skip_ambiguous_ts}")
    print(f"Uebersprungen - Fehler bei Anwendung: {n_skip_error}")

    write_report(skip_records)

    if not apply_changes:
        print("\nTrockenlauf beendet. Mit --apply erneut aufrufen, um tatsaechlich zu schreiben.")

    dokprot_conn.close()


if __name__ == "__main__":
    main()
