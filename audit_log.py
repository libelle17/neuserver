# -*- coding: utf-8 -*-
# Gemeinsames, revisionssicheres Aenderungsprotokoll fuer alle Skripte dieses
# Projekts (find_missing_patient_emails.py Schreibschritt, patient_emails_sync.py,
# archive_patient_emails.py). Jede tatsaechliche oder im Trockenlauf simulierte
# Aenderung (FEmail/FStaatsangehoerigkeit, Adressbuch-Eintrag, Ablage in P:\dok) wird
# als eine Zeile angehaengt - nie ueberschrieben, eine Datei pro Lauf.
#
# Dateiname: AendProt_Phase_<Kuerzel>_<Zeitstempel>.csv - das Kuerzel zeigt
# auf einen Blick, welche(r) Pipeline-Phase(n) (siehe pipeline_ablauf.html)
# zu diesem Lauf gehoeren, z.B. "A-D" (Adressbuch-Sync + Staging +
# Archivierung, Teil 1 vor der Thunderbird-Aktualisierung), "E" (Thunderbird-
# Aktualisierung: institutionelle Mails + 2. Adressbuch-Durchlauf) oder "F"
# (medoff-Aktualisierung, eigener -CommitMedoff-Aufruf).
import csv
import os
from datetime import datetime

# Windows-Pfad als Default; ueberschreibbar fuer einen kuenftigen Linux-
# Einsatz (siehe [[project-missing-patient-emails]] - poll_diabetologie_inbox.py
# soll ggf. auch auf linux1 laufen koennen).
AUDIT_DIR = os.environ.get("AUDIT_DIR", r"C:\Mail\Thunderbird\Profiles\Protokolle")


def new_run_timestamp():
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def get_run_ts():
    """Liefert den Zeitstempel fuer das gemeinsame Aenderungsprotokoll dieses
    Laufs. Wenn PATMAIL_RUN_TS gesetzt ist (von einem uebergeordneten Aufruf,
    der mehrere Skripte zu EINEM Lauf buendelt), wird dieser wiederverwendet,
    damit alle beteiligten Skripte in dieselbe Protokolldatei schreiben -
    sonst wird ein neuer, eigener Zeitstempel erzeugt (Alleinlauf)."""
    return os.environ.get("PATMAIL_RUN_TS") or new_run_timestamp()


def get_run_phase(default):
    """Liefert das Phasen-Kuerzel fuer den Dateinamen-Praefix
    'AendProt_Phase_<Kuerzel>_'. Wenn PATMAIL_PHASE gesetzt ist (von
    run_pipeline.ps1, das mehrere Skripte zu einer Phasengruppe buendelt),
    wird dieser Wert verwendet - sonst der skriptspezifische Default
    (Alleinlauf ausserhalb der Pipeline)."""
    return os.environ.get("PATMAIL_PHASE") or default


class AuditLog:
    def __init__(self, run_ts, apply_changes, skriptname, phase):
        os.makedirs(AUDIT_DIR, exist_ok=True)
        self.path = os.path.join(AUDIT_DIR, f"AendProt_Phase_{phase}_{run_ts}.csv")
        self.apply_changes = apply_changes
        self.skriptname = skriptname
        is_new = not os.path.exists(self.path)
        self._f = open(self.path, "a", encoding="utf-8-sig", newline="")
        self._writer = csv.writer(self._f, delimiter=";", quoting=csv.QUOTE_MINIMAL)
        if is_new:
            self._writer.writerow([
                "Zeitstempel", "Lauf-Modus", "Skript", "Aktion", "Patientennummer",
                "Alter Wert", "Neuer Wert", "Pfad",
            ])

    def log(self, aktion, patientennummer="", alt="", neu="", pfad=""):
        modus = "durchgefuehrt" if self.apply_changes else "Trockenlauf (wuerde)"
        self._writer.writerow([
            datetime.now().strftime("%Y-%m-%d %H:%M:%S"), modus, self.skriptname,
            aktion, patientennummer, alt, neu, pfad,
        ])
        self._f.flush()

    def close(self):
        self._f.close()
