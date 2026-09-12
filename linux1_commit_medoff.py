# -*- coding: utf-8 -*-
# Duenner Linux-Wrapper um patient_addresses_db.commit_pending_main_addresses()
# - dieselbe Logik wie apply_patient_emails.py --commit-medoff auf Windows,
# nur mit linux1-eigenen Verbindungen statt secure_pwd.py/DPAPI und
# AendProt-CSV. Fuer den Betrieb auf linux1 vorgesehen, NICHT auf szn4.
# Deployment-Ziel: /opt/mo-emailadr/ (ausserhalb von /srv/www/htdocs -
# bewusst nicht web-exponiert, siehe [[project-missing-patient-emails]]).
#
# Vorgesehener Aufruf: direkt aus dem PHP-Patientenlaufzettel heraus nach
# jeder relevanten pat_email_adr-Aenderung (z.B. per shell_exec), statt nur
# auf den naechsten festen Windows-Task-Termin (14:30/21:00) zu warten -
# siehe [[project-missing-patient-emails]] fuer die Motivation (Kollision
# mit der "Rueckgaengig"-Funktion sollte dadurch strukturell kleiner werden,
# nicht nur seltener). Der Windows-Task bleibt zusaetzlich als Sicherheitsnetz
# bestehen (idempotent - schadet nicht, wenn beide denselben wartenden
# Eintrag verarbeiten wuerden, der eine kommt dann einfach zu spaet).
#
# Aufruf: python3 linux1_commit_medoff.py [--apply]
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import patient_addresses_db as padb
import linux1_medoff_connect as conn_helper


def main():
    apply_changes = "--apply" in sys.argv

    padb_conn = conn_helper.connect_quelle()
    medoff_conn = conn_helper.connect_medoff()
    mcur = medoff_conn.cursor()

    def log(aktion, pat_id, alt="", neu=""):
        # apply_changes durchreichen - commit_pending_main_addresses() ruft
        # log() unconditional auf (siehe dortigen Docstring/Windows-AendProt-
        # Verhalten), log_audit() selbst sorgt dafuer, dass ein Trockenlauf
        # trotzdem nichts in die gemeinsame Tabelle schreibt.
        padb.log_audit(padb_conn, aktion, pat_id, alt=alt, neu=neu,
                        bemerkung="linux1_commit_medoff.py", apply_changes=apply_changes)

    stats = padb.commit_pending_main_addresses(padb_conn, mcur, apply_changes, log)

    if apply_changes:
        medoff_conn.commit()
        padb_conn.commit()

    print("=== Ergebnis ===")
    print((("Eingetragen" if apply_changes else "Wuerde eingetragen (Trockenlauf)")) + f": {stats['n_written']}")
    print(f"Bereits aktuell (nur als committed markiert): {stats['n_already_current']}")
    print(f"Uebersprungen (FEmail zwischenzeitlich veraendert / Patient fehlt): {stats['n_skipped_changed']}"
          f" (davon nach pat_email_adr synchronisiert: {stats['n_synced']})")
    print(f"Uebersprungen (FStaatsangehoerigkeit bereits belegt): {stats['n_skipped_belegt']}")
    print(f"Uebersprungen (Zeichen ausserhalb Latin-1): {stats['n_skipped_encoding']}")
    print(f"Fehler (unerwartet, uebersprungen): {stats['n_error']}")
    if not apply_changes:
        print("Trockenlauf beendet. Zum tatsaechlichen Eintragen erneut mit --apply aufrufen.")

    medoff_conn.close()
    padb_conn.close()


if __name__ == "__main__":
    main()
