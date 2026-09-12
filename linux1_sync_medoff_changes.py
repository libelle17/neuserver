# -*- coding: utf-8 -*-
# Fuer den Betrieb auf linux1 vorgesehen (Cron), NICHT auf szn4/Windows -
# Deployment-Ziel: /opt/mo-emailadr/ (ausserhalb von /srv/www/htdocs,
# bewusst nicht web-exponiert). Ergaenzt das Commit-Skript
# (patient_addresses_db.commit_pending_main_addresses, schreibt
# pat_email_adr -> medoff) um die umgekehrte Richtung: erkennt
# Adressen, die DIREKT in medoff.patstamm.FEmail geaendert wurden (nicht
# ueber pat_email_adr/den PHP-Patientenlaufzettel), und uebernimmt sie nach
# quelle.pat_email_adr.
#
# Betrachtet ABSICHTLICH nur pat_email_adr-Zeilen mit rolle='h' UND
# committed=1 - eine noch nicht committete (committed=0) Zeile ist eine
# normale, wartende Korrektur und Sache des Commit-Skripts (siehe
# linux1_commit_medoff.py), nicht dieses Jobs. Wuerden beide denselben
# Zustand behandeln, kaeme sich das in die Quere (siehe
# patient_addresses_db.sync_from_medoff()-Docstring - dort auch der
# Unterschied zwischen den beiden Aufrufern erklaert).
#
# Aufruf: python3 linux1_sync_medoff_changes.py [--apply]
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import patient_addresses_db as padb
import linux1_medoff_connect as conn_helper


def main():
    apply_changes = "--apply" in sys.argv

    padb_conn = conn_helper.connect_quelle()
    cur = padb_conn.cursor()
    cur.execute(
        "SELECT pat_id, email FROM pat_email_adr WHERE rolle=%s AND committed=1",
        (padb.ROLLE_HAUPT,)
    )
    tracked = {str(row["pat_id"]): row["email"] for row in cur.fetchall()}
    print(f"Bereits committete Hauptadressen zur Kontrolle: {len(tracked)}")

    medoff_conn = conn_helper.connect_medoff()
    mcur = medoff_conn.cursor()

    aktuelle_werte = {}
    if tracked:
        placeholders = ",".join(["%s"] * len(tracked))
        mcur.execute(
            f"SELECT FSurogat, FEmail FROM patstamm WHERE FSurogat IN ({placeholders})",
            tuple(tracked.keys())
        )
        aktuelle_werte = {
            str(row["FSurogat"]): (row["FEmail"] or "").strip().lower()
            for row in mcur.fetchall()
        }

    n_unchanged = 0
    n_synced = 0
    n_cleared = 0
    n_patient_fehlt = 0

    for pat_id, bekannt_h in tracked.items():
        aktuell = aktuelle_werte.get(pat_id)
        if aktuell is None:
            n_patient_fehlt += 1
            continue
        if aktuell == bekannt_h:
            n_unchanged += 1
            continue
        if not aktuell:
            n_cleared += 1
            print(f"FEmail in medoff geleert - Historie angepasst: Patient {pat_id}")
            if apply_changes:
                padb.demote_to_alt(padb_conn, pat_id, bekannt_h)
                padb.log_audit(padb_conn, "FEmail in medoff geleert - Historie angepasst",
                                pat_id, alt=bekannt_h, bemerkung="linux1_sync_medoff_changes.py")
            continue
        n_synced += 1
        print(f"Direkte medoff-Aenderung erkannt, pat_email_adr synchronisiert: Patient {pat_id}")
        if apply_changes:
            padb.sync_from_medoff(padb_conn, pat_id, aktuell, bekannt_h, verdraengte_rolle=padb.ROLLE_ALT)
            padb.log_audit(padb_conn, "FEmail manuell in medoff geaendert - pat_email_adr synchronisiert",
                            pat_id, alt=bekannt_h, neu=aktuell, bemerkung="linux1_sync_medoff_changes.py")

    print("=== Ergebnis ===")
    print(f"Unveraendert: {n_unchanged}")
    print(f"Synchronisiert (direkte medoff-Aenderung uebernommen): {n_synced}")
    print(f"Geleert (medoff-FEmail entfernt, keine Ersatzadresse): {n_cleared}")
    print(f"Patient in medoff nicht gefunden: {n_patient_fehlt}")
    if not apply_changes:
        print("Trockenlauf beendet. Zum tatsaechlichen Schreiben erneut mit --apply aufrufen.")

    if apply_changes:
        padb_conn.commit()
    medoff_conn.close()
    padb_conn.close()


if __name__ == "__main__":
    main()
