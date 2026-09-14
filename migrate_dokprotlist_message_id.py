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

MAIL_PROFILE_ROOT = os.environ.get(
    "MAIL_PROFILE_ROOT", "/mnt/szn4/profiles/Schade/Mail")
SOURCES = [
    os.path.join(MAIL_PROFILE_ROOT, "pop.mnet-online.de", "Inbox"),
    os.path.join(MAIL_PROFILE_ROOT, "pop.mnet-online.de", "Archiv"),
    os.path.join(MAIL_PROFILE_ROOT, "Local Folders", "Praxis.sbd", "Patientenmails"),
]

TS_RE = re.compile(r"(\d{6} \d{6}),")


def build_message_index():
    """Zeitstempel (yymmdd hhmmss) -> Liste von (message_id, in_reply_to) -
    mehrere Eintraege bei einer Kollision zweier Nachrichten in derselben
    Sekunde, dann beim Abgleich unten bewusst nicht verwendet (siehe
    n_skip_ambiguous_ts)."""
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
            index.setdefault(ts, []).append((msg_id[:255], in_reply_to[:255] or None))
            n += 1
        print(f"{path}: {n} Nachrichten mit Date+Message-ID indiziert", flush=True)
    return index


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
    for r in all_rows:
        m = TS_RE.search(r["datName"])
        if not m:
            n_skip_no_ts += 1
            continue
        key = (r["Pat_ID"], m.group(1))
        groups.setdefault(key, []).append(r)
    print(f"Gruppen (Zeitstempel je Patient): {len(groups)}")

    n_ok_groups = 0
    n_ok_rows = 0
    n_skip_not_in_index = 0
    n_skip_ambiguous_ts = 0
    n_skip_error = 0

    for (pat_id, ts), rows in groups.items():
        if limit is not None and n_ok_groups >= limit:
            break
        candidates = index.get(ts)
        if not candidates:
            n_skip_not_in_index += 1
            continue
        if len(candidates) != 1:
            n_skip_ambiguous_ts += 1
            continue
        message_id, in_reply_to = candidates[0]

        if apply_changes:
            try:
                for r in rows:
                    cur.execute(
                        "UPDATE dokprotlist SET MessageID=%s, InReplyTo=%s WHERE id=%s",
                        (message_id, in_reply_to, r["id"]))
            except Exception as e:
                n_skip_error += 1
                print(f"FEHLER bei Anwendung (Pat_ID {pat_id}): {type(e).__name__}", flush=True)
                continue
        n_ok_groups += 1
        n_ok_rows += len(rows)

    print(f"\n{'Angewendet' if apply_changes else 'Wuerde anwenden'}: "
          f"{n_ok_groups} Gruppen ({n_ok_rows} Zeilen)")
    print(f"Uebersprungen - kein Zeitstempel im Dateinamen erkennbar: {n_skip_no_ts}")
    print(f"Uebersprungen - kein Treffer im Mail-Index: {n_skip_not_in_index}")
    print(f"Uebersprungen - Zeitstempel im Index mehrdeutig (Kollision): {n_skip_ambiguous_ts}")
    print(f"Uebersprungen - Fehler bei Anwendung: {n_skip_error}")

    if not apply_changes:
        print("\nTrockenlauf beendet. Mit --apply erneut aufrufen, um tatsaechlich zu schreiben.")

    dokprot_conn.close()


if __name__ == "__main__":
    main()
