# -*- coding: utf-8 -*-
# Einmaliges Hilfsskript (2026-09-12, Nutzeranfrage): kopiert die von
# migrate_dokprotlist_email_adresse.py uebersprungenen Email-Gruppen zur
# Durchsicht nach /DATA/Patientendokumente/email_migration_review/<Grund>/
# <Pat_ID>/ - reine Kopie (Originale in dok/ bleiben unangetastet).
import os
import re
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import patient_addresses_db as padb
import linux1_medoff_connect as medoff_conn_helper
from archive_patient_emails import extract_pdf_text, DOK_ROOT
from migrate_dokprotlist_email_adresse import (
    OLD_PATTERN_RE, load_patstamm, load_known_addresses, find_base_row,
    extract_address,
)

REVIEW_ROOT = os.environ.get(
    "REVIEW_ROOT", "/DATA/Patientendokumente/email_migration_review")
OWNER_UID = 1001  # sturm
OWNER_GID = 1001  # praxis


def slugify(text):
    text = re.sub(r"[^A-Za-z0-9]+", "_", text).strip("_").lower()
    return text[:60]


def main():
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

    groups = {}
    for r in all_rows:
        m = OLD_PATTERN_RE.search(r["datName"])
        if not m:
            continue
        key = (r["Pat_ID"], m.group("direction"), m.group("ts"))
        groups.setdefault(key, []).append(r)

    pat_ids = sorted({k[0] for k in groups if k[0] is not None})
    patstamm = load_patstamm(medoff_cur, pat_ids)
    staged_by_patient = padb.addresses_by_patient(padb_conn)
    known_addr_cache = {}

    n_copied_files = 0
    n_groups_by_reason = {}

    for key, rows in groups.items():
        pat_id, direction, ts = key
        reason = None
        if pat_id is None:
            reason = "kein_Pat_ID"
        else:
            p = patstamm.get(str(pat_id))
            if p is None:
                reason = "Pat_ID nicht mehr in patstamm"
            else:
                base = find_base_row(rows)
                if base is None:
                    reason = "Basis-Email-PDF nicht eindeutig bestimmbar"
                else:
                    base_path = os.path.join(DOK_ROOT, str(pat_id), base["datName"])
                    if not os.path.exists(base_path):
                        reason = "Basis-Datei fehlt auf Platte"
                    else:
                        missing_sibling = any(
                            not os.path.exists(os.path.join(DOK_ROOT, str(pat_id), r["datName"]))
                            for r in rows)
                        if missing_sibling:
                            reason = "Anhang- oder Quelldatei fehlt auf Platte"
                        else:
                            known = known_addr_cache.get(pat_id)
                            if known is None:
                                known = load_known_addresses(medoff_cur, staged_by_patient, pat_id)
                                known_addr_cache[pat_id] = known
                            addr, err = extract_address(base_path, direction, known)
                            reason = err if addr is None else "faelschlich noch nicht migriert"

        n_groups_by_reason[reason] = n_groups_by_reason.get(reason, 0) + 1
        slug = slugify(reason)
        target_dir = os.path.join(REVIEW_ROOT, slug, str(pat_id) if pat_id is not None else "ohne_pat_id")
        os.makedirs(target_dir, exist_ok=True)
        for r in rows:
            src = os.path.join(DOK_ROOT, str(pat_id), r["datName"])
            if not os.path.exists(src):
                continue
            dst = os.path.join(target_dir, r["datName"])
            if not os.path.exists(dst):
                shutil.copy2(src, dst)
                n_copied_files += 1

    for root, dirs, files in os.walk(REVIEW_ROOT):
        os.chown(root, OWNER_UID, OWNER_GID)
        os.chmod(root, 0o770)
        for f in files:
            fp = os.path.join(root, f)
            os.chown(fp, OWNER_UID, OWNER_GID)
            os.chmod(fp, 0o660)

    print(f"Kopierte Dateien: {n_copied_files}")
    print(f"Ziel: {REVIEW_ROOT}")
    print("Gruppen je Grund:")
    for reason, n in sorted(n_groups_by_reason.items(), key=lambda kv: -kv[1]):
        print(f"  {slugify(reason)}: {n}")

    dokprot_conn.close()
    medoff.close()
    padb_conn.close()


if __name__ == "__main__":
    main()
