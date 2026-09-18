# -*- coding: utf-8 -*-
# Ergaenzt das Commit-Skript (patient_addresses_db.commit_pending_main_addresses,
# schreibt pat_email_adr -> medoff) um die umgekehrte Richtung: erkennt Adressen, die
# DIREKT in medoff.patstamm.FEmail geaendert wurden (nicht ueber pat_email_adr/den
# PHP-Patientenlaufzettel), und uebernimmt sie nach quelle.pat_email_adr.
#
# Fuer den Betrieb auf linux1 vorgesehen (Cron), NICHT auf szn4/Windows - Deployment-Ziel:
# /opt/mo-emailadr/ (ausserhalb von /srv/www/htdocs, bewusst nicht web-exponiert).
#
# Betrachtet ABSICHTLICH nur pat_email_adr-Zeilen mit rolle='h' UND
# committed=1 - eine noch nicht committete (committed=0) Zeile ist eine
# normale, wartende Korrektur und Sache des Commit-Skripts (siehe
# linux1_commit_medoff.py), nicht dieses Jobs. Wuerden beide denselben
# Zustand behandeln, kaeme sich das in die Quere (siehe
# patient_addresses_db.sync_from_medoff()-Docstring - dort auch der
# Unterschied zwischen den beiden Aufrufern erklaert).
#
# Zwei Modi (2026-09-12, fuer haeufiges Polling ohne relevante DB-Last):
#   Normal (ohne --full): inkrementell ueber medoff.dbsprot - Medical
#     Office protokolliert dort jede patstamm-Aenderung als schlankes
#     XML-Fragment nur mit dem GEAENDERTEN Feld (verifiziert: die
#     jeweils letzte patstamm-Zeile enthaelt nur <Email>...</Email>,
#     nicht die ganze Zeile). FSurogat (Primaerschluessel von dbsprot,
#     nachweislich monoton mit der Zeit) dient als billiger Cursor - nur
#     Zeilen mit FSurogat > letztem Bookmark UND FTablename='patstamm'
#     UND FXmlinhalt LIKE '%<Email>%' werden angesehen, das sind bei
#     normalem Praxisbetrieb ca. 10-20 dbsprot-Zeilen pro Minute
#     INSGESAMT (alle Tabellen), also unkritisch fuer 1-2-Minuten-Takt.
#     FPatnr in dbsprot entspricht direkt patstamm.FSurogat/pat_id
#     (verifiziert). Bookmark liegt in DBSPROT_BOOKMARK_FILE; bei
#     fehlender Datei wird NICHT rueckwirkend der komplette dbsprot-
#     Bestand durchsucht, sondern beim aktuellen Maximalwert begonnen.
#   --full: die urspruengliche, erschoepfende Pruefung (alle committeten
#     rolle='h'-Zeilen gegen medoff) als taeglicher Backstop, falls
#     dbsprot aus irgendeinem Grund (z.B. eine Aenderung ausserhalb des
#     normalen MO-Wegs) etwas nicht protokolliert haben sollte -
#     dasselbe Backstop-Prinzip wie der Windows-Task neben dem direkten
#     PHP-Aufruf bei linux1_commit_medoff.py.
#
# Aufruf: python3 linux1_sync_medoff_changes.py [--apply] [--full]
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import patient_addresses_db as padb
import linux1_medoff_connect as conn_helper

DBSPROT_BOOKMARK_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".dbsprot_bookmark")


def load_bookmark():
    try:
        with open(DBSPROT_BOOKMARK_FILE) as f:
            return int(f.read().strip())
    except (FileNotFoundError, ValueError):
        return None


def save_bookmark(value):
    with open(DBSPROT_BOOKMARK_FILE, "w") as f:
        f.write(str(value))


def kandidaten_seit_bookmark(mcur):
    """pat_ids (als str), deren patstamm.FEmail sich seit dem letzten Lauf
    laut dbsprot geaendert haben koennte, plus der neue Bookmark-Wert (vom
    Aufrufer bei apply_changes zu speichern)."""
    bookmark = load_bookmark()
    mcur.execute("SELECT MAX(FSurogat) AS m FROM dbsprot")
    aktueller_max = mcur.fetchone()["m"] or 0

    if bookmark is None:
        # Erster Lauf: nicht rueckwirkend den kompletten Bestand durchsuchen,
        # sondern erst ab jetzt beobachten (die --full-Vergleiche decken den
        # Bestand bis hierher ab).
        print(f"Kein Bookmark gefunden - initialisiere auf aktuellen Stand ({aktueller_max}), "
              f"kein Rueckwirkungs-Scan.")
        return set(), aktueller_max

    mcur.execute(
        "SELECT DISTINCT FPatnr FROM dbsprot WHERE FTablename='patstamm' AND FSurogat > %s "
        "AND FXmlinhalt LIKE '%%<Email>%%'",
        (bookmark,)
    )
    pat_ids = {str(row["FPatnr"]) for row in mcur.fetchall() if row["FPatnr"] is not None}
    print(f"dbsprot: {aktueller_max - bookmark} neue Zeile(n) seit Bookmark {bookmark}, "
          f"davon mit patstamm-Email-Aenderung: {len(pat_ids)}")
    return pat_ids, aktueller_max


def pruefe_und_synchronisiere(padb_conn, mcur, tracked, apply_changes):
    """Gemeinsamer Vergleichs-/Schreibteil fuer --full und den
    dbsprot-Modus - identisch zur urspruenglichen Logik, nur die Auswahl
    von "tracked" (welche pat_ids ueberhaupt angesehen werden) ist neu."""
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

    return {
        "n_unchanged": n_unchanged,
        "n_synced": n_synced,
        "n_cleared": n_cleared,
        "n_patient_fehlt": n_patient_fehlt,
    }


def entdecke_fehlende_hauptadressen(padb_conn, mcur, apply_changes):
    """Einmaliger/gelegentlicher Abgleich (Nutzer-Auftrag 2026-09-18, Befund
    bei Pat. 79070: FEmail in medoff gesetzt, aber NIE eine
    pat_email_adr-Zeile bekommen): findet medoff.patstamm-Patienten mit
    gesetzter FEmail, fuer die noch KEINE pat_email_adr-Zeile mit rolle='h'
    existiert - weder der dbsprot-Cursor (reagiert nur auf NEUE
    Aenderungen seit dem Bookmark) noch der --full-Abgleich oben (prueft
    nur bereits vorhandene rolle='h'-Zeilen) koennen so einen Patienten
    jemals finden, wenn seine FEmail schon vor dem Start des Bookmarks
    gesetzt wurde (oder auf einem Weg ohne dbsprot-Eintrag). Laeuft als
    Teil von --full (Windows-Instanz-Empfehlung 2026-09-18: kein eigener
    Cron-Takt noetig, "gelegentlich" reicht).

    Nutzt sync_from_medoff() mit einer leeren verdraengten Adresse (es gibt
    ja keine bisherige rolle='h'-Zeile zu verdraengen) - schreibt die neue
    Zeile mit rolle='h', quelle='s', committed=1 (Absprache mit der
    Windows-Instanz: quelle='s' fuer Konsistenz mit dem reaktiven Sync,
    NICHT 'c' wie bei der Vorschlagsliste, da nicht darueber gefunden)."""
    cur = padb_conn.cursor()
    cur.execute("SELECT DISTINCT pat_id FROM pat_email_adr WHERE rolle=%s", (padb.ROLLE_HAUPT,))
    bereits_bekannt = {str(row["pat_id"]) for row in cur.fetchall()}

    mcur.execute("SELECT FSurogat, FEmail FROM patstamm WHERE FEmail IS NOT NULL AND FEmail <> ''")
    fehlend = [(str(row["FSurogat"]), (row["FEmail"] or "").strip().lower())
               for row in mcur.fetchall()
               if (row["FEmail"] or "").strip() and str(row["FSurogat"]) not in bereits_bekannt]

    print(f"medoff-Patienten mit FEmail ohne jede pat_email_adr-Zeile: {len(fehlend)}")
    for pat_id, email in fehlend:
        print(f"Fehlende Hauptadresse nachgetragen: Patient {pat_id}")
        if apply_changes:
            padb.sync_from_medoff(padb_conn, pat_id, email, "", verdraengte_rolle=padb.ROLLE_ALT)
            padb.log_audit(padb_conn, "FEmail aus medoff nachtraeglich uebernommen (Entdeckungs-Abgleich)",
                            pat_id, neu=email, bemerkung="linux1_sync_medoff_changes.py --full (Entdeckung)")
    return len(fehlend)


def main():
    apply_changes = "--apply" in sys.argv
    voller_lauf = "--full" in sys.argv

    padb_conn = conn_helper.connect_quelle()
    cur = padb_conn.cursor()
    cur.execute(
        "SELECT pat_id, email FROM pat_email_adr WHERE rolle=%s AND committed=1",
        (padb.ROLLE_HAUPT,)
    )
    alle_committeten = {str(row["pat_id"]): row["email"] for row in cur.fetchall()}
    print(f"Bereits committete Hauptadressen insgesamt: {len(alle_committeten)}")

    medoff_conn = conn_helper.connect_medoff()
    mcur = medoff_conn.cursor()

    neuer_bookmark = None
    if voller_lauf:
        print("Voller Lauf (--full): pruefe ALLE committeten Hauptadressen gegen medoff.")
        tracked = alle_committeten
    else:
        kandidaten, neuer_bookmark = kandidaten_seit_bookmark(mcur)
        tracked = {pid: alle_committeten[pid] for pid in kandidaten if pid in alle_committeten}

    stats = pruefe_und_synchronisiere(padb_conn, mcur, tracked, apply_changes)

    n_entdeckt = 0
    if voller_lauf:
        n_entdeckt = entdecke_fehlende_hauptadressen(padb_conn, mcur, apply_changes)

    print("=== Ergebnis ===")
    print(f"Geprueft: {len(tracked)}")
    print(f"Unveraendert: {stats['n_unchanged']}")
    print(f"Synchronisiert (direkte medoff-Aenderung uebernommen): {stats['n_synced']}")
    print(f"Geleert (medoff-FEmail entfernt, keine Ersatzadresse): {stats['n_cleared']}")
    print(f"Patient in medoff nicht gefunden: {stats['n_patient_fehlt']}")
    if voller_lauf:
        print(f"Neu entdeckt (FEmail ohne jede pat_email_adr-Zeile): {n_entdeckt}")
    if not apply_changes:
        print("Trockenlauf beendet. Zum tatsaechlichen Schreiben erneut mit --apply aufrufen.")

    if apply_changes:
        padb_conn.commit()
        if neuer_bookmark is not None:
            save_bookmark(neuer_bookmark)
    medoff_conn.close()
    padb_conn.close()


if __name__ == "__main__":
    main()
