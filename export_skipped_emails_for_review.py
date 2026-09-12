# -*- coding: utf-8 -*-
# Einmaliges Hilfsskript (2026-09-12, Nutzeranfrage): kopiert die von
# migrate_dokprotlist_email_adresse.py uebersprungenen Email-Gruppen zur
# Durchsicht nach /DATA/Patientendokumente/email_migration_review/<Grund>/
# <Pat_ID>/ - reine Kopie (Originale in dok/ bleiben unangetastet).
#
# sync_review_tree() gleicht bei jedem Lauf nur die DIFFERENZ zum
# vorhandenen Baum ab (legt fehlende Verzeichnisse/Dateien an, entfernt
# nicht mehr benoetigte) - ruehrt dabei Verzeichnisse/Dateien, die schon
# vorhanden UND weiterhin gewuenscht sind, gar nicht erst an. Grund: ein
# Windows-Client, der einen Unterordner schon offen hat, haelt eine SMB3-
# Lease auf dessen Inode - wird der Ordner geloescht+neu angelegt (wie
# fruehere Version: kompletter rm -rf + Neuaufbau bei jedem Lauf), zeigt
# die Lease auf ein totes Inode und der Zugriff schlaegt fehl, bis sie
# serverseitig gebrochen wird (smbcontrol <pid> close-share <share> -
# mehrfach noetig gewesen, 2026-09-12). Unveraenderte Unterordner bleiben
# mit dieser Version stabil.
import os
import re
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import patient_addresses_db as padb
import linux1_medoff_connect as medoff_conn_helper
from archive_patient_emails import extract_pdf_text, DOK_ROOT
from migrate_dokprotlist_email_adresse import (
    OLD_PATTERN_RE, load_patstamm, load_known_addresses, resolve_address,
)

REVIEW_ROOT = os.environ.get(
    "REVIEW_ROOT", "/DATA/Patientendokumente/email_migration_review")
OWNER_UID = 1001  # sturm
OWNER_GID = 1001  # praxis


def slugify(text):
    text = re.sub(r"[^A-Za-z0-9]+", "_", text).strip("_").lower()
    return text[:60]


def compute_desired(groups, patstamm, staged_by_patient, medoff_cur):
    """Liefert (desired_files, n_groups_by_reason):
    desired_files: {rel_dir (Grund/Pat_ID): {dateiname: quellpfad}}."""
    known_addr_cache = {}
    desired_files = {}
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
                known = known_addr_cache.get(pat_id)
                if known is None:
                    known = load_known_addresses(medoff_cur, staged_by_patient, pat_id)
                    known_addr_cache[pat_id] = known
                addr, err = resolve_address(rows, direction, pat_id, known)
                reason = err if addr is None else "faelschlich noch nicht migriert"

        n_groups_by_reason[reason] = n_groups_by_reason.get(reason, 0) + 1
        slug = slugify(reason)
        rel_dir = os.path.join(slug, str(pat_id) if pat_id is not None else "ohne_pat_id")
        files_here = desired_files.setdefault(rel_dir, {})
        for r in rows:
            src = os.path.join(DOK_ROOT, str(pat_id), r["datName"])
            if os.path.exists(src):
                files_here[r["datName"]] = src

    return desired_files, n_groups_by_reason


def sync_review_tree(desired_files):
    """Gleicht REVIEW_ROOT auf den in desired_files beschriebenen Soll-
    Zustand ab - legt nur an/entfernt nur, was sich tatsaechlich
    unterscheidet; unveraenderte Verzeichnisse/Dateien bleiben unberuehrt
    (siehe Modulkopf, SMB3-Lease-Problem)."""
    os.makedirs(REVIEW_ROOT, exist_ok=True)

    all_dirs_needed = set()
    for rel_dir in desired_files:
        parts = rel_dir.split(os.sep)
        for i in range(1, len(parts) + 1):
            all_dirs_needed.add(os.sep.join(parts[:i]))

    n_removed_dirs = 0
    n_removed_files = 0
    for root, dirs, files in os.walk(REVIEW_ROOT, topdown=False):
        rel = os.path.relpath(root, REVIEW_ROOT)
        if rel == ".":
            continue
        if rel not in all_dirs_needed:
            shutil.rmtree(root, ignore_errors=True)
            n_removed_dirs += 1
            continue
        wanted = desired_files.get(rel, {})
        for f in files:
            if f not in wanted:
                os.remove(os.path.join(root, f))
                n_removed_files += 1

    n_new_dirs = 0
    n_new_files = 0
    for rel_dir in sorted(all_dirs_needed, key=lambda p: p.count(os.sep)):
        full = os.path.join(REVIEW_ROOT, rel_dir)
        if not os.path.isdir(full):
            os.makedirs(full)
            os.chown(full, OWNER_UID, OWNER_GID)
            os.chmod(full, 0o770)
            n_new_dirs += 1

    for rel_dir, files_map in desired_files.items():
        full_dir = os.path.join(REVIEW_ROOT, rel_dir)
        for fn, src in files_map.items():
            dst = os.path.join(full_dir, fn)
            if not os.path.exists(dst):
                shutil.copy2(src, dst)
                os.chown(dst, OWNER_UID, OWNER_GID)
                os.chmod(dst, 0o660)
                n_new_files += 1

    return n_new_dirs, n_new_files, n_removed_dirs, n_removed_files


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

    desired_files, n_groups_by_reason = compute_desired(
        groups, patstamm, staged_by_patient, medoff_cur)
    n_new_dirs, n_new_files, n_removed_dirs, n_removed_files = sync_review_tree(desired_files)

    print(f"Ziel: {REVIEW_ROOT}")
    print(f"Neu angelegt: {n_new_dirs} Verzeichnisse, {n_new_files} Dateien")
    print(f"Entfernt (nicht mehr benoetigt): {n_removed_dirs} Verzeichnisse, {n_removed_files} Dateien")
    print("Gruppen je Grund (aktueller Stand):")
    for reason, n in sorted(n_groups_by_reason.items(), key=lambda kv: -kv[1]):
        print(f"  {slugify(reason)}: {n}")

    dokprot_conn.close()
    medoff.close()
    padb_conn.close()


if __name__ == "__main__":
    main()
