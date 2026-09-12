# -*- coding: utf-8 -*-
# Liest die vom Nutzer gepflegte Liste der Mitarbeiter-/Ex-Mitarbeiter-Email-
# Adressen (eine Adresse pro Zeile, '#'-Kommentare und Leerzeilen erlaubt).
# Wird von patient_emails_sync.py (Ausschluss aus dem Patienten-Adressbuch),
# find_missing_patient_emails.py (Ausschluss aus der Kandidatensuche) und
# mitarbeiter_contacts_sync.py (Datengrundlage) gemeinsam genutzt.
import os

MITARBEITER_EMAILS_PATH = r"C:\Mail\Thunderbird\Profiles\mitarbeiter_emails.txt"


def load_mitarbeiter_emails(path=MITARBEITER_EMAILS_PATH):
    emails = set()
    if not os.path.exists(path):
        return emails
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            emails.add(line.lower())
    return emails
